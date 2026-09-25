import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'pages/home_page.dart';
import 'pages/calendar_page.dart';
import 'pages/stats_page.dart';
import 'pages/settings_page.dart';
import 'pages/mood_record_page.dart';
import 'pages/splash_page.dart';
import 'pages/privacy_lock_page.dart';
import 'pages/privacy_policy_page.dart';
import 'pages/author_info_page.dart';
import 'providers/mood_provider.dart';
import 'services/preferences_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'utils/pin_code.dart';
import 'widgets/desktop_viewport.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MoodTabApp());
}

class MoodTabApp extends StatelessWidget {
  const MoodTabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MoodProvider(),
      child: Consumer<MoodProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            title: '脑电波',
            debugShowCheckedModeBanner: false,
            navigatorKey: NotificationService.navigatorKey,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: provider.themeMode == 'dark'
                ? ThemeMode.dark
                : provider.themeMode == 'system'
                ? ThemeMode.system
                : ThemeMode.light,
            // 桌面端（Windows / Linux / macOS）的窗口尺寸兜底：
            // 窗口可随意缩放、横向拉大内容就跟着变宽；只有窗口被缩到小于
            // 内容最小尺寸时才锁住内容并改为滚动。移动端 / Web 不受影响。
            builder: (context, child) =>
                DesktopViewport(child: child ?? const SizedBox.shrink()),
            home: const _AppEntrance(),
          );
        },
      ),
    );
  }
}

/// 启动入口：先显示 SplashPage，加载完成后切换到主页
class _AppEntrance extends StatefulWidget {
  const _AppEntrance();

  @override
  State<_AppEntrance> createState() => _AppEntranceState();
}

class _AppEntranceState extends State<_AppEntrance>
    with WidgetsBindingObserver {
  final PreferencesService _preferences = PreferencesService();
  final NotificationService _notifications = NotificationService();
  bool _showSplash = true;
  bool _showPrivacy = false;
  bool _showAuthorInfo = false;
  bool _isLocked = false;
  bool _preferencesReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MoodProvider>().loadAllData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 是否需要上锁：开关已开 + 存的 PIN 是合法值。
  ///
  /// 只把上锁挂在 [didChangeAppLifecycleState] 上是不够的 ——
  /// Windows 上「关闭窗口」是**直接结束进程**，根本不会有 paused / hidden 回调，
  /// 于是设过 PIN 的用户重新打开应用时完全不会被要求输入密码，
  /// 表现就是「设了密码也没用」（手机端进程被系统回收后重新启动同理）。
  /// 所以冷启动也要走一次这个判断。
  bool get _shouldLock =>
      _preferences.privacyLockEnabled && isValidPin(_preferences.pinCode);

  /// 在已登录态之外补一次上锁。必须在 `setState` 里调用。
  void _lockIfNeeded() {
    if (!_isLocked && _shouldLock) {
      _isLocked = true;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_preferencesReady || _showSplash) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (!_isLocked) {
        setState(_lockIfNeeded);
      }
    }
  }

  Future<void> _onSplashDone() async {
    final provider = context.read<MoodProvider>();
    // 等待 provider 加载完成，不再依赖 totalCount 条件
    int retries = 0;
    while (provider.isLoading && retries < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      retries++;
    }
    if (!mounted) return;

    try {
      await _preferences.init();
      await _notifications.init();
      // 先检查通知权限是否已授予，未授予才申请
      await _notifications.ensurePermissions();
    } catch (e) {
      debugPrint('Initialization error: $e');
    }

    // 检查精确闹钟权限，未授予才申请
    try {
      final hasExactAlarm = await _notifications.canScheduleExactAlarms();
      if (!hasExactAlarm) {
        final granted = await _notifications.requestExactAlarmPermission();
        if (!granted) {
          debugPrint('Exact alarm permission denied by user');
        }
      }
    } catch (e) {
      debugPrint('Request exact alarm permission error: $e');
    }

    if (!mounted) return;
    setState(() {
      _showSplash = false;
      _preferencesReady = true;
      // 冷启动上锁。首次启动时隐私协议还没同意，这里先不锁，
      // 等协议页 / 作者信息页走完再补（见下面两处 onAccept / onContinue）。
      if (_preferences.privacyPolicyAccepted) {
        _lockIfNeeded();
      }
    });

    // 首次启动：检查隐私协议是否已同意
    if (!_preferences.privacyPolicyAccepted) {
      setState(() => _showPrivacy = true);
      return;
    }

    // 通知调度在后台异步执行，不阻塞 UI 启动
    _scheduleNotificationsInBackground(provider);
  }

  /// 后台异步调度通知，避免阻塞主页启动
  void _scheduleNotificationsInBackground(MoodProvider provider) async {
    try {
      if (_preferences.dailyReminderEnabled &&
          _preferences.dailyReminderTimes.isNotEmpty) {
        await _notifications.scheduleDailyReminder(
          _preferences.dailyReminderTimes,
        );
      }
      // 启动时重新调度所有药物提醒（应对设备重启等场景）
      await provider.rescheduleMedicationReminders();
    } catch (e) {
      debugPrint('Schedule notification error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashPage(onAnimationEnd: _onSplashDone);
    }
    if (_showPrivacy) {
      final provider = context.read<MoodProvider>();
      return PrivacyPolicyPage(
        onAccept: () async {
          await _preferences.setPrivacyPolicyAccepted(true);
          setState(() {
            _showPrivacy = false;
            _showAuthorInfo = true;
          });
          // 隐私协议同意后立即开始调度通知，不等待作者信息页完毕
          _scheduleNotificationsInBackground(provider);
        },
      );
    }
    if (_showAuthorInfo) {
      return AuthorInfoPage(
        onContinue: () async {
          await _preferences.setAuthorInfoShown(true);
          setState(() {
            _showAuthorInfo = false;
            _lockIfNeeded();
          });
        },
      );
    }
    if (_isLocked) {
      return PrivacyLockPage(
        expectedPin: _preferences.pinCode,
        onUnlocked: () => setState(() => _isLocked = false),
      );
    }
    return const MainScaffold();
  }
}

/// 主框架 - 底部导航
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  bool _errorBannerDismissed = false;

  final List<Widget> _pages = const [
    HomePage(),
    CalendarPage(),
    StatsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomBarColor = isDark ? AppTheme.darkCardBg : AppTheme.cardBg;

    final dataError = context.select<MoodProvider, String?>((p) => p.dataError);
    final showErrorBanner = dataError != null && !_errorBannerDismissed;

    return Scaffold(
      body: Column(
        children: [
          if (showErrorBanner) _buildDataErrorBanner(context, dataError),
          Expanded(
            child: IndexedStack(index: _currentIndex, children: _pages),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 0,
        color: bottomBarColor,
        surfaceTintColor: Colors.transparent,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              Expanded(
                child: _buildNavItem(0, Icons.home_outlined, Icons.home, '今日'),
              ),
              Expanded(
                child: _buildNavItem(
                  1,
                  Icons.calendar_month_outlined,
                  Icons.calendar_month,
                  '日历',
                ),
              ),
              Expanded(child: _buildRecordNavItem()),
              Expanded(
                child: _buildNavItem(
                  2,
                  Icons.bar_chart_outlined,
                  Icons.bar_chart,
                  '统计',
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  3,
                  Icons.person_outline,
                  Icons.person,
                  '我的',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 本地数据库不可用时的顶部横幅。
  ///
  /// 桌面端（尤其 Windows）一旦数据库打不开，界面只会「一片空白 + 存不进去」，
  /// 用户完全看不出原因，只会觉得「记录丢了 / 保存没反应」。
  /// 这条横幅把原因摆到台面上，并且可以一键复制详情用于排查。
  Widget _buildDataErrorBanner(BuildContext context, String detail) {
    return Material(
      color: const Color(0xFFB3261E),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.storage_outlined,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '本地数据库不可用，记录读不到也存不进去。点右侧按钮可复制原因。',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
              IconButton(
                tooltip: '复制详情',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.copy, color: Colors.white, size: 18),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: detail));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已复制失败详情')),
                  );
                },
              ),
              IconButton(
                tooltip: '先忽略',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                onPressed: () => setState(() => _errorBannerDismissed = true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 中间的「记录」入口 —— 不是切换 tab，而是打开记录页
  Widget _buildRecordNavItem() {
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MoodRecordPage()));
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.edit_note, size: 22, color: Colors.white),
          ),
          const SizedBox(height: 2),
          const Text(
            '记录',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isActive = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppTheme.primaryColor;
    final inactiveColor = isDark ? AppTheme.darkTextHint : AppTheme.textHint;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            size: 24,
            color: isActive ? activeColor : inactiveColor,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? activeColor : inactiveColor,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
