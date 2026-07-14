import 'package:flutter/material.dart';

/// 情绪强度选择圆点
/// 根据强度级别显示不同大小的圆点
class IntensityDots extends StatelessWidget {
  final int intensity;   // 1-5
  final int maxIntensity; // 默认 5
  final Color? color;
  final double size;

  const IntensityDots({
    super.key,
    required this.intensity,
    this.maxIntensity = 5,
    this.color,
    this.size = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxIntensity, (index) {
        final isActive = index < intensity;
        return Container(
          margin: const EdgeInsets.only(right: 4),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? (color ?? const Color(0xFF7EC8B0))
                : const Color(0xFFE0E0E0),
          ),
        );
      }),
    );
  }
}

/// 情绪颜色圆点
class MoodColorDot extends StatelessWidget {
  final Color color;
  final double size;

  const MoodColorDot({
    super.key,
    required this.color,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
