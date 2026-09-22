import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../widgets/webview_support.dart';

/// 关于作者页面 - WebView 加载本地 HTML（终端风格个人主页）
/// Windows / Linux 上没有 WebView 实现，进页面直接调起系统浏览器
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  WebViewController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (!isEmbeddedWebViewSupported) return;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0A0D12))
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
      ..loadFlutterAsset('assets/about.html');
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(
        title: const Text('关于作者'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (controller != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                controller.reload();
              },
            ),
        ],
      ),
      body: controller == null
          ? const ExternalBrowserFallback(
              pageTitle: '关于作者',
              autoOpenIndex: 0,
              message: '桌面版无法内嵌网页，已用系统浏览器打开作者主页（本地离线页面）。',
              targets: [
                ExternalOpenTarget(
                  label: '在浏览器中打开',
                  description: '作者主页（本地离线页面）',
                  icon: Icons.person_outline,
                  assetKey: 'assets/about.html',
                ),
              ],
            )
          : Stack(
              children: [
                WebViewWidget(controller: controller),
                if (_isLoading)
                  Container(
                    color: const Color(0xFF0A0D12),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Color(0xFF8BE9C1),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            '正在加载...',
                            style: TextStyle(
                              color: Color(0xFF5C6B7A),
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
}
