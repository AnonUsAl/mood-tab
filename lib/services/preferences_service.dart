import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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
  static const _keyDailyReminderHour = 'daily_reminder_hour';
  static const _keyDailyReminderMinute = 'daily_reminder_minute';
  static const _keyPrivacyLockEnabled = 'privacy_lock_enabled';
  static const _keyPinCode = 'pin_code';
  static const _keyThemeMode = 'theme_mode'; // 'light' | 'dark'
  static const _keyThemeColorIndex = 'theme_color_index';
  static const _keyStreakDays = 'streak_days';
  static const _keyLastCheckInDate = 'last_check_in_date';
  static const _keyCustomTags = 'custom_tags';

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

  int get dailyReminderHour =>
      _prefsInstance.getInt(_keyDailyReminderHour) ?? 20;

  Future<void> setDailyReminderHour(int value) =>
      _prefsInstance.setInt(_keyDailyReminderHour, value);

  int get dailyReminderMinute =>
      _prefsInstance.getInt(_keyDailyReminderMinute) ?? 0;

  Future<void> setDailyReminderMinute(int value) =>
      _prefsInstance.setInt(_keyDailyReminderMinute, value);

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
