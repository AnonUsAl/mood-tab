import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/webview_diag.dart';
import '../widgets/webview_support.dart';

/// 关于作者页面 - WebView 加载作者主页（终端风格个人主页）
/// Windows / Linux 上没有 WebView 实现，进页面直接调起系统浏览器
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  /// 作者主页（在线）。
  ///
  /// 2026-09-30 由「打包进 app 的本地 `assets/about.html`」改为在线地址：
  /// 页面内容更新不必再发版；同时绕开了 macOS 上 `loadFlutterAsset` 找不到
  /// `flutter_assets` 的老问题（上游 flutter/flutter#162938，详见 webview_support.dart）。
  static const String _url = 'https://anonusal.cldery.com/';

  static const List<ExternalOpenTarget> _externalTargets = [
    ExternalOpenTarget(
      label: '在浏览器中打开',
      description: 'anonusal.cldery.com',
      icon: Icons.person_outline,
      url: _url,
    ),
  ];

  WebViewController? _controller;
  bool _isLoading = true;
  WebViewWatchdog? _watch;

  @override
  void initState() {
    super.initState();
    _watch = WebViewDiag.watch('关于作者');
    if (!isEmbeddedWebViewSupported) {
      WebViewDiag.record(
        '关于作者',
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
      applyWebViewBackground(controller, const Color(0xFF0A0D12));
      _controller = controller;
      _load();
    } catch (e, stack) {
      // 建不出来就不留一页空白：记下原因，界面回落到系统浏览器兜底页
      WebViewDiag.problem('关于作者', '创建网页控件失败：$e', stack: stack);
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
        content: const Text('作者主页没能加载出来'),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: '用浏览器打开',
          onPressed: () => openUrlExternally(_url),
        ),
      ),
    );
  }

  /// 加载作者主页。
  ///
  /// 改成在线地址后这里就只是 `loadRequest` —— 原先那套「macOS 上把本地 HTML
  /// 落到临时文件再 `loadFile`」的绕法随本地资产一起退役了。
  Future<void> _load() async {
    final controller = _controller;
    if (controller == null) return;
    await controller.loadRequest(Uri.parse(_url));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      // 不给 appBar：网页铺满整屏，按钮以浮层叠在上面（与栖所统一）。
      body: Stack(
        children: [
          Positioned.fill(
            child: controller == null
                ? const ExternalBrowserFallback(
                    pageTitle: '关于作者',
                    autoOpenIndex: 0,
                    message: '桌面版无法内嵌网页，已用系统浏览器打开作者主页。',
                    targets: _externalTargets,
                  )
                : WebViewWidget(controller: controller),
          ),
          if (controller != null && _isLoading)
            Positioned.fill(
              child: Container(
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
            ),
          // 浮在网页上的控制条：只有返回 + 重新加载
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: WebViewFloatingControls(
                pageTitle: '关于作者',
                targets: _externalTargets,
                onBack: () => Navigator.of(context).pop(),
                onReload: controller == null
                    ? null
                    : () {
                        setState(() => _isLoading = true);
                        _load();
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
