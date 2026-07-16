import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/mood_record.dart';
import '../models/urge_log.dart';

/// 本地 SQLite 数据库服务
/// 所有数据 100% 存储在设备本地，绝不上传云端
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(documentsDir.path, 'mood_tab.db');
    return await openDatabase(
      dbPath,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE mood_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mood_type INTEGER NOT NULL,
        intensity INTEGER NOT NULL,
        note TEXT,
        tags TEXT,
        diary TEXT,
        diary_images TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_mood_created_at ON mood_records(created_at)');
    await db.execute('''
      CREATE TABLE checkins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_checkins_date ON checkins(date)');
    await _createUrgeLogsTable(db);
  }

  /// 创建自伤冲动监测日志表（自我觉察工具，非行为指导）
  Future<void> _createUrgeLogsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS urge_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        intensity INTEGER NOT NULL,
        acted_on INTEGER NOT NULL DEFAULT 0,
        trigger TEXT,
        coping_used TEXT,
        note TEXT,
        image_path TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_urge_created_at ON urge_logs(created_at)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE mood_records ADD COLUMN diary TEXT');
    }
    // v3 的 assessment_results 表已移除，测评改为 WebView 外链
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE checkins (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL UNIQUE,
          created_at INTEGER NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX idx_checkins_date ON checkins(date)');
    }
    if (oldVersion < 5) {
      // 新增自伤冲动监测日志表
      await _createUrgeLogsTable(db);
      // 将历史打卡日期规范为补零格式（yyyy-MM-dd），避免连续天数比较错位
      await _normalizeCheckinDates(db);
    }
    if (oldVersion < 6) {
      // 情绪安全记录支持事件名称与关联图片
      await db.execute('ALTER TABLE urge_logs ADD COLUMN title TEXT');
      await db.execute('ALTER TABLE urge_logs ADD COLUMN image_path TEXT');
    }
    if (oldVersion < 7) {
      // 日记支持关联多张图片
      await db.execute('ALTER TABLE mood_records ADD COLUMN diary_images TEXT');
    }
  }

  /// 把 checkins 表里旧的非补零日期（如 2026-7-6）迁移为补零格式（2026-07-06）。
  /// 若规范化后与已有行冲突（同一天两种写法），保留其一并删除重复。
  Future<void> _normalizeCheckinDates(Database db) async {
    final rows = await db.query('checkins', columns: ['id', 'date']);
    for (final row in rows) {
      final id = row['id'] as int;
      final raw = row['date'] as String;
      final parts = raw.split('-');
      if (parts.length != 3) continue;
      final y = parts[0];
      final m = parts[1].padLeft(2, '0');
      final d = parts[2].padLeft(2, '0');
      final normalized = '$y-$m-$d';
      if (normalized == raw) continue;
      try {
        await db.update('checkins', {'date': normalized},
            where: 'id = ?', whereArgs: [id]);
      } catch (_) {
        // UNIQUE 冲突：已存在补零写法的同一天，删除这条重复行
        await db.delete('checkins', where: 'id = ?', whereArgs: [id]);
      }
    }
  }

  // ==================== 情绪记录 CRUD ====================

  Future<int> insertRecord(MoodRecord record) async {
    final db = await database;
    return await db.insert('mood_records', record.toMap());
  }

  Future<int> updateRecord(MoodRecord record) async {
    final db = await database;
    if (record.id == null) return 0;
    return await db.update(
      'mood_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<List<MoodRecord>> getAllRecords() async {
    final db = await database;
    final maps = await db.query('mood_records', orderBy: 'created_at DESC');
    return maps.map(MoodRecord.fromMap).toList();
  }

  Future<List<MoodRecord>> getRecordsBetween(
      DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      'mood_records',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'created_at DESC',
    );
    return maps.map(MoodRecord.fromMap).toList();
  }

  Future<List<MoodRecord>> getTodayRecords() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getRecordsBetween(startOfDay, endOfDay);
  }

  Future<List<MoodRecord>> getRecordsForDay(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return getRecordsBetween(start, end);
  }

  Future<List<MoodRecord>> getDiaryRecords() async {
    final db = await database;
    final maps = await db.query(
      'mood_records',
      where: 'diary IS NOT NULL AND diary != ?',
      whereArgs: [''],
      orderBy: 'created_at DESC',
    );
    return maps.map(MoodRecord.fromMap).toList();
  }

  Future<int> deleteRecord(int id) async {
    final db = await database;
    return await db.delete('mood_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getRecordCount() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM mood_records');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Set<String>> getRecordedDates() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT DISTINCT created_at FROM mood_records');
    final dates = <String>{};
    for (final row in result) {
      final ts = row['created_at'] as int;
      final dt = DateTime.fromMillisecondsSinceEpoch(ts);
      dates.add(_formatDateKey(dt));
    }
    return dates;
  }

  /// 统一的日期键格式：yyyy-MM-dd（补零，保证与日历/打卡比较一致）
  static String _formatDateKey(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d';
  }

  Future<List<Map<String, dynamic>>> exportAll() async {
    final db = await database;
    return await db.query('mood_records', orderBy: 'created_at ASC');
  }

  Future<void> importAll(List<Map<String, dynamic>> data) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('mood_records');
      for (final map in data) {
        await txn.insert('mood_records', map);
      }
    });
  }

  // ==================== 打卡功能 ====================

  Future<int> insertCheckin(DateTime date) async {
    final db = await database;
    final dateStr = _formatDateKey(date);
    try {
      return await db.insert('checkins', {
        'date': dateStr,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {
      return 0;
    }
  }

  Future<bool> hasCheckedInToday() async {
    final dateStr = _formatDateKey(DateTime.now());
    final db = await database;
    final result = await db.query(
      'checkins',
      where: 'date = ?',
      whereArgs: [dateStr],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<int> getCheckinStreak() async {
    final db = await database;
    final result = await db.query('checkins', orderBy: 'date DESC');
    if (result.isEmpty) return 0;

    final dates = result.map((r) => r['date'] as String).toList();
    int streak = 0;
    final now = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final checkDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dateStr = _formatDateKey(checkDate);
      if (dates.contains(dateStr)) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }

    return streak;
  }

  Future<int> getTotalCheckins() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM checkins');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Set<String>> getCheckinDates() async {
    final db = await database;
    final result = await db.query('checkins', columns: ['date']);
    return result.map((r) => r['date'] as String).toSet();
  }

  // ==================== 自伤冲动监测日志 ====================

  Future<int> insertUrgeLog(UrgeLog log) async {
    final db = await database;
    return await db.insert('urge_logs', log.toMap());
  }

  Future<List<UrgeLog>> getUrgeLogs() async {
    final db = await database;
    final maps = await db.query('urge_logs', orderBy: 'created_at DESC');
    return maps.map(UrgeLog.fromMap).toList();
  }

  Future<List<UrgeLog>> getUrgeLogsBetween(DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      'urge_logs',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'created_at DESC',
    );
    return maps.map(UrgeLog.fromMap).toList();
  }

  Future<int> deleteUrgeLog(int id) async {
    final db = await database;
    return await db.delete('urge_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateUrgeLog(UrgeLog log) async {
    final db = await database;
    return await db
        .update('urge_logs', log.toMap(), where: 'id = ?', whereArgs: [log.id]);
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
