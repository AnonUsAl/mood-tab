import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/webview_support.dart';

/// 栖所页面 - WebView 套壳加载 qisoul.cldery.com
/// 沉浸式设计：透明 AppBar，浮动半透明按钮，让网页内容占主导
/// Windows / Linux 上没有 WebView 实现，进页面直接调起系统浏览器
class QisoulWebPage extends StatefulWidget {
  const QisoulWebPage({super.key});

  @override
  State<QisoulWebPage> createState() => _QisoulWebPageState();
}

class _QisoulWebPageState extends State<QisoulWebPage> {
  static const _qisoulUrl = 'https://qisoul.cldery.com/';

  WebViewController? _controller;
  bool _isLoading = true;
  bool _canGoBack = false;

  @override
  void initState() {
    super.initState();
    if (!isEmbeddedWebViewSupported) return;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF8F6FF))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
            final canBack = await _controller!.canGoBack();
            if (mounted) {
              setState(() => _canGoBack = canBack);
            }
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(_qisoulUrl));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: _buildFloatingButton(
            icon: Icons.arrow_back_rounded,
            onTap: () {
              if (controller != null && _canGoBack) {
                controller.goBack();
              } else {
                Navigator.of(context).pop();
              }
            },
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
              padding: EdgeInsets.only(top: 64),
              child: ExternalBrowserFallback(
                pageTitle: '栖所',
                autoOpenIndex: 0,
                message: '桌面版无法内嵌网页，已用系统浏览器打开栖所。',
                targets: [
                  ExternalOpenTarget(
                    label: '进入栖所',
                    description: 'qisoul.cldery.com',
                    icon: Icons.nightlight_outlined,
                    url: _qisoulUrl,
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
                            '正在进入栖所...',
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

  /// 半透明浮动圆形按钮 — 低调不抢眼
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
