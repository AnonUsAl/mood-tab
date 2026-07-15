import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/mood_record.dart';

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
      version: 4,
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
      dates.add('${dt.year}-${dt.month}-${dt.day}');
    }
    return dates;
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
    final dateStr = '${date.year}-${date.month}-${date.day}';
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
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month}-${now.day}';
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
      final dateStr = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
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

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
