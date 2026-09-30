import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData, rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/webview_diag.dart';
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

/// 给内嵌 WebView 设底色。
///
/// ⚠️ **macOS 上必须整句跳过 —— 否则整个页面会变一片空白。**
///
/// `webview_flutter_wkwebview` 的 `WebKitWebViewController.setBackgroundColor`
/// 内部会调三个方法，而这三个在 `NSViewWKWebView`（也就是 macOS）分支里
/// **全是直接抛异常**（`lib/src/common/platform_webview.dart`）：
///
/// | 调用 | 行 | macOS 行为 |
/// |---|---|---|
/// | `setOpaque` | 386 | `throw UnimplementedError('opaque is not implemented on macOS')` |
/// | `setBackgroundColor` | 333 | `throw UnimplementedError('backgroundColor is not implemented on macOS')` |
/// | `scrollView` | 305 | `throw UnimplementedError('scrollView is not implemented on macOS')` |
///
/// 要命的是它**同步抛出**。而调用点一般写成 `initState` 里的级联
/// （`WebViewController()..setBackgroundColor(...)`），于是整个 `initState`
/// 抛异常 → 这一页构建失败 → 被替换成 release 版的**空白 ErrorWidget**：
/// 表现就是「网页一片空白、连一个字都没有」，与渲染器无关，屏幕上也没有任何提示。
/// 本项目 v3.0.17 ~ v3.0.19 连续三版都栽在这一句上。
///
/// 底色本身只是锦上添花（页面自带的 CSS 背景已经够用），跳过不影响显示。
void applyWebViewBackground(WebViewController controller, Color color) {
  if (Platform.isMacOS) return;
  try {
    controller.setBackgroundColor(color);
  } catch (e) {
    debugPrint('setBackgroundColor failed: $e');
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
    // await 是为了让「打不开浏览器」也走这里的 catch，返回 false 而不是抛出去
    return await openUrlExternally(Uri.file(file.path).toString());
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

/// 半透明圆形浮钮 —— 叠在网页上，低调不抢眼。
class WebViewFloatingButton extends StatelessWidget {
  const WebViewFloatingButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  /// 不传则跟随主题（深色主题＝黑底白图标，浅色主题＝白底深图标）。
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg =
        background ?? (isDark ? Colors.black : Colors.white).withValues(alpha: 0.5);
    final Color fg = foreground ?? (isDark ? Colors.white70 : Colors.black54);

    Widget button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: fg),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

/// 浮在网页之上的迷你控制条：**只要返回 + 重新加载**。
///
/// ## 为什么不用 `AppBar`
///
/// 网页页要的是「栏隐藏、网页占满整屏」，但 `AppBar` 这条路走不通：
///
/// - `AppBar` 必然占据一条栏（默认 `toolbarHeight` 56，压到 44 也仍有 44），
///   把网页整体往下推；
/// - 想「把栏压到极小」也不行 —— `toolbarHeight` 只要小于按钮高度，
///   `NavigationToolbar` 内部的 `CustomMultiChildLayout` 就会把按钮的
///   `maxHeight` 约束成 `toolbarHeight`，按钮会被**压扁成一条**
///   （试过 `toolbarHeight: 5`：按钮变成 36×5 的细条，比有栏还难看）。
///
/// 所以正解是**整个不要栏**：`Scaffold` 不给 `appBar`，网页铺满 body，
/// 再把按钮以浮层形式叠在网页上。栏高度 = 0，沉没成本归零。
class WebViewFloatingControls extends StatelessWidget {
  const WebViewFloatingControls({
    super.key,
    required this.onBack,
    this.pageTitle = '',
    this.onReload,
    this.onOpenExternally,
    this.targets = const <ExternalOpenTarget>[],
    this.background,
    this.foreground,
  });

  final VoidCallback onBack;
  final String pageTitle;

  /// 传 null 表示当前没有可刷新的网页（控件没建出来、或平台不支持）。
  final VoidCallback? onReload;

  /// 「用系统浏览器打开当前页」。为 null 时不显示这个按钮。
  final VoidCallback? onOpenExternally;

  /// 诊断入口用的「用系统浏览器打开」候选；为空则不显示诊断入口。
  final List<ExternalOpenTarget> targets;

  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          WebViewFloatingButton(
            icon: Icons.arrow_back_rounded,
            tooltip: '返回',
            onTap: onBack,
            background: background,
            foreground: foreground,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 平时完全不出现，只在网页出错时才顶出来 —— 不占视觉位置
              WebViewDiagButton(
                pageTitle: pageTitle,
                targets: targets,
                floating: true,
              ),
              if (onOpenExternally != null) ...[
                const SizedBox(width: 8),
                WebViewFloatingButton(
                  icon: Icons.open_in_new_rounded,
                  tooltip: '用系统浏览器打开',
                  onTap: onOpenExternally!,
                  background: background,
                  foreground: foreground,
                ),
              ],
              if (onReload != null) ...[
                const SizedBox(width: 8),
                WebViewFloatingButton(
                  icon: Icons.refresh_rounded,
                  tooltip: '重新加载',
                  onTap: onReload!,
                  background: background,
                  foreground: foreground,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// 网页显示不出来时的「诊断」入口。
///
/// 平时**完全不出现**；只有当 [WebViewDiag] 记到东西（平台视图创建失败、
/// 页面加载失败、或者迟迟收不到任何加载回调）时才顶出一个图标。
///
/// 存在的意义：这类失败在 Flutter 里是「静默」的 —— 页面只有一个空白的
/// `SizedBox.expand()`，既没有字也没有报错，用户和开发者都无从下手。
/// 点开之后能看到原始原因、一键复制，并且**可以立刻改用系统浏览器打开**，
/// 保证网页显示不出来时至少还有一条走得通的路。
class WebViewDiagButton extends StatelessWidget {
  final String pageTitle;

  /// 可用的打开入口，第一个会被当作「用系统浏览器打开」的按钮。
  final List<ExternalOpenTarget> targets;

  /// 以「浮在网页上的圆钮」形态出现（无栏页面用），而不是 `AppBar` 里的裸图标。
  final bool floating;

  const WebViewDiagButton({
    super.key,
    required this.pageTitle,
    this.targets = const <ExternalOpenTarget>[],
    this.floating = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: WebViewDiag.hasProblems,
      builder: (context, hasProblems, _) {
        if (!hasProblems) return const SizedBox.shrink();
        if (floating) {
          return WebViewFloatingButton(
            icon: Icons.error_outline,
            tooltip: '网页没显示出来？点这里看原因',
            foreground: const Color(0xFFB3261E),
            onTap: () => _showReport(context),
          );
        }
        return IconButton(
          tooltip: '网页没显示出来？点这里看原因',
          visualDensity: VisualDensity.compact,
          iconSize: 20,
          icon: const Icon(Icons.error_outline, color: Color(0xFFB3261E)),
          onPressed: () => _showReport(context),
        );
      },
    );
  }

  Future<void> _showReport(BuildContext context) async {
    final String report = WebViewDiag.report;
    final String path = WebViewDiag.filePath;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$pageTitle 没能显示出来'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '应用记录到的原始原因写在下面。如果看着是空白，可以直接改用系统浏览器打开。',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBgOf(dialogContext),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.dividerOf(dialogContext)),
                  ),
                  child: SingleChildScrollView(
                    reverse: true,
                    child: SelectableText(
                      report.isEmpty ? '（没有记录到内容）' : report,
                      style: const TextStyle(fontSize: 11, height: 1.45),
                    ),
                  ),
                ),
              ),
              if (path.isNotEmpty) ...[
                const SizedBox(height: 8),
                SelectableText(
                  '日志文件：$path',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: report));
              if (!dialogContext.mounted) return;
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(content: Text('已复制诊断信息')),
              );
            },
            child: const Text('复制'),
          ),
          if (targets.isNotEmpty)
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final bool ok = await targets.first.open();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok ? '已交给系统浏览器打开' : '没能打开，请检查系统默认浏览器设置',
                    ),
                  ),
                );
              },
              child: const Text('用系统浏览器打开'),
            ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
