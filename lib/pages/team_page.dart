import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
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

  WebViewController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (!isEmbeddedWebViewSupported) return;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF8F6FF))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(_teamUrl));
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
                WebViewWidget(controller: controller),
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
