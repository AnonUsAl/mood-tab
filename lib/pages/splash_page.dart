import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 启动加载页
/// 在 app 初始化期间显示暖心 emoji 和随机暖心语句
class SplashPage extends StatefulWidget {
  final VoidCallback? onAnimationEnd;

  const SplashPage({super.key, this.onAnimationEnd});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  static const List<String> _warmMessages = [
    '今天也是值得记录的一天',
    '你的感受很重要，无论好坏',
    '慢慢来，比较快',
    '你比想象中更坚强',
    '每一个情绪都值得被看见',
    '深呼吸，一切都会好起来的',
    '记录此刻，拥抱自己',
    '你不需要完美，只需要真实',
    '今天辛苦了，你已经很棒了',
    '允许自己有不开心的时候',
    '难过也是生活的一部分',
    '你值得被温柔对待',
    '小小的进步也是进步',
    '照顾好自己，从记录开始',
    '情绪没有对错，只有真实',
  ];

  late final String _message;

  @override
  void initState() {
    super.initState();
    _message = _warmMessages[DateTime.now().millisecond % _warmMessages.length];

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _scaleController.forward();

    // 动画结束后通知回调
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted && widget.onAnimationEnd != null) {
        widget.onAnimationEnd!();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkScaffoldBg : AppTheme.scaffoldBg;
    final subColor =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // emoji 带弹性动画
              ScaleTransition(
                scale: _scaleAnimation,
                child: const Text(
                  '🌿',
                  style: TextStyle(fontSize: 72),
                ),
              ),
              const SizedBox(height: 24),
              // app 名称
              const Text(
                'mood-tab',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              // 暖心语句
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: subColor,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // 加载指示器
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.primaryColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
