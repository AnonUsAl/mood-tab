import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

/// 当前平台是否支持内嵌 WebView。
///
/// `webview_flutter` 只实现了 Android、iOS 和 macOS(wkwebview)，
/// 在 Windows / Linux 上创建 `WebViewController` 会直接抛异常，
/// 页面表现为白屏 —— 看起来就像「内容没显示出来」。
bool get isEmbeddedWebViewSupported {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

/// 用系统默认浏览器打开一个网络链接
Future<bool> openUrlExternally(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('openUrlExternally failed: $e');
    return false;
  }
}

/// 把打包在 assets 里的 HTML 释放到本地临时文件，再用系统浏览器打开。
/// 用于「关于作者」这类只依赖本地资源的离线页面。
///
/// Windows 上 url_launcher 会走 ShellExecuteW，`file:` 链接是被支持的。
Future<bool> openBundledAssetExternally(
  String assetKey, {
  String fileName = 'mood_tab_page.html',
}) async {
  try {
    final html = await rootBundle.loadString(assetKey);
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, fileName));
    await file.writeAsString(html);
    return openUrlExternally(Uri.file(file.path).toString());
  } catch (e) {
    debugPrint('openBundledAssetExternally failed: $e');
    return false;
  }
}

/// 一个可用系统浏览器打开的入口
class ExternalOpenTarget {
  final String label;
  final String description;
  final IconData icon;

  /// 打开网络链接
  final String? url;

  /// 打开打包资源（与 url 二选一）
  final String? assetKey;

  const ExternalOpenTarget({
    required this.label,
    required this.description,
    required this.icon,
    this.url,
    this.assetKey,
  });

  Future<bool> open() => assetKey != null
      ? openBundledAssetExternally(assetKey!)
      : openUrlExternally(url ?? '');
}

/// 内嵌 WebView 不可用平台上的落地页。
///
/// 移动端保持内嵌 WebView 的沉浸体验；Windows / Linux 上 webview_flutter
/// 没有任何实现，与其给用户一个白屏、或者一个还得再点一下的中间页，
/// 不如进入页面时就把内容交给系统默认浏览器。
///
/// 所以这里的行为是：**挂载后自动调起浏览器**，同时保留这个页面本身
/// 作为「没弹出来 / 想再打开一次」的兜底入口。
class ExternalBrowserFallback extends StatefulWidget {
  final String pageTitle;

  /// 可用的打开入口。第一个通常就是主入口。
  final List<ExternalOpenTarget> targets;

  /// 挂载后自动打开第几个入口。
  /// 传 null 表示不自动打开（由调用方自己控制时机，例如先弹版本选择）。
  ///
  /// 该值从 null 变为有效下标时，也会触发一次自动打开。
  final int? autoOpenIndex;

  final String message;

  const ExternalBrowserFallback({
    super.key,
    required this.pageTitle,
    required this.targets,
    this.autoOpenIndex,
    this.message = '桌面版无法内嵌网页，内容已交给系统浏览器显示。',
  });

  @override
  State<ExternalBrowserFallback> createState() =>
      _ExternalBrowserFallbackState();
}

class _ExternalBrowserFallbackState extends State<ExternalBrowserFallback> {
  bool _opening = false;

  /// null = 尚未尝试，true = 已交给浏览器，false = 打开失败
  bool? _opened;

  @override
  void initState() {
    super.initState();
    _maybeAutoOpen(widget.autoOpenIndex);
  }

  @override
  void didUpdateWidget(covariant ExternalBrowserFallback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoOpenIndex != null &&
        widget.autoOpenIndex != oldWidget.autoOpenIndex) {
      _maybeAutoOpen(widget.autoOpenIndex);
    }
  }

  void _maybeAutoOpen(int? index) {
    if (index == null) return;
    if (index < 0 || index >= widget.targets.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _open(widget.targets[index]);
    });
  }

  Future<void> _open(ExternalOpenTarget target) async {
    if (_opening) return;
    setState(() => _opening = true);
    final bool ok = await target.open();
    if (!mounted) return;
    setState(() {
      _opening = false;
      _opened = ok;
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('没能打开「${target.label}」，请检查系统默认浏览器设置'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              _opened == false
                  ? Icons.link_off_rounded
                  : Icons.open_in_new_rounded,
              size: 48,
              color: AppTheme.primaryColor.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 20),
            Text(
              widget.pageTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              _statusText(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _opened == false
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondaryOf(context),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textHintOf(context),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            for (final target in widget.targets) ...[
              _buildTargetTile(context, target),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  String _statusText() {
    if (_opening) return '正在调用系统浏览器…';
    return switch (_opened) {
      true => '已在系统浏览器中打开',
      false => '没能自动打开，请点击下面的入口重试',
      _ => '可用系统浏览器打开',
    };
  }

  Widget _buildTargetTile(BuildContext context, ExternalOpenTarget target) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _open(target),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardBgOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.dividerOf(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(target.icon, size: 20, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    target.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    target.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textHintOf(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new,
              size: 18,
              color: AppTheme.textHintOf(context),
            ),
          ],
        ),
      ),
    );
  }
}
