import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
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

  /// 桌面端用：版本选择完成后才置为 0/1，
  /// 该值变化会触发 [ExternalBrowserFallback] 自动调起浏览器。
  int? _browserAutoOpenIndex;

  @override
  void initState() {
    super.initState();
    if (isEmbeddedWebViewSupported) {
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
            onWebResourceError: (error) {
              if (!mounted) return;
              setState(() {
                _isLoading = false;
              });
            },
          ),
        );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showVersionChoice();
    });
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
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('心理测评'),
        titleTextStyle: Theme.of(context).textTheme.titleMedium,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          iconSize: 20,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (controller != null) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              iconSize: 20,
              onPressed: () {
                setState(() => _isLoading = true);
                controller.reload();
              },
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new),
              iconSize: 20,
              onPressed: () {
                controller.loadRequest(Uri.parse(_currentUrl));
              },
            ),
          ],
        ],
      ),
      body: controller == null
          ? ExternalBrowserFallback(
              pageTitle: '心理测评',
              autoOpenIndex: _browserAutoOpenIndex,
              message: '桌面版无法内嵌网页，已用系统浏览器打开所选版本。',
              targets: const [
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
              ],
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
              ],
            ),
    );
  }
}
