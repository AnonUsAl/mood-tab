import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/mood_record.dart';

/// 本地 SQLite 数据库服务
/// 所有情绪数据 100% 存储在设备本地，绝不上传云端
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  /// 获取数据库实例（懒初始化）
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
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE mood_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mood_type INTEGER NOT NULL,
        intensity INTEGER NOT NULL,
        note TEXT,
        tags TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // 按时间查询的索引，加速历史列表和统计查询
    await db.execute(
      'CREATE INDEX idx_mood_created_at ON mood_records(created_at)',
    );
  }

  // ==================== CRUD 操作 ====================

  /// 插入一条情绪记录
  Future<int> insertRecord(MoodRecord record) async {
    final db = await database;
    return await db.insert('mood_records', record.toMap());
  }

  /// 查询所有记录，按时间倒序
  Future<List<MoodRecord>> getAllRecords() async {
    final db = await database;
    final maps = await db.query(
      'mood_records',
      orderBy: 'created_at DESC',
    );
    return maps.map(MoodRecord.fromMap).toList();
  }

  /// 查询指定日期范围内的记录
  Future<List<MoodRecord>> getRecordsBetween(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final maps = await db.query(
      'mood_records',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'created_at DESC',
    );
    return maps.map(MoodRecord.fromMap).toList();
  }

  /// 查询今日记录
  Future<List<MoodRecord>> getTodayRecords() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getRecordsBetween(startOfDay, endOfDay);
  }

  /// 删除一条记录
  Future<int> deleteRecord(int id) async {
    final db = await database;
    return await db.delete(
      'mood_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取记录总数
  Future<int> getRecordCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM mood_records');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 关闭数据库连接
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
