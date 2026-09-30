import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/webview_diag.dart';
import '../theme/app_theme.dart';
import '../widgets/webview_support.dart';

/// 关于团队页面 - WebView 套壳加载云术工作室官网
/// 沉浸式设计：透明 AppBar，浮动半透明按钮
/// Windows / Linux 上没有 WebView 实现，进页面直接调起系统浏览器
class TeamPage extends StatefulWidget {
  const TeamPage({super.key});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  static const _teamUrl = 'https://www.cldery.com/';

  static const List<ExternalOpenTarget> _externalTargets = [
    ExternalOpenTarget(
      label: '打开官网',
      description: 'www.cldery.com',
      icon: Icons.language,
      url: _teamUrl,
    ),
  ];

  WebViewController? _controller;
  bool _isLoading = true;
  WebViewWatchdog? _watch;

  @override
  void initState() {
    super.initState();
    _watch = WebViewDiag.watch('云术工作室');
    if (!isEmbeddedWebViewSupported) {
      WebViewDiag.record(
        '云术工作室',
        '当前平台 $defaultTargetPlatform 没有内嵌 WebView 实现，改走系统浏览器',
      );
      return;
    }
    try {
      final WebViewController controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (url) {
              _watch?.seen('onPageFinished url=$url');
              if (!mounted) return;
              setState(() {
                _isLoading = false;
              });
            },
            onWebResourceError: (error) {
              _watch?.failed(
                'onWebResourceError code=${error.errorCode} '
                'type=${error.errorType} url=${error.url} '
                'mainFrame=${error.isForMainFrame} desc=${error.description}',
              );
              if (!mounted) return;
              setState(() {
                _isLoading = false;
              });
              _notifyExternalFallback();
            },
          ),
        );
      // ⚠️ 必须走这个包装：setBackgroundColor 在 macOS 上会同步抛异常，
      // 直接写进级联会让整个 initState 抛、整页变空白（详见 webview_support.dart）
      applyWebViewBackground(controller, const Color(0xFFF8F6FF));
      controller.loadRequest(Uri.parse(_teamUrl));
      _controller = controller;
    } catch (e, stack) {
      // 建不出来就不留一页空白：记下原因，界面回落到系统浏览器兜底页
      WebViewDiag.problem('云术工作室', '创建网页控件失败：$e', stack: stack);
      _controller = null;
    }
  }

  @override
  void dispose() {
    _watch?.dispose();
    super.dispose();
  }

  /// 加载失败不再默默留一片空白，而是直接给一条走得通的路。
  void _notifyExternalFallback() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('网页没能加载出来'),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: '用浏览器打开',
          onPressed: () => openUrlExternally(_teamUrl),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: _buildFloatingButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          const WebViewDiagButton(
            pageTitle: '云术工作室',
            targets: _externalTargets,
          ),
          if (controller != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFloatingButton(
                icon: Icons.refresh_rounded,
                onTap: () {
                  setState(() => _isLoading = true);
                  controller.reload();
                },
              ),
            ),
        ],
      ),
      body: controller == null
          ? const Padding(
              // 透明 AppBar 覆盖在内容之上，这里留出顶部空间
              padding: EdgeInsets.only(top: 72),
              child: ExternalBrowserFallback(
                pageTitle: '云术工作室',
                autoOpenIndex: 0,
                message: '桌面版无法内嵌网页，已用系统浏览器打开官网。',
                targets: [
                  ExternalOpenTarget(
                    label: '打开官网',
                    description: 'www.cldery.com',
                    icon: Icons.language,
                    url: _teamUrl,
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // 平台视图要拿到确定尺寸才画得出来，Stack 里必须显式铺满
                Positioned.fill(child: WebViewWidget(controller: controller)),
                if (_isLoading)
                  Container(
                    color: AppTheme.scaffoldBgOf(context),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '正在打开云术工作室...',
                            style: TextStyle(
                              color: AppTheme.textSecondaryOf(context),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.5),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }
}
