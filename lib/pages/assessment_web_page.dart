import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_theme.dart';

/// 心理测评页面 - WebView 套壳加载 pt.cldery.com
class AssessmentWebPage extends StatefulWidget {
  const AssessmentWebPage({super.key});

  @override
  State<AssessmentWebPage> createState() => _AssessmentWebPageState();
}

class _AssessmentWebPageState extends State<AssessmentWebPage> {
  static const _productionUrl = 'https://pt.cldery.com/';
  static const _previewUrl = 'https://pre-pt.cldery.com/';

  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentUrl = _productionUrl;

  @override
  void initState() {
    super.initState();
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
    _currentUrl = usePreview == true ? _previewUrl : _productionUrl;
    _loadCurrentUrl();
  }

  void _loadCurrentUrl() {
    setState(() => _isLoading = true);
    _controller.loadRequest(Uri.parse(_currentUrl));
  }

  @override
  Widget build(BuildContext context) {
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
          IconButton(
            icon: const Icon(Icons.refresh),
            iconSize: 20,
            onPressed: () {
              setState(() => _isLoading = true);
              _controller.reload();
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            iconSize: 20,
            onPressed: () {
              _controller.loadRequest(Uri.parse(_currentUrl));
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
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
