import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 桌面端窗口尺寸兜底。
///
/// 两条原则：
///
/// 1. **窗口可以随意缩放，横向拉大时内容跟着一起变宽** —— 不对内容宽度设上限，
///    窗口有多宽界面就铺多宽，不做「固定宽度居中画布」那套。
/// 2. **窗口缩得比内容最小逻辑尺寸还小时，不继续压缩内容** —— 内容保持最小尺寸
///    并改为可滚动。这样窗口能缩到任意小，排版也不会溢出或被裁掉。
///
/// 也就是说这里只兜底「太小」，不管「太大」。
class DesktopViewport extends StatefulWidget {
  /// 内容可用的最小逻辑尺寸。窗口比这更小时不再压缩内容，改为滚动。
  ///
  /// 窗口本身没有任何尺寸限制，这两条只作用于内容。
  static const double minContentWidth = 320;
  static const double minContentHeight = 480;

  /// 是否需要处理尺寸的平台：桌面端 true，移动端 / Web false
  static bool get isDesktopPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  final Widget child;

  const DesktopViewport({super.key, required this.child});

  @override
  State<DesktopViewport> createState() => _DesktopViewportState();
}

class _DesktopViewportState extends State<DesktopViewport> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = widget.child;
    if (!DesktopViewport.isDesktopPlatform) return child;

    final media = MediaQuery.of(context);
    final double windowWidth = media.size.width;
    final double windowHeight = media.size.height;

    final bool tooNarrow = windowWidth < DesktopViewport.minContentWidth;
    final bool tooShort = windowHeight < DesktopViewport.minContentHeight;

    // 常态：窗口宽高都够用，内容直接用窗口尺寸 —— 一层都不多套，
    // 横向拉大窗口内容就跟着变宽。
    if (!tooNarrow && !tooShort) return child;

    // 只有在某个方向上窗口已经小于内容最小尺寸时才介入：
    // 该方向锁在最小尺寸，交给滚动容器。
    final double contentWidth = tooNarrow
        ? DesktopViewport.minContentWidth
        : windowWidth;
    final double contentHeight = tooShort
        ? DesktopViewport.minContentHeight
        : windowHeight;

    Widget body = SizedBox(
      width: contentWidth,
      height: contentHeight,
      child: MediaQuery(
        // 让内容内部的尺寸以内容区为准，这样弹窗、底部弹层、
        // 日期选择器等也会跟着按内容区计算
        data: media.copyWith(
          size: Size(contentWidth, contentHeight),
          padding: EdgeInsets.zero,
          viewPadding: EdgeInsets.zero,
          viewInsets: EdgeInsets.zero,
        ),
        child: child,
      ),
    );

    // 纵向在外、横向在内：内容在两个方向上都只会「大于等于」窗口，
    // 所以不需要额外居中，缺哪个方向就补哪一层滚动。
    if (tooNarrow) {
      body = Scrollbar(
        controller: _horizontalController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          child: body,
        ),
      );
    }
    if (tooShort) {
      body = Scrollbar(
        controller: _verticalController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _verticalController,
          child: body,
        ),
      );
    }
    return body;
  }
}
