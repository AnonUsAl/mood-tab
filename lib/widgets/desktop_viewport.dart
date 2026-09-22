import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 桌面画布 —— 让桌面端（Windows / Linux / macOS）保持移动端排版
///
/// 本项目的界面是按手机竖屏设计的。桌面窗口通常又宽又扁，
/// 如果让界面直接铺满窗口，就会出现「卡片被横向摊开、元素错位、
/// 底部内容被裁切」等排版问题。
///
/// 处理方式：窗口仍然可以自由缩放，但当窗口宽度超过手机宽度时，
/// 把整个 App 限制在一张固定宽度的「画布」里并水平居中，
/// 画布之外的区域填充一层更深的底色。这样界面在任何窗口尺寸下
/// 都与移动端保持一致。
class DesktopViewport extends StatelessWidget {
  /// 画布宽度（贴近主流手机的逻辑宽度）
  static const double canvasWidth = 480;

  /// 窗口宽度超过这个值才需要加画布（否则窗口本身已经够窄）
  static const double _canvasThreshold = canvasWidth + 16;

  /// 是否需要限制画布的平台：桌面端 true，移动端 / Web false
  static bool get isDesktopPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  final Widget child;

  const DesktopViewport({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!isDesktopPlatform) return child;

    final media = MediaQuery.of(context);
    if (media.size.width <= _canvasThreshold) return child;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 画布外的底色：比 App 背景稍深，让画布有「一张纸」的层次感
    final canvasOuterBg =
        isDark ? const Color(0xFF111119) : const Color(0xFFE9E7E2);

    return ColoredBox(
      color: canvasOuterBg,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: canvasWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            // SizedBox.expand：把画布撑满可用高度，同时宽度锁死在 canvasWidth
            child: SizedBox.expand(
              child: MediaQuery(
                // 让画布内部的尺寸以画布为准，这样弹窗、底部弹层、
                // 日期选择器等也会正确地限制在手机宽度内
                data: media.copyWith(
                  size: Size(canvasWidth, media.size.height),
                  padding: EdgeInsets.zero,
                  viewPadding: EdgeInsets.zero,
                  viewInsets: EdgeInsets.zero,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
