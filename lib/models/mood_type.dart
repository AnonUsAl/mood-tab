/// 情绪类型枚举
/// 定义应用支持的所有情绪类型，每种情绪关联颜色、emoji 和描述
enum MoodType {
  happy,        // 开心
  calm,         // 平静
  grateful,     // 感恩
  excited,      // 兴奋
  neutral,      // 一般
  tired,        // 疲惫
  sad,          // 难过
  anxious,      // 焦虑
  angry,        // 愤怒
  lonely,       // 孤独
}

extension MoodTypeExtension on MoodType {
  /// 情绪中文名称
  String get label {
    switch (this) {
      case MoodType.happy:
        return '开心';
      case MoodType.calm:
        return '平静';
      case MoodType.grateful:
        return '感恩';
      case MoodType.excited:
        return '兴奋';
      case MoodType.neutral:
        return '一般';
      case MoodType.tired:
        return '疲惫';
      case MoodType.sad:
        return '难过';
      case MoodType.anxious:
        return '焦虑';
      case MoodType.angry:
        return '愤怒';
      case MoodType.lonely:
        return '孤独';
    }
  }

  /// 情绪 emoji 表情
  String get emoji {
    switch (this) {
      case MoodType.happy:
        return '😊';
      case MoodType.calm:
        return '😌';
      case MoodType.grateful:
        return '🙏';
      case MoodType.excited:
        return '🤩';
      case MoodType.neutral:
        return '😐';
      case MoodType.tired:
        return '😴';
      case MoodType.sad:
        return '😢';
      case MoodType.anxious:
        return '😰';
      case MoodType.angry:
        return '😠';
      case MoodType.lonely:
        return '🥺';
    }
  }

  /// 情绪对应的颜色值（0xAARRGGBB）
  int get colorValue {
    switch (this) {
      case MoodType.happy:
        return 0xFFFFB74D;   // 暖橙
      case MoodType.calm:
        return 0xFF81C7E4;   // 天蓝
      case MoodType.grateful:
        return 0xFFA5D6A7;   // 薄荷绿
      case MoodType.excited:
        return 0xFFFF8A65;   // 珊瑚橙
      case MoodType.neutral:
        return 0xFFB0BEC5;   // 灰蓝
      case MoodType.tired:
        return 0xFF9575CD;   // 淡紫
      case MoodType.sad:
        return 0xFF64B5F6;   // 浅蓝
      case MoodType.anxious:
        return 0xFFE57373;   // 柔红
      case MoodType.angry:
        return 0xFFEF5350;   // 红
      case MoodType.lonely:
        return 0xFF78909C;   // 蓝灰
    }
  }

  /// 从数据库存储的索引值还原为 MoodType
  static MoodType fromIndex(int index) {
    if (index >= 0 && index < MoodType.values.length) {
      return MoodType.values[index];
    }
    return MoodType.neutral;
  }
}
