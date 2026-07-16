import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'preferences_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _dailyReminderIdBase = 100;
  static const int _maxDailyReminderTimes = 10;
  static const String _channelId = 'daily_reminder';
  static const String _channelName = '每日情绪记录提醒';
  static const String _medChannelId = 'medication_reminder';
  static const String _medChannelName = '用药提醒';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    if (!_initialized) await init();
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      if (granted != null && !granted) return false;
    }
    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true, badge: true, sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  Future<void> requestExactAlarmPermission() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.requestExactAlarmsPermission();
    }
  }

  AndroidNotificationDetails _androidDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
    required String stylePreference,
  }) {
    if (stylePreference == 'alarm') {
      return AndroidNotificationDetails(
        channelId, channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        icon: '@drawable/ic_notification',
        enableVibration: true,
        playSound: true,
        category: AndroidNotificationCategory.alarm,
      );
    }
    return AndroidNotificationDetails(
      channelId, channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
    );
  }

  DarwinNotificationDetails _iosDetails(String stylePreference) {
    if (stylePreference == 'alarm') {
      // 闹钟模式：时间敏感级别，可穿透专注模式
      return const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );
    }
    return const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
  }

  Future<void> scheduleDailyReminder(List<String> times) async {
    if (!_initialized) await init();
    await requestPermissions();
    await requestExactAlarmPermission();
    await cancelDailyReminders();

    final prefs = PreferencesService();
    final androidDetails = _androidDetails(
      channelId: _channelId,
      channelName: _channelName,
      channelDescription: '每天定时提醒你记录情绪',
      stylePreference: prefs.dailyReminderStyle,
    );
    final iosDetails = _iosDetails(prefs.dailyReminderStyle);
    final details = NotificationDetails(
      android: androidDetails, iOS: iosDetails,
    );

    for (int i = 0; i < times.length && i < _maxDailyReminderTimes; i++) {
      final parts = times[i].split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute,
      );
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        _dailyReminderIdBase + i,
        '记录此刻的心情 🌿',
        '花一分钟，写下今天的情绪吧',
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelDailyReminders() async {
    for (int i = 0; i < _maxDailyReminderTimes; i++) {
      await _plugin.cancel(_dailyReminderIdBase + i);
    }
  }

  // ==================== 药物提醒 ====================

  Future<void> scheduleMedicationReminder({
    required int notificationId,
    required String name,
    required String dosage,
    required int hour,
    required int minute,
  }) async {
    if (!_initialized) await init();
    await requestPermissions();
    await requestExactAlarmPermission();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, hour, minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final prefs = PreferencesService();
    final androidDetails = _androidDetails(
      channelId: _medChannelId,
      channelName: _medChannelName,
      channelDescription: '药物服用提醒',
      stylePreference: prefs.medicationReminderStyle,
    );
    final iosDetails = _iosDetails(prefs.medicationReminderStyle);
    final details = NotificationDetails(
      android: androidDetails, iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      notificationId,
      '该吃药了 💊 $name',
      '剂量：$dosage · 记得按时服药哦',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelMedicationReminder(int medicationId) async {
    for (int i = 0; i < 10; i++) {
      await _plugin.cancel(medicationId * 10 + i);
    }
  }

  Future<void> cancelAllMedicationReminders() async {
    await _plugin.cancelAll();
  }
}
