import 'package:flutter/foundation.dart';
import '../models/medication.dart';
import '../models/mood_record.dart';
import '../models/mood_tag.dart';
import '../models/mood_type.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';

/// 应用全局状态管理
/// 负责情绪记录的增删查改，以及数据状态的维护
class MoodProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final PreferencesService _prefs = PreferencesService();
  final NotificationService _notifications = NotificationService();

  List<MoodRecord> _allRecords = [];
  List<MoodRecord> _todayRecords = [];
  List<MoodRecord> _diaryRecords = [];
  bool _isLoading = false;

  /// 主题模式：'light' 或 'dark'
  String _themeMode = 'light';

  /// 用户昵称
  String _userName = '';

  /// 药物列表
  List<Medication> _medications = [];

  /// 打卡状态
  bool _hasCheckedInToday = false;
  int _checkinStreak = 0;
  int _totalCheckins = 0;

  List<MoodRecord> get allRecords => _allRecords;
  List<MoodRecord> get todayRecords => _todayRecords;
  List<MoodRecord> get diaryRecords => _diaryRecords;
  bool get isLoading => _isLoading;
  String get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == 'dark';
  String get userName => _userName;
  List<Medication> get medications => _medications;
  bool get hasCheckedInToday => _hasCheckedInToday;
  int get checkinStreak => _checkinStreak;
  int get totalCheckins => _totalCheckins;

  /// 今日记录条数
  int get todayCount => _todayRecords.length;

  /// 总记录条数
  int get totalCount => _allRecords.length;

  /// 日记条数
  int get diaryCount => _diaryRecords.length;

  /// 自定义标签列表
  List<MoodTag> get customTags => MoodTags.customTags;

  /// 所有标签（预设 + 自定义）
  List<MoodTag> get allTags => MoodTags.allTags;

  /// 加载所有数据
  Future<void> loadAllData() async {
    _setLoading(true);
    await _prefs.init();
    _themeMode = _prefs.themeMode;
    _userName = _prefs.userName;
    _medications = _prefs.getMedications();
    final customTags = _prefs.getCustomTags();
    MoodTags.setCustomTags(customTags);
    _allRecords = await _dbService.getAllRecords();
    _todayRecords = await _dbService.getTodayRecords();
    _diaryRecords = await _dbService.getDiaryRecords();
    _hasCheckedInToday = await _dbService.hasCheckedInToday();
    _checkinStreak = await _dbService.getCheckinStreak();
    _totalCheckins = await _dbService.getTotalCheckins();
    if (_prefs.dailyReminderEnabled) {
      await _notifications.scheduleDailyReminder(_prefs.dailyReminderTimes);
    }
    _setLoading(false);
  }

  /// 今日打卡
  Future<void> checkinToday() async {
    if (_hasCheckedInToday) return;
    await _dbService.insertCheckin(DateTime.now());
    _hasCheckedInToday = true;
    _checkinStreak = await _dbService.getCheckinStreak();
    _totalCheckins = await _dbService.getTotalCheckins();
    notifyListeners();
  }

  /// 切换主题模式
  Future<void> setThemeMode(String mode) async {
    _themeMode = mode;
    await _prefs.setThemeMode(mode);
    notifyListeners();
  }

  /// 设置用户昵称
  Future<void> setUserName(String name) async {
    _userName = name;
    await _prefs.setUserName(name);
    notifyListeners();
  }

  // ==================== 自定义标签管理 ====================

  /// 添加自定义标签
  ///
  /// [label] 标签名称，[emoji] 标签 emoji
  /// 返回 true 表示添加成功，false 表示标签已存在
  Future<bool> addCustomTag(String label, String emoji) async {
    if (MoodTags.exists(label)) return false;
    final tag = MoodTag(label: label, emoji: emoji, isCustom: true);
    final updated = [...MoodTags.customTags, tag];
    await _prefs.setCustomTags(updated);
    MoodTags.setCustomTags(updated);
    notifyListeners();
    return true;
  }

  /// 删除自定义标签（按 label）
  Future<void> deleteCustomTag(String label) async {
    final updated =
        MoodTags.customTags.where((t) => t.label != label).toList();
    await _prefs.setCustomTags(updated);
    MoodTags.setCustomTags(updated);
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
    DateTime? createdAt,
  }) async {
    final record = MoodRecord(
      moodType: moodType,
      intensity: intensity,
      note: note,
      diary: diary,
      tags: tags,
      createdAt: createdAt ?? DateTime.now(),
    );
    await _dbService.insertRecord(record);
    await loadAllData();
  }

  /// 更新一条已有记录
  Future<void> updateRecord(MoodRecord record) async {
    await _dbService.updateRecord(record);
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

  // ==================== 药物提醒管理 ====================

  /// 重新调度所有启用药物的提醒通知
  Future<void> _rescheduleAllMedicationReminders() async {
    await _notifications.cancelAllMedicationReminders();

    // 重新设置每日情绪提醒（因为 cancelAll 会清除它）
    if (_prefs.dailyReminderEnabled) {
      await _notifications.scheduleDailyReminder(
        _prefs.dailyReminderTimes,
      );
    }

    // 为每个启用的药物设置提醒
    for (final med in _medications) {
      if (!med.enabled) continue;
      for (int i = 0; i < med.times.length && i < Medication.maxTimes; i++) {
        final parts = med.times[i].split(':');
        if (parts.length != 2) continue;
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null || minute == null) continue;

        await _notifications.scheduleMedicationReminder(
          notificationId: med.notificationIdFor(i),
          name: med.name,
          dosage: med.dosage,
          hour: hour,
          minute: minute,
        );
      }
    }
  }

  /// 添加药物
  Future<void> addMedication(Medication medication) async {
    _medications = [..._medications, medication];
    await _prefs.setMedications(_medications);
    notifyListeners();
    try {
      await _rescheduleAllMedicationReminders();
    } catch (_) {}
  }

  /// 更新药物
  Future<void> updateMedication(Medication medication) async {
    _medications = _medications
        .map((m) => m.id == medication.id ? medication : m)
        .toList();
    await _prefs.setMedications(_medications);
    notifyListeners();
    try {
      await _rescheduleAllMedicationReminders();
    } catch (_) {}
  }

  /// 删除药物
  Future<void> deleteMedication(int id) async {
    _medications = _medications.where((m) => m.id != id).toList();
    await _prefs.setMedications(_medications);
    notifyListeners();
    try {
      await _notifications.cancelMedicationReminder(id);
    } catch (_) {}
  }

  /// 切换药物启用状态
  Future<void> toggleMedicationEnabled(int id) async {
    _medications = _medications
        .map((m) => m.id == id
            ? m.copyWith(enabled: !m.enabled)
            : m)
        .toList();
    await _prefs.setMedications(_medications);
    notifyListeners();
    try {
      await _rescheduleAllMedicationReminders();
    } catch (_) {}
  }
}
