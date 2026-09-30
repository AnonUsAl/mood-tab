import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/webview_diag.dart';
import '../theme/app_theme.dart';
import '../widgets/webview_support.dart';

/// 心理测评页面 - WebView 套壳加载 pt.cldery.com
/// Windows / Linux 上没有 WebView 实现：仍然先让用户选版本，
/// 选完直接把对应网址交给系统浏览器
class AssessmentWebPage extends StatefulWidget {
  const AssessmentWebPage({super.key});

  @override
  State<AssessmentWebPage> createState() => _AssessmentWebPageState();
}

class _AssessmentWebPageState extends State<AssessmentWebPage> {
  static const _productionUrl = 'https://pt.cldery.com/';
  static const _previewUrl = 'https://pre-pt.cldery.com/';

  WebViewController? _controller;
  bool _isLoading = true;
  String _currentUrl = _productionUrl;
  WebViewWatchdog? _watch;

  /// 桌面端用：版本选择完成后才置为 0/1，
  /// 该值变化会触发 [ExternalBrowserFallback] 自动调起浏览器。
  int? _browserAutoOpenIndex;

  static const List<ExternalOpenTarget> _externalTargets = [
    ExternalOpenTarget(
      label: '正式版',
      description: 'pt.cldery.com',
      icon: Icons.assignment_turned_in_outlined,
      url: _productionUrl,
    ),
    ExternalOpenTarget(
      label: '预览版',
      description: 'pre-pt.cldery.com · 内容可能仍在调整中',
      icon: Icons.science_outlined,
      url: _previewUrl,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _watch = WebViewDiag.watch('心理测评');
    if (isEmbeddedWebViewSupported) {
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
        _controller = controller;
      } catch (e, stack) {
        // 建不出来就不留一页空白：记下原因，界面回落到系统浏览器兜底页
        WebViewDiag.problem('心理测评', '创建网页控件失败：$e', stack: stack);
        _controller = null;
      }
    } else {
      WebViewDiag.record(
        '心理测评',
        '当前平台 $defaultTargetPlatform 没有内嵌 WebView 实现，改走系统浏览器',
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showVersionChoice();
    });
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
          onPressed: () => openUrlExternally(_currentUrl),
        ),
      ),
    );
  }

  Future<void> _showVersionChoice() async {
    final usePreview = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('选择心理测评版本'),
        content: const Text('预览版用于体验新功能，内容可能仍在调整中。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('正式版'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('预览版'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    final bool preview = usePreview == true;
    setState(() {
      _currentUrl = preview ? _previewUrl : _productionUrl;
      _browserAutoOpenIndex = preview ? 1 : 0;
    });
    _loadCurrentUrl();
  }

  void _loadCurrentUrl() {
    // 桌面端没有内嵌 WebView，内容由系统浏览器承载
    if (_controller == null) return;
    setState(() => _isLoading = true);
    _controller!.loadRequest(Uri.parse(_currentUrl));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      // 不给 appBar：网页铺满整屏，按钮以浮层叠在上面（与栖所 / 关于作者统一）。
      body: Stack(
        children: [
          Positioned.fill(
            child: controller == null
                ? ExternalBrowserFallback(
                    pageTitle: '心理测评',
                    autoOpenIndex: _browserAutoOpenIndex,
                    message: '桌面版无法内嵌网页，已用系统浏览器打开所选版本。',
                    targets: _externalTargets,
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
                        '正在加载心理测评...',
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
          // 浮在网页上的控制条：返回 + 用系统浏览器打开 + 重新加载（无栏）
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: WebViewFloatingControls(
                pageTitle: '心理测评',
                targets: _externalTargets,
                onBack: () => Navigator.of(context).pop(),
                onReload: controller == null
                    ? null
                    : () {
                        setState(() => _isLoading = true);
                        controller.reload();
                      },
                onOpenExternally: controller == null
                    ? null
                    : () => openUrlExternally(_currentUrl),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
