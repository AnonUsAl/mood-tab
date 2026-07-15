import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medication.dart';
import '../models/mood_tag.dart';

/// 偏好设置服务
/// 使用 shared_preferences 管理应用的本地配置
/// 单例模式，确保全局唯一的配置访问入口
class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  SharedPreferences? _prefs;

  // ==================== 存储键名 ====================

  static const _keyDailyReminderEnabled = 'daily_reminder_enabled';
  static const _keyDailyReminderTimes = 'daily_reminder_times'; // JSON list of "HH:mm"
  // 旧 key（向后兼容迁移）
  static const _keyDailyReminderHourLegacy = 'daily_reminder_hour';
  static const _keyDailyReminderMinuteLegacy = 'daily_reminder_minute';
  static const _keyPrivacyLockEnabled = 'privacy_lock_enabled';
  static const _keyPinCode = 'pin_code';
  static const _keyThemeMode = 'theme_mode'; // 'light' | 'dark'
  static const _keyThemeColorIndex = 'theme_color_index';
  static const _keyStreakDays = 'streak_days';
  static const _keyLastCheckInDate = 'last_check_in_date';
  static const _keyCustomTags = 'custom_tags';
  static const _keyUserName = 'user_name';
  static const _keyMedications = 'medications';
  static const _keyGardenDoodles = 'garden_doodles';
  static const _keyEraserSize = 'eraser_size';
  static const _keyDailyReminderStyle = 'daily_reminder_style';
  static const _keyMedicationReminderStyle = 'medication_reminder_style';

  /// 初始化，应在 app 启动时调用
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _prefsInstance {
    if (_prefs == null) {
      throw StateError('PreferencesService 尚未初始化，请先调用 init()');
    }
    return _prefs!;
  }

  // ==================== 每日提醒 ====================

  bool get dailyReminderEnabled =>
      _prefsInstance.getBool(_keyDailyReminderEnabled) ?? false;

  Future<void> setDailyReminderEnabled(bool value) =>
      _prefsInstance.setBool(_keyDailyReminderEnabled, value);

  /// 每日提醒时间列表，格式 ["08:00", "20:00"]
  /// 默认 ["20:00"]
  List<String> get dailyReminderTimes {
    final jsonStr = _prefsInstance.getString(_keyDailyReminderTimes);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        return (jsonDecode(jsonStr) as List).cast<String>();
      } catch (_) {}
    }
    // 向后兼容：从旧的单一 hour/minute 迁移
    final hour = _prefsInstance.getInt(_keyDailyReminderHourLegacy);
    final minute = _prefsInstance.getInt(_keyDailyReminderMinuteLegacy);
    if (hour != null) {
      final time = '${hour.toString().padLeft(2, '0')}:${(minute ?? 0).toString().padLeft(2, '0')}';
      // 迁移并清除旧 key
      setDailyReminderTimes([time]);
      _prefsInstance.remove(_keyDailyReminderHourLegacy);
      _prefsInstance.remove(_keyDailyReminderMinuteLegacy);
      return [time];
    }
    return ['20:00'];
  }

  Future<void> setDailyReminderTimes(List<String> times) async {
    final jsonStr = jsonEncode(times);
    await _prefsInstance.setString(_keyDailyReminderTimes, jsonStr);
  }

  // ==================== 隐私锁 ====================

  bool get privacyLockEnabled =>
      _prefsInstance.getBool(_keyPrivacyLockEnabled) ?? false;

  Future<void> setPrivacyLockEnabled(bool value) =>
      _prefsInstance.setBool(_keyPrivacyLockEnabled, value);

  String get pinCode => _prefsInstance.getString(_keyPinCode) ?? '';

  Future<void> setPinCode(String value) =>
      _prefsInstance.setString(_keyPinCode, value);

  // ==================== 主题设置 ====================

  /// 主题模式：'light' 或 'dark'
  String get themeMode => _prefsInstance.getString(_keyThemeMode) ?? 'light';

  Future<void> setThemeMode(String value) =>
      _prefsInstance.setString(_keyThemeMode, value);

  /// 主题色索引
  int get themeColorIndex => _prefsInstance.getInt(_keyThemeColorIndex) ?? 0;

  Future<void> setThemeColorIndex(int value) =>
      _prefsInstance.setInt(_keyThemeColorIndex, value);

  // ==================== 打卡天数 ====================

  int get streakDays => _prefsInstance.getInt(_keyStreakDays) ?? 0;

  Future<void> setStreakDays(int value) =>
      _prefsInstance.setInt(_keyStreakDays, value);

  String get lastCheckInDate =>
      _prefsInstance.getString(_keyLastCheckInDate) ?? '';

  Future<void> setLastCheckInDate(String value) =>
      _prefsInstance.setString(_keyLastCheckInDate, value);

  // ==================== 自定义标签 ====================

  /// 获取自定义标签列表
  List<MoodTag> getCustomTags() {
    final jsonStr = _prefsInstance.getString(_keyCustomTags);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List;
      return list
          .map((e) => MoodTag.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 保存自定义标签列表
  Future<void> setCustomTags(List<MoodTag> tags) async {
    final jsonStr =
        jsonEncode(tags.map((t) => t.toJson()).toList());
    await _prefsInstance.setString(_keyCustomTags, jsonStr);
  }

  // ==================== 用户名 ====================

  /// 用户昵称，未设置时返回空字符串
  String get userName => _prefsInstance.getString(_keyUserName) ?? '';

  Future<void> setUserName(String value) =>
      _prefsInstance.setString(_keyUserName, value);

  // ==================== 药物提醒 ====================

  /// 获取药物列表
  List<Medication> getMedications() {
    final jsonStr = _prefsInstance.getString(_keyMedications);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List;
      return list
          .map((e) => Medication.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 保存药物列表
  Future<void> setMedications(List<Medication> medications) async {
    final jsonStr =
        jsonEncode(medications.map((m) => m.toJson()).toList());
    await _prefsInstance.setString(_keyMedications, jsonStr);
  }

  // ==================== 打卡逻辑 ====================

  /// 检查并更新打卡连续天数
  ///
  /// 规则：
  /// - 如果今天已打卡，返回当前连续天数（不重复计算）
  /// - 如果上次打卡是昨天，连续天数 +1
  /// - 否则重置为 1
  Future<int> checkAndUpdateStreak() async {
    final today = _formatDate(DateTime.now());
    final lastDate = lastCheckInDate;

    if (today == lastDate) {
      return streakDays;
    }

    int newStreak;
    if (lastDate.isNotEmpty) {
      final lastDateTime = _parseDate(lastDate);
      final todayDate = DateTime.now();
      final diff = todayDate.difference(lastDateTime).inDays;
      if (diff == 1) {
        newStreak = streakDays + 1;
      } else {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    await setStreakDays(newStreak);
    await setLastCheckInDate(today);
    return newStreak;
  }

  // ==================== 情绪花园涂鸦 ====================

  /// 保存涂鸦 JSON（Stroke 列表的序列化字符串）
  Future<void> setGardenDoodles(String jsonStr) =>
      _prefsInstance.setString(_keyGardenDoodles, jsonStr);

  /// 读取涂鸦 JSON，无数据时返回空 JSON 数组字符串
  String get gardenDoodles =>
      _prefsInstance.getString(_keyGardenDoodles) ?? '[]';

  /// 橡皮擦大小
  Future<void> setEraserSize(double value) =>
      _prefsInstance.setDouble(_keyEraserSize, value);

  double get eraserSize =>
      _prefsInstance.getDouble(_keyEraserSize) ?? 12.0;

  // ==================== 提醒风格 ====================

  /// 'notification' (系统通知) 或 'alarm' (闹钟)
  String get dailyReminderStyle =>
      _prefsInstance.getString(_keyDailyReminderStyle) ?? 'notification';

  Future<void> setDailyReminderStyle(String value) =>
      _prefsInstance.setString(_keyDailyReminderStyle, value);

  String get medicationReminderStyle =>
      _prefsInstance.getString(_keyMedicationReminderStyle) ?? 'notification';

  Future<void> setMedicationReminderStyle(String value) =>
      _prefsInstance.setString(_keyMedicationReminderStyle, value);

  // ==================== 工具方法 ====================

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  DateTime _parseDate(String s) {
    final parts = s.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
