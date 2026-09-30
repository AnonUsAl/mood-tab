import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/webview_diag.dart';
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

  static const List<ExternalOpenTarget> _externalTargets = [
    ExternalOpenTarget(
      label: '进入栖所',
      description: 'qisoul.cldery.com',
      icon: Icons.nightlight_outlined,
      url: _qisoulUrl,
    ),
  ];

  WebViewController? _controller;
  bool _isLoading = true;
  bool _canGoBack = false;
  WebViewWatchdog? _watch;

  @override
  void initState() {
    super.initState();
    _watch = WebViewDiag.watch('栖所');
    if (!isEmbeddedWebViewSupported) {
      WebViewDiag.record(
        '栖所',
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
      controller.loadRequest(Uri.parse(_qisoulUrl));
      _controller = controller;
    } catch (e, stack) {
      // 建不出来就不留一页空白：记下原因，界面回落到系统浏览器兜底页
      WebViewDiag.problem('栖所', '创建网页控件失败：$e', stack: stack);
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
          onPressed: () => openUrlExternally(_qisoulUrl),
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
      // 改成把按钮以浮层形式叠在网页上 —— 栏高度 0，网页占满整屏。
      body: Stack(
        children: [
          Positioned.fill(
            child: controller == null
                ? const ExternalBrowserFallback(
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
                  )
                : WebViewWidget(controller: controller),
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
            ),
          // 浮在网页上的控制条：只有返回 + 重新加载
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: WebViewFloatingControls(
                pageTitle: '栖所',
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
