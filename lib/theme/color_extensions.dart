import 'package:flutter/material.dart';

extension ColorExtensions on Color {
  Color withValues({
    double? alpha,
    int? red,
    int? green,
    int? blue,
  }) {
    final int a;
    if (alpha != null) {
      a = (alpha.clamp(0.0, 1.0) * 255).round();
    } else {
      a = (this.a * 255.0).round().clamp(0, 255);
    }

    return Color.fromARGB(
      a,
      red ?? (this.r * 255.0).round().clamp(0, 255),
      green ?? (this.g * 255.0).round().clamp(0, 255),
      blue ?? (this.b * 255.0).round().clamp(0, 255),
    );
  }
}