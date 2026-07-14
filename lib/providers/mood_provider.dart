import 'package:flutter/foundation.dart';
import '../models/mood_record.dart';
import '../models/mood_type.dart';
import '../services/database_service.dart';

/// 应用全局状态管理
/// 负责情绪记录的增删查改，以及数据状态的维护
class MoodProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<MoodRecord> _allRecords = [];
  List<MoodRecord> _todayRecords = [];
  bool _isLoading = false;

  List<MoodRecord> get allRecords => _allRecords;
  List<MoodRecord> get todayRecords => _todayRecords;
  bool get isLoading => _isLoading;

  /// 今日记录条数
  int get todayCount => _todayRecords.length;

  /// 总记录条数
  int get totalCount => _allRecords.length;

  /// 加载所有数据
  Future<void> loadAllData() async {
    _setLoading(true);
    _allRecords = await _dbService.getAllRecords();
    _todayRecords = await _dbService.getTodayRecords();
    _setLoading(false);
  }

  /// 只刷新今日数据
  Future<void> refreshToday() async {
    _todayRecords = await _dbService.getTodayRecords();
    notifyListeners();
  }

  /// 添加一条情绪记录
  Future<void> addRecord({
    required MoodType moodType,
    required int intensity,
    String? note,
    required List<String> tags,
  }) async {
    final record = MoodRecord(
      moodType: moodType,
      intensity: intensity,
      note: note,
      tags: tags,
      createdAt: DateTime.now(),
    );
    await _dbService.insertRecord(record);
    await loadAllData();
  }

  /// 删除一条记录
  Future<void> deleteRecord(int id) async {
    await _dbService.deleteRecord(id);
    await loadAllData();
  }

  /// 获取指定日期范围内的记录
  Future<List<MoodRecord>> getRecordsBetween(
    DateTime start,
    DateTime end,
  ) async {
    return _dbService.getRecordsBetween(start, end);
  }

  /// 获取最近 N 天的记录
  Future<List<MoodRecord>> getRecentRecords(int days) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));
    final end = start.add(Duration(days: days));
    return _dbService.getRecordsBetween(start, end);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
