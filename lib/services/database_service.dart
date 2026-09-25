import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/mood_record.dart';
import '../models/urge_log.dart';
// 条件导入：原生平台用 FFI 实现（Windows / Linux 必需），Web 用空实现。
import 'database_factory_stub.dart'
    if (dart.library.io) 'database_factory_io.dart';

/// 本地数据库不可用（打开失败、原生库缺失、目录不可写……）。
///
/// 单独一个类型是为了让界面层能一眼认出「这是数据层的问题」，
/// 而不是把一句底层 ffi 异常直接甩给用户。
class DatabaseUnavailableException implements Exception {
  /// 已经整理过、可以直接显示给用户看的多行说明。
  final String message;

  /// 尝试打开过的库文件路径。
  final String? path;

  const DatabaseUnavailableException(this.message, {this.path});

  @override
  String toString() => message;
}

/// 本地 SQLite 数据库服务
/// 所有数据 100% 存储在设备本地，绝不上传云端
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  /// 当前使用的库文件完整路径（打开成功后才有值）。
  String? _databasePath;
  String? get databasePath => _databasePath;

  /// 最近一次打开数据库失败的原因；成功时为 null。
  String? _lastOpenError;
  String? get lastOpenError => _lastOpenError;

  /// 正在进行中的首次初始化。
  ///
  /// 多个页面（日历页、统计页、情绪花园等）会在同一帧的 post-frame 回调里
  /// 各自发起一次查询，如果这里不做单飞，两边会同时看到 `_database == null`
  /// 并各自 `openDatabase` 同一个文件（还会并发跑 onCreate / onUpgrade），
  /// 桌面端 FFI 实现下这两个打开操作会互相等待，查询永远不返回 ——
  /// 表现就是「页面一直转圈」。这里让并发调用共享同一个 Future。
  Future<Database>? _opening;

  Future<Database> get database {
    final existing = _database;
    if (existing != null) return Future.value(existing);
    return _opening ??= _open();
  }

  Future<Database> _open() async {
    try {
      final db = await _initDatabase();
      _database = db;
      return db;
    } catch (_) {
      // 初始化失败时清空，让下一次调用可以重试，而不是永久返回失败的 Future。
      _opening = null;
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
    // Windows / Linux 上 sqflite 没有原生实现，必须先切到 FFI 工厂；
    // 其他平台这里是空操作。
    // ⚠️ 这里不吞异常：桌面端原生 sqlite3 库缺失时必须在这一步炸出来，
    // 否则会退化成「页面全空 + 记录存不进去」这种看不出原因的状态。
    initDesktopDatabaseFactory();

    // 只收路径字符串，不引 dart:io 的类型，Web 构建也能过。
    final candidateDirs = <String>[];
    try {
      candidateDirs.add((await getApplicationDocumentsDirectory()).path);
    } catch (e) {
      debugPrint('取用户文档目录失败: $e');
    }
    try {
      candidateDirs.add((await getApplicationSupportDirectory()).path);
    } catch (e) {
      debugPrint('取应用支持目录失败: $e');
    }

    if (candidateDirs.isEmpty) {
      _lastOpenError = '拿不到任何可写入的数据目录，本地数据库无法使用。';
      throw DatabaseUnavailableException(_lastOpenError!);
    }

    // 兜底目录只在首选目录还从没建过库文件时才用。
    // 已经有库文件却打不开时绝不换目录 —— 换目录等于换一个空库，
    // 用户会以为以前的记录全丢了。
    final dbPaths = candidateDirs.map((d) => p.join(d, 'mood_tab.db')).toList();
    final usable = await _databaseFileExists(dbPaths.first)
        ? dbPaths.take(1).toList()
        : dbPaths;

    Object? lastError;
    final tried = <String>[];
    for (final dbPath in usable) {
      tried.add(dbPath);
      try {
        final db = await openDatabase(
          dbPath,
          version: 7,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        );
        _databasePath = dbPath;
        _lastOpenError = null;
        return db;
      } catch (e, st) {
        lastError = e;
        debugPrint('打开数据库失败（$dbPath）: $e\n$st');
      }
    }

    _lastOpenError = _describeOpenFailure(lastError, tried);
    throw DatabaseUnavailableException(_lastOpenError!, path: tried.first);
  }

  /// 库文件是否已经存在。探测本身出错就当「不存在」，不影响主流程。
  Future<bool> _databaseFileExists(String dbPath) async {
    try {
      return await databaseFactory.databaseExists(dbPath);
    } catch (e) {
      debugPrint('检查数据库文件是否存在失败: $e');
      return false;
    }
  }

  /// 把打开失败整理成能给用户看的说明。
  String _describeOpenFailure(Object? error, List<String> triedPaths) {
    final buffer = StringBuffer('本地数据库打开失败，记录暂时读不到，也存不进去。');
    buffer.write('\n\n尝试过的文件：');
    for (final path in triedPaths) {
      buffer.write('\n· $path');
    }

    final factoryError = desktopDatabaseFactoryError;
    if (factoryError != null) {
      buffer.write('\n\n$factoryError');
    } else {
      buffer.write(
        '\n\n数据库工厂初始化正常，问题出在打开文件这一步。'
        '常见原因：文件被占用（上次没退出干净）、没有写权限、磁盘已满。',
      );
    }

    buffer.write('\n\n原始错误：$error');
    return buffer.toString();
  }

  /// 给用户看的诊断摘要（保存失败时随错误提示一起显示，便于定位）。
  String diagnostics() {
    return [
      '数据库已就绪：${_database != null ? '是' : '否'}',
      '库文件路径：${_databasePath ?? '（尚未打开）'}',
      '打开失败原因：${_lastOpenError ?? '无'}',
    ].join('\n');
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
      'CREATE INDEX idx_mood_created_at ON mood_records(created_at)',
    );
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
      'CREATE INDEX IF NOT EXISTS idx_urge_created_at ON urge_logs(created_at)',
    );
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
        await db.update(
          'checkins',
          {'date': normalized},
          where: 'id = ?',
          whereArgs: [id],
        );
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
    DateTime start,
    DateTime end,
  ) async {
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
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM mood_records',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Set<String>> getRecordedDates() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT created_at FROM mood_records',
    );
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
      final checkDate = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
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
    return await db.update(
      'urge_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<void> close() async {
    final db = _database;
    // 清掉单飞缓存，否则关库后再次访问会拿到已关闭的实例。
    _database = null;
    _opening = null;
    if (db != null) {
      await db.close();
    }
  }
}
