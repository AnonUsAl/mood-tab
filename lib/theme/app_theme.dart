import 'package:flutter/material.dart';

/// 单组主题色方案
class ThemeColorScheme {
  final String name;
  final String label;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color accent;

  const ThemeColorScheme({
    required this.name,
    required this.label,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.accent,
  });
}

/// 应用主题配置
/// 治愈系风格：柔和配色、圆角卡片、温和视觉
class AppTheme {
  AppTheme._();

  // ==================== 主题色方案列表 ====================

  static const List<ThemeColorScheme> colorSchemes = [
    ThemeColorScheme(
      name: 'mint',
      label: '薄荷绿',
      primary: Color(0xFF7EC8B0),
      primaryLight: Color(0xFFB5E5D6),
      primaryDark: Color(0xFF4A9B82),
      accent: Color(0xFFFFB74D),
    ),
    ThemeColorScheme(
      name: 'lavender',
      label: '薰衣草紫',
      primary: Color(0xFF9575CD),
      primaryLight: Color(0xFFD1C4E9),
      primaryDark: Color(0xFF5E35B1),
      accent: Color(0xFFFFB74D),
    ),
    ThemeColorScheme(
      name: 'rose',
      label: '玫瑰粉',
      primary: Color(0xFFE8A0BF),
      primaryLight: Color(0xFFF8C8DC),
      primaryDark: Color(0xFFD46A95),
      accent: Color(0xFFFFB74D),
    ),
    ThemeColorScheme(
      name: 'ocean',
      label: '海洋蓝',
      primary: Color(0xFF5C9EAD),
      primaryLight: Color(0xFFA0CED9),
      primaryDark: Color(0xFF3A7B8A),
      accent: Color(0xFFFFB74D),
    ),
    ThemeColorScheme(
      name: 'sunset',
      label: '日落橙',
      primary: Color(0xFFF2A65A),
      primaryLight: Color(0xFFF8C892),
      primaryDark: Color(0xFFD4842F),
      accent: Color(0xFF7EC8B0),
    ),
    ThemeColorScheme(
      name: 'forest',
      label: '森林青',
      primary: Color(0xFF6B8E5A),
      primaryLight: Color(0xFFA8C49C),
      primaryDark: Color(0xFF4A6B3E),
      accent: Color(0xFFFFB74D),
    ),
  ];

  // ==================== 默认主题色（薄荷绿，向后兼容）====================

  static const Color primaryColor = Color(0xFF7EC8B0);
  static const Color primaryLight = Color(0xFFB5E5D6);
  static const Color primaryDark = Color(0xFF4A9B82);
  static const Color accentColor = Color(0xFFFFB74D);

  /// 背景色 - 温暖的米白
  static const Color scaffoldBg = Color(0xFFFAF9F6);
  static const Color cardBg = Color(0xFFFFFFFF);

  /// 文字色
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textHint = Color(0xFFB2BEC3);

  /// 情绪强度渐变色 (1=最淡, 5=最深)
  static const List<Color> intensityColors = [
    Color(0xFFE8F5E9), // 1 - 最淡
    Color(0xFFC8E6C9), // 2
    Color(0xFFA5D6A7), // 3
    Color(0xFF81C784), // 4
    Color(0xFF66BB6A), // 5 - 最深
  ];

  // ==================== 暗色主题常量 ====================

  /// 暗色背景
  static const Color darkScaffoldBg = Color(0xFF1A1A2E);
  static const Color darkCardBg = Color(0xFF252537);
  static const Color darkTextPrimary = Color(0xFFE8E8E8);
  static const Color darkTextSecondary = Color(0xFFA0A0B0);
  static const Color darkTextHint = Color(0xFF6C6C80);

  // ==================== 当前主题色索引（由 main.dart 在 build 前设置）====================

  static int _colorIndex = 0;

  static int get colorIndex => _colorIndex;

  static void setColorIndex(int index) {
    if (index >= 0 && index < colorSchemes.length) {
      _colorIndex = index;
    }
  }

  static ThemeColorScheme get currentScheme => colorSchemes[_colorIndex];

  // ==================== Context 感知主题色 ====================

  /// 当前主题主色
  static Color primaryColorOf(BuildContext context) {
    return currentScheme.primary;
  }

  static Color primaryLightOf(BuildContext context) =>
      currentScheme.primaryLight;
  static Color primaryDarkOf(BuildContext context) => currentScheme.primaryDark;
  static Color accentOf(BuildContext context) => currentScheme.accent;

  // ==================== 亮色 / 暗色主题 ====================

  static ThemeData get lightTheme {
    final s = currentScheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: s.primary,
        primary: s.primary,
        secondary: s.accent,
        surface: cardBg,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: scaffoldBg,
      fontFamily: null, // 使用系统默认字体

      // AppBar
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: scaffoldBg,
        foregroundColor: textPrimary,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),

      // 卡片
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),

      // 输入框
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: s.primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textHint, fontSize: 14),
      ),

      // 按钮
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: s.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // 底部导航
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardBg,
        selectedItemColor: s.primary,
        unselectedItemColor: textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // 文字
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary),
        headlineMedium: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: textPrimary),
        bodySmall: TextStyle(fontSize: 12, color: textSecondary),
        labelLarge: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
      ),
    );
  }

  static ThemeData get darkTheme {
    final s = currentScheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: s.primary,
        primary: s.primary,
        secondary: s.accent,
        surface: darkCardBg,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: darkScaffoldBg,
      fontFamily: null,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: darkScaffoldBg,
        foregroundColor: darkTextPrimary,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2D2D3F),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: s.primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: darkTextHint, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: s.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkCardBg,
        selectedItemColor: s.primary,
        unselectedItemColor: darkTextHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 28, fontWeight: FontWeight.bold, color: darkTextPrimary),
        headlineMedium: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w600, color: darkTextPrimary),
        titleLarge: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: darkTextPrimary),
        titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, color: darkTextPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: darkTextPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: darkTextPrimary),
        bodySmall: TextStyle(fontSize: 12, color: darkTextSecondary),
        labelLarge: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: darkTextPrimary),
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: darkCardBg,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: const Color(0xFF3D3D50),
    );
  }

  // ==================== Context 感知颜色 ====================
  // 根据当前主题亮度自动返回对应颜色，解决暗色模式下硬编码浅色问题

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color scaffoldBgOf(BuildContext context) =>
      _isDark(context) ? darkScaffoldBg : scaffoldBg;

  static Color cardBgOf(BuildContext context) =>
      _isDark(context) ? darkCardBg : cardBg;

  static Color textPrimaryOf(BuildContext context) =>
      _isDark(context) ? darkTextPrimary : textPrimary;

  static Color textSecondaryOf(BuildContext context) =>
      _isDark(context) ? darkTextSecondary : textSecondary;

  static Color textHintOf(BuildContext context) =>
      _isDark(context) ? darkTextHint : textHint;

  /// 分隔线颜色
  static Color dividerOf(BuildContext context) =>
      _isDark(context) ? const Color(0xFF3D3D50) : const Color(0xFFE8E8E8);

  /// 输入框填充色
  static Color inputFillOf(BuildContext context) =>
      _isDark(context) ? const Color(0xFF2D2D3F) : const Color(0xFFF5F5F5);
}
