import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'preferences_service.dart';

/// 本地提醒服务。
///
/// ## 平台能力（flutter_local_notifications 22.x）
/// - Android / iOS / macOS / Linux：原生支持 `matchDateTimeComponents` 循环提醒。
/// - **Windows：不支持循环提醒**。官方文档明确写着
///   「On Windows, this will only set a notification on the scheduledDate,
///   and not repeat, regardless of the value for matchDateTimeComponents」。
///   底层用的是 `ScheduledToastNotification` + `AddToSchedule`，天生只能单次触发。
///
/// 所以 Windows 上的「每天提醒」是靠**展开**实现的：一次把未来若干天的
/// 提醒都排成独立的一次性 toast（见 [_windowsHorizonDays]），
/// 并在每次启动时重新挂钩（`main.dart` 启动流程里会重新调度）。
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ==================== ID 规划 ====================

  /// 每日提醒逻辑 ID：100 ~ 109
  static const int _dailyReminderIdBase = 100;
  static const int _maxDailyReminderTimes = 10;

  /// 用药提醒逻辑 ID：200 ~ 999（80 药物 × 10 时间点）
  static const int _medReminderIdBase = 200;
  static const int _maxMedReminders = 800;

  /// Windows 上真正下发给系统的 toast ID，与逻辑 ID 分处不同区间，
  /// 避免和移动端的 ID 语义混淆：
  ///   每日：[10000, 10000 + 10 * 7)
  ///   用药：[20000, 20000 + 800 * 7)
  static const int _windowsDailyBandBase = 10000;
  static const int _windowsMedBandBase = 20000;

  /// Windows 上的展开天数：一次排未来 7 天。
  /// 用户 7 天没打开过 App 才可能断档，之后一启动就会自动续上。
  static const int _windowsHorizonDays = 7;

  /// Windows 单个应用最多约 4096 条计划通知，这里留足余量。
  static const int _windowsToastBudget = 2000;

  /// Windows 初始化身份（会在注册表 HKCU\Software\Classes\AppUserModelId 下登记）
  static const String _windowsAppUserModelId = 'ClouderyStudio.MoodTab';
  static const String _windowsAppName = '脑电波';

  /// 通知激活回调的 GUID，必须固定不变（生成一次后写死）
  static const String _windowsGuid = 'a44873bf-dade-4e0e-85bd-8eb7f978f76b';

  // ==================== 频道 ====================

  static const String _channelId = 'daily_reminder_notify';
  static const String _channelName = '每日情绪记录提醒';
  static const String _alarmChannelId = 'daily_reminder_alarm';
  static const String _medChannelId = 'medication_reminder_notify';
  static const String _medChannelName = '用药提醒';
  static const String _medAlarmChannelId = 'medication_reminder_alarm';

  /// 全局导航器，用于通知点击时跳转页面
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  bool _initialized = false;

  /// 当前平台没有通知实现，所有操作直接跳过（见 [_isSupported]）。
  /// 目前只有 Web 会走到这里。
  bool _disabled = false;

  /// 缓存精确闹钟权限状态，避免重复尝试失败
  bool? _canUseExactAlarm;

  // ==================== 平台判定 ====================

  static bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  /// flutter_local_notifications 19.0.0 起实现了 Windows（Toast Notifications）。
  /// Web 端需要 service worker 与额外的初始化配置，这里暂不启用。
  static bool get _isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

  /// 给定逻辑提醒条数时，Windows 上合适的展开天数。
  ///
  /// 展开后的 toast 总数 = 逻辑条数 × 天数，需要压在系统上限内。
  /// 药物提醒最多 800 条，此时自动退到 2 天；日常几条时用满 7 天。
  static int windowsHorizonFor(int logicalCount) {
    if (logicalCount <= 0) return _windowsHorizonDays;
    final int days = _windowsToastBudget ~/ logicalCount;
    return days.clamp(1, _windowsHorizonDays);
  }

  // ==================== 初始化 ====================

  Future<void> init() async {
    if (_initialized) return;
    if (!_isSupported) {
      _disabled = true;
      _initialized = true;
      debugPrint('NotificationService: 当前平台不支持本地通知，已降级为 no-op');
      return;
    }
    // 插件没有为本平台注册实现时，后续调用都会抛 MissingPluginException。
    // 提前判定，免得每次打开提醒开关才报一次错。
    if (_isWindows &&
        _plugin
                .resolvePlatformSpecificImplementation<
                  FlutterLocalNotificationsWindows
                >() ==
            null) {
      _disabled = true;
      _initialized = true;
      debugPrint('NotificationService: 未找到 Windows 通知实现（FFI 插件未注册），已降级为 no-op');
      return;
    }

    tz_data.initializeTimeZones();
    _updateLocalTimeZone();
    _canUseExactAlarm = null; // 初始化时重置权限缓存

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings darwinSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    const LinuxInitializationSettings linuxSettings =
        LinuxInitializationSettings(defaultActionName: 'Open notification');
    const WindowsInitializationSettings windowsSettings =
        WindowsInitializationSettings(
          appName: _windowsAppName,
          appUserModelId: _windowsAppUserModelId,
          guid: _windowsGuid,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      // macOS 也必须提供设置，否则 initialize() 会抛 ArgumentError
      macOS: darwinSettings,
      linux: linuxSettings,
      windows: windowsSettings,
    );

    try {
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );
      _initialized = true;
    } catch (e) {
      // 初始化失败不应该拖垮启动流程：整个服务退化为 no-op
      _disabled = true;
      _initialized = true;
      debugPrint('NotificationService: 初始化失败，已降级为 no-op — $e');
    }
  }

  /// 通知点击回调 — 跳转到主页
  static void _onNotificationResponse(NotificationResponse response) {
    debugPrint(
      'Notification tapped: id=${response.id}, payload=${response.payload}',
    );
    final nav = navigatorKey.currentState;
    if (nav != null) {
      nav.pushNamedAndRemoveUntil('/', (_) => false);
    }
  }

  /// 根据用户设置的时区更新 tz.local
  void _updateLocalTimeZone() {
    final prefs = PreferencesService();
    final tzName = prefs.timeZone;
    try {
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    }
  }

  /// 用户更改时区后调用，重新初始化时区并重新调度通知
  Future<void> refreshTimeZone() async {
    _updateLocalTimeZone();
  }

  // ==================== 权限 ====================

  /// 检查通知权限是否已授予（不弹出系统对话框）
  Future<bool> areNotificationsEnabled() async {
    if (!_initialized) await init();
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      return await androidImpl.areNotificationsEnabled() ?? false;
    }
    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosImpl != null) {
      final result = await iosImpl.checkPermissions();
      return result?.isEnabled ?? false;
    }
    return true;
  }

  /// 检查通知权限，未授予则申请
  /// 返回 true 表示当前已拥有通知权限
  Future<bool> ensurePermissions() async {
    if (!_initialized) await init();
    final hasPermission = await areNotificationsEnabled();
    if (hasPermission) return true;
    // 未授予，弹出系统权限申请对话框
    return requestPermissions();
  }

  Future<bool> requestPermissions() async {
    if (!_initialized) await init();
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      if (granted != null && !granted) return false;
    }
    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    // 桌面端（Windows / Linux）没有可申请的运行时权限，交由系统设置管理
    return true;
  }

  Future<bool> requestExactAlarmPermission() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      try {
        return await androidImpl.requestExactAlarmsPermission() ?? false;
      } catch (e) {
        debugPrint('requestExactAlarmsPermission error: $e');
        return false;
      }
    }
    return true;
  }

  /// 检查当前是否拥有精确闹钟权限（Android 12+）
  /// 返回 true 表示可以使用 exactAllowWhileIdle / alarmClock 模式
  Future<bool> canScheduleExactAlarms() async {
    if (!_initialized) await init();
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl == null) return true; // 非 Android 平台视为有权限
    try {
      return await androidImpl.canScheduleExactNotifications() ?? false;
    } catch (e) {
      debugPrint('canScheduleExactAlarms error: $e');
      return false;
    }
  }

  /// 检查是否拥有精确闹钟权限，没有则尝试请求
  /// 药物提醒为时间敏感型，主动确保精确调度权限可用
  Future<bool> _ensureExactAlarm() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl == null) return true; // 非 Android 平台
    try {
      final canSchedule = await androidImpl.canScheduleExactNotifications();
      if (canSchedule == true) {
        _canUseExactAlarm = true;
        return true;
      }
      // 没有精确闹钟权限，尝试请求（每次启动都尝试，不依赖缓存）
      if (_canUseExactAlarm != true) {
        final granted =
            await androidImpl.requestExactAlarmsPermission() ?? false;
        if (granted) {
          _canUseExactAlarm = true;
          return true;
        }
      }
      // 再次检查（用户可能已手动在系统设置中开启）
      final recheck = await androidImpl.canScheduleExactNotifications();
      if (recheck == true) {
        _canUseExactAlarm = true;
        return true;
      }
    } catch (e) {
      debugPrint('_ensureExactAlarm permission check error: $e');
    }
    // 确认无精确闹钟权限，但不永久缓存——下次启动仍会重新检查
    _canUseExactAlarm = false;
    return false;
  }

  // ==================== 调度公共部分 ====================

  /// 根据提醒风格选择调度模式
  /// 药物提醒为时间敏感型通知，始终优先使用精确调度确保后台可靠触发。
  /// 风格偏好（通知/闹钟）仅影响通知的外观表现，不影响调度精确度。
  AndroidScheduleMode _resolveScheduleMode(bool hasExactAlarm) {
    if (hasExactAlarm) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    // 无精确闹钟权限时回退到不精确模式
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// 计算从「下一个」开始、连续 [count] 个日历日的触发时刻。
  ///
  /// 两个要点：
  /// 1. 以**日历日**推进（`DateTime(y, m, d + n)` 再构造 `TZDateTime`），
  ///    而不是叠加 `Duration(days: n)` —— 后者跨夏令时切换会偏移一小时。
  /// 2. 「今天这个点已过」的基准偏移只算一次并统一应用到所有天，
  ///    否则 day0 顺延到明天、day1 又是明天，会排出两条同一时刻的重复提醒。
  ///
  /// 返回的时刻一定都在当前时间之后（Windows 的实现对过去时间会抛错）。
  List<tz.TZDateTime> _occurrences(int hour, int minute, int count) {
    final now = tz.TZDateTime.now(tz.local);
    final today = DateTime(now.year, now.month, now.day);
    final firstToday = tz.TZDateTime(
      tz.local,
      today.year,
      today.month,
      today.day,
      hour,
      minute,
    );
    final int baseShift = firstToday.isAfter(now) ? 0 : 1;

    final result = <tz.TZDateTime>[];
    for (int d = 0; d < count; d++) {
      final target = DateTime(
        today.year,
        today.month,
        today.day + baseShift + d,
      );
      result.add(
        tz.TZDateTime(
          tz.local,
          target.year,
          target.month,
          target.day,
          hour,
          minute,
        ),
      );
    }
    return result;
  }

  /// 提交一条定时通知，返回**实际生效**的调度模式。
  ///
  /// 原生层拒绝精确闹钟时会自动降级到不精确模式重试，
  /// 调用方用返回值更新后续循环用的模式，避免每条都失败一次。
  Future<AndroidScheduleMode> _zonedSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduled,
    required NotificationDetails details,
    required AndroidScheduleMode scheduleMode,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    Future<void> attempt(AndroidScheduleMode mode) => _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: mode,
      matchDateTimeComponents: matchDateTimeComponents,
    );

    try {
      await attempt(scheduleMode);
      return scheduleMode;
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted' &&
          scheduleMode != AndroidScheduleMode.inexactAllowWhileIdle) {
        // 原生层拒绝精确闹钟，回退到不精确模式重新调度
        _canUseExactAlarm = false;
        try {
          await attempt(AndroidScheduleMode.inexactAllowWhileIdle);
          return AndroidScheduleMode.inexactAllowWhileIdle;
        } catch (retryError) {
          debugPrint('zonedSchedule retry failed id=$id: $retryError');
          return scheduleMode;
        }
      }
      debugPrint('zonedSchedule failed id=$id code=${e.code}: $e');
      return scheduleMode;
    } catch (e) {
      // 覆盖桌面端可能抛出的 UnimplementedError / StateError 等，
      // 单条提醒失败不应该中断其余提醒的调度
      debugPrint('zonedSchedule failed id=$id: $e');
      return scheduleMode;
    }
  }

  // ==================== 每日提醒 ====================

  Future<void> scheduleDailyReminder(List<String> times) async {
    if (!_initialized) await init();
    if (_disabled) return;
    final hasExactAlarm = await _ensureExactAlarm();
    await cancelDailyReminders();

    final prefs = PreferencesService();
    final stylePref = prefs.dailyReminderStyle;
    final channelId = stylePref == 'alarm' ? _alarmChannelId : _channelId;
    final androidDetails = _androidDetails(
      channelId: channelId,
      channelName: _channelName,
      channelDescription: '每天定时提醒你记录情绪',
      stylePreference: stylePref,
    );
    final iosDetails = _iosDetails(stylePref);
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    var scheduleMode = _resolveScheduleMode(hasExactAlarm);

    const String title = '记录此刻的心情 🌿';
    const String body = '花一分钟，写下今天的情绪吧';

    for (int i = 0; i < times.length && i < _maxDailyReminderTimes; i++) {
      final parts = times[i].split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      // Windows 要展开成多天，其它平台靠 matchDateTimeComponents 循环，只需一条
      final occurrences = _occurrences(
        hour,
        minute,
        _isWindows ? _windowsHorizonDays : 1,
      );

      if (_isWindows) {
        for (int day = 0; day < occurrences.length; day++) {
          scheduleMode = await _zonedSchedule(
            id: _windowsDailyBandBase + i + day * _maxDailyReminderTimes,
            title: title,
            body: body,
            scheduled: occurrences[day],
            details: details,
            scheduleMode: scheduleMode,
          );
        }
      } else {
        scheduleMode = await _zonedSchedule(
          id: _dailyReminderIdBase + i,
          title: title,
          body: body,
          scheduled: occurrences.first,
          details: details,
          scheduleMode: scheduleMode,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    }
  }

  Future<void> cancelDailyReminders() async {
    if (!_initialized) await init();
    if (_disabled) return;
    if (_isWindows) {
      await _cancelWindowsWhere(
        (id) =>
            id >= _windowsDailyBandBase &&
            id <
                _windowsDailyBandBase +
                    _maxDailyReminderTimes * _windowsHorizonDays,
      );
      return;
    }
    for (int i = 0; i < _maxDailyReminderTimes; i++) {
      await _plugin.cancel(id: _dailyReminderIdBase + i);
    }
  }

  // ==================== 药物提醒 ====================

  /// [windowsHorizonDays] 只在 Windows 生效：调用方知道当前启用的提醒总条数，
  /// 可以据此算出合适的展开天数（见 [windowsHorizonFor]）。
  Future<void> scheduleMedicationReminder({
    required int notificationId,
    required String name,
    required String dosage,
    required int hour,
    required int minute,
    int windowsHorizonDays = _windowsHorizonDays,
  }) async {
    if (!_initialized) await init();
    if (_disabled) return;
    final hasExactAlarm = await _ensureExactAlarm();

    final prefs = PreferencesService();
    final stylePref = prefs.medicationReminderStyle;
    final channelId = stylePref == 'alarm' ? _medAlarmChannelId : _medChannelId;
    final androidDetails = _androidDetails(
      channelId: channelId,
      channelName: _medChannelName,
      channelDescription: '药物服用提醒',
      stylePreference: stylePref,
    );
    final iosDetails = _iosDetails(stylePref);
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final String title = '该吃药了 💊 $name';
    final String body = '剂量：$dosage · 记得按时服药哦';

    var scheduleMode = _resolveScheduleMode(hasExactAlarm);

    if (_isWindows) {
      final logicalIndex = notificationId - _medReminderIdBase;
      if (logicalIndex < 0 || logicalIndex >= _maxMedReminders) {
        debugPrint('scheduleMedicationReminder 收到越界 ID: $notificationId');
        return;
      }
      final horizon = windowsHorizonDays.clamp(1, _windowsHorizonDays);
      final occurrences = _occurrences(hour, minute, horizon);
      for (int day = 0; day < occurrences.length; day++) {
        scheduleMode = await _zonedSchedule(
          id: _windowsMedBandBase + logicalIndex + day * _maxMedReminders,
          title: title,
          body: body,
          scheduled: occurrences[day],
          details: details,
          scheduleMode: scheduleMode,
        );
      }
      return;
    }

    await _zonedSchedule(
      id: notificationId,
      title: title,
      body: body,
      scheduled: _occurrences(hour, minute, 1).first,
      details: details,
      scheduleMode: scheduleMode,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelMedicationReminder(int medIndex) async {
    if (!_initialized) await init();
    if (_disabled) return;
    if (_isWindows) {
      final lo = medIndex * 10;
      final hi = lo + 10;
      await _cancelWindowsWhere((id) {
        final offset = id - _windowsMedBandBase;
        if (offset < 0 || offset >= _maxMedReminders * _windowsHorizonDays) {
          return false;
        }
        final logical = offset % _maxMedReminders;
        return logical >= lo && logical < hi;
      });
      return;
    }
    for (int i = 0; i < 10; i++) {
      await _plugin.cancel(id: _medReminderIdBase + medIndex * 10 + i);
    }
  }

  /// 取消所有药物提醒（不影响每日提醒）
  Future<void> cancelAllMedicationReminders() async {
    if (!_initialized) await init();
    if (_disabled) return;
    if (_isWindows) {
      await _cancelWindowsWhere(
        (id) =>
            id >= _windowsMedBandBase &&
            id < _windowsMedBandBase + _maxMedReminders * _windowsHorizonDays,
      );
      return;
    }
    // 只取消药物提醒范围内的 ID（200~999），避免误删每日提醒（100~109）
    for (int i = 0; i < _maxMedReminders; i++) {
      await _plugin.cancel(id: _medReminderIdBase + i);
    }
  }

  // ==================== Windows 取消辅助 ====================

  /// Windows 上按条件取消待触发通知。
  ///
  /// 这里刻意不走「枚举 ID 逐个 cancel」的路子：Windows 的
  /// `cancel(id)` 每次调用都会遍历一遍系统里已挂的计划通知，
  /// 用 800 个 ID 去撞会退化成 O(n²)。改成先把待触发列表拉一次
  /// （`pendingNotificationRequests()`，Windows 上无需 MSIX 包身份即可用），
  /// 再只对命中区间的那些 ID 下发取消。
  Future<void> _cancelWindowsWhere(bool Function(int id) test) async {
    final List<PendingNotificationRequest> pending;
    try {
      pending = await _plugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('pendingNotificationRequests failed: $e');
      return;
    }
    for (final request in pending) {
      if (!test(request.id)) continue;
      try {
        await _plugin.cancel(id: request.id);
      } catch (e) {
        debugPrint('cancel notification ${request.id} failed: $e');
      }
    }
  }

  // ==================== 通知样式 ====================

  AndroidNotificationDetails _androidDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
    required String stylePreference,
  }) {
    if (stylePreference == 'alarm') {
      return AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        icon: '@drawable/ic_notification',
        enableVibration: true,
        playSound: true,
        // 使用系统默认闹钟提示音（区别于通知的提示音）
        sound: const UriAndroidNotificationSound(
          'content://settings/system/alarm_alert',
        ),
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        // 闹钟模式：持续展示直到用户操作
        ongoing: true,
        autoCancel: false,
        showWhen: true,
        usesChronometer: false,
        color: const Color(0xFFE53935),
      );
    }
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
      visibility: NotificationVisibility.public,
      // 通知模式：可滑动清除
      ongoing: false,
      autoCancel: true,
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
}
