import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/webview_diag.dart';
import '../theme/app_theme.dart';
import '../widgets/webview_support.dart';

/// MHOP 公益心理辅助平台 —— WebView 套壳加载 mhop.cldery.com
///
/// 结构与 [QisoulWebPage] 一致：**不给 `AppBar`**，按钮以浮层叠在网页上
/// （原因见 `webview_support.dart` 的 `WebViewFloatingControls` 文档）。
/// 网页本体外面套了 [WebViewSafeInset]，否则网页自己的固定顶栏会压住系统时间。
///
/// Windows / Linux 上没有内嵌 WebView 实现，进页面直接调起系统浏览器。
class MhopWebPage extends StatefulWidget {
  const MhopWebPage({super.key});

  @override
  State<MhopWebPage> createState() => _MhopWebPageState();
}

class _MhopWebPageState extends State<MhopWebPage> {
  static const _url = 'https://mhop.cldery.com/';
  static const _pageTitle = '公益心理辅助';

  static const List<ExternalOpenTarget> _externalTargets = [
    ExternalOpenTarget(
      label: '打开 MHOP',
      description: 'mhop.cldery.com',
      icon: Icons.handshake_outlined,
      url: _url,
    ),
  ];

  WebViewController? _controller;
  bool _isLoading = true;
  bool _canGoBack = false;
  WebViewWatchdog? _watch;

  @override
  void initState() {
    super.initState();
    _watch = WebViewDiag.watch(_pageTitle);
    if (!isEmbeddedWebViewSupported) {
      WebViewDiag.record(
        _pageTitle,
        '当前平台 $defaultTargetPlatform 没有内嵌 WebView 实现，改走系统浏览器',
      );
      return;
    }
    try {
      final WebViewController controller = WebViewController();
      controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      controller.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) async {
            _watch?.seen('onPageFinished url=$url');
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
            final canBack = await controller.canGoBack();
            if (mounted) {
              setState(() => _canGoBack = canBack);
            }
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
      controller.loadRequest(Uri.parse(_url));
      _controller = controller;
    } catch (e, stack) {
      // 建不出来就不留一页空白：记下原因，界面回落到系统浏览器兜底页
      WebViewDiag.problem(_pageTitle, '创建网页控件失败：$e', stack: stack);
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
          onPressed: () => openUrlExternally(_url),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      // ⚠️ 刻意**不给 appBar**：栏会白占一条高度把网页往下推，而想把它压小
      // 又会把按钮压扁（见 webview_support.dart 的 WebViewFloatingControls）。
      body: Stack(
        children: [
          // ⚠️ 必须包 WebViewSafeInset：Android 15+ 强制 edge-to-edge，
          // 少了它网页自己的固定顶栏会顶到 y=0、压住系统时间（详见 WebViewSafeInset）
          Positioned.fill(
            child: WebViewSafeInset(
              child: controller == null
                  ? const ExternalBrowserFallback(
                      pageTitle: _pageTitle,
                      autoOpenIndex: 0,
                      message: '桌面版无法内嵌网页，已用系统浏览器打开 MHOP。',
                      targets: _externalTargets,
                    )
                  : WebViewWidget(controller: controller),
            ),
          ),
          if (controller != null && _isLoading)
            Positioned.fill(
              child: Container(
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
                        '正在打开 MHOP...',
                        style: TextStyle(
                          color: AppTheme.textSecondaryOf(context),
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
                pageTitle: _pageTitle,
                targets: _externalTargets,
                onBack: () {
                  if (controller != null && _canGoBack) {
                    controller.goBack();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                onReload: controller == null
                    ? null
                    : () {
                        setState(() => _isLoading = true);
                        controller.reload();
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
