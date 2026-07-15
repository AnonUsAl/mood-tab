import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// 本地通知服务
/// 使用 flutter_local_notifications 管理每日情绪记录提醒
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _dailyReminderId = 0;
  static const String _channelId = 'daily_reminder';
  static const String _channelName = '每日情绪记录提醒';

  bool _initialized = false;

  /// 初始化通知插件和时区数据
  Future<void> init() async {
    if (_initialized) return;

    // 初始化时区数据
    tz_data.initializeTimeZones();

    // Android 配置
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS / macOS 配置
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

  /// 请求通知权限（主要针对 iOS）
  Future<bool> requestPermissions() async {
    if (!_initialized) await init();

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  /// 设置每日定时提醒
  ///
  /// [hour] 小时（0-23），[minute] 分钟（0-59）
  /// 每天在指定时间发送通知，如果今天该时间已过则从明天开始
  Future<void> scheduleDailyReminder(int hour, int minute) async {
    if (!_initialized) await init();
    await requestPermissions();

    // 先取消已有的提醒
    await cancelReminder();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // 如果今天的时间已过，从明天开始
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: '每天定时提醒你记录情绪',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      _dailyReminderId,
      '记录此刻的心情 🌿',
      '花一分钟，写下今天的情绪吧',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// 取消每日提醒
  Future<void> cancelReminder() async {
    // cancelAll 清除所有已展示的通知和待调度通知
    // 确保新通知弹出时挤掉上一个
    await _plugin.cancelAll();
  }
}
