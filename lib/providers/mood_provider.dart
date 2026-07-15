import 'package:flutter/foundation.dart';
import '../models/mood_record.dart';
import '../models/mood_type.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';

/// 应用全局状态管理
/// 负责情绪记录的增删查改，以及数据状态的维护
class MoodProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final PreferencesService _prefs = PreferencesService();

  List<MoodRecord> _allRecords = [];
  List<MoodRecord> _todayRecords = [];
  List<MoodRecord> _diaryRecords = [];
  bool _isLoading = false;

  /// 主题模式：'light' 或 'dark'
  String _themeMode = 'light';

  List<MoodRecord> get allRecords => _allRecords;
  List<MoodRecord> get todayRecords => _todayRecords;
  List<MoodRecord> get diaryRecords => _diaryRecords;
  bool get isLoading => _isLoading;
  String get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == 'dark';

  /// 今日记录条数
  int get todayCount => _todayRecords.length;

  /// 总记录条数
  int get totalCount => _allRecords.length;

  /// 日记条数
  int get diaryCount => _diaryRecords.length;

  /// 加载所有数据
  Future<void> loadAllData() async {
    _setLoading(true);
    await _prefs.init();
    _themeMode = _prefs.themeMode;
    _allRecords = await _dbService.getAllRecords();
    _todayRecords = await _dbService.getTodayRecords();
    _diaryRecords = await _dbService.getDiaryRecords();
    _setLoading(false);
  }

  /// 切换主题模式
  Future<void> setThemeMode(String mode) async {
    _themeMode = mode;
    await _prefs.setThemeMode(mode);
    notifyListeners();
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
    String? diary,
    required List<String> tags,
  }) async {
    final record = MoodRecord(
      moodType: moodType,
      intensity: intensity,
      note: note,
      diary: diary,
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

  /// 获取某一天的记录
  Future<List<MoodRecord>> getRecordsForDay(DateTime date) async {
    return _dbService.getRecordsForDay(date);
  }

  /// 获取最近 N 天的记录
  Future<List<MoodRecord>> getRecentRecords(int days) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));
    final end = start.add(Duration(days: days));
    return _dbService.getRecordsBetween(start, end);
  }

  /// 获取有记录的日期集合
  Future<Set<String>> getRecordedDates() async {
    return _dbService.getRecordedDates();
  }

  /// 导出全部数据
  Future<List<Map<String, dynamic>>> exportAll() async {
    return _dbService.exportAll();
  }

  /// 从备份恢复
  Future<void> importAll(List<Map<String, dynamic>> data) async {
    await _dbService.importAll(data);
    await loadAllData();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
