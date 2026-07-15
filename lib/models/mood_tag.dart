/// 触发标签
/// 用户记录情绪时可选择哪些情境/事件触发了当前情绪
class MoodTag {
  final String label;
  final String emoji;
  final bool isCustom;

  const MoodTag({
    required this.label,
    required this.emoji,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'emoji': emoji,
      };

  factory MoodTag.fromJson(Map<String, dynamic> json) => MoodTag(
        label: json['label'] as String,
        emoji: json['emoji'] as String,
        isCustom: true,
      );
}

/// 预设标签列表
class MoodTags {
  static const List<MoodTag> presets = [
    MoodTag(label: '工作', emoji: '💼'),
    MoodTag(label: '学习', emoji: '📚'),
    MoodTag(label: '家庭', emoji: '🏠'),
    MoodTag(label: '朋友', emoji: '👫'),
    MoodTag(label: '恋爱', emoji: '❤️'),
    MoodTag(label: '健康', emoji: '💊'),
    MoodTag(label: '睡眠', emoji: '🛏️'),
    MoodTag(label: '运动', emoji: '🏃'),
    MoodTag(label: '美食', emoji: '🍜'),
    MoodTag(label: '天气', emoji: '🌤️'),
    MoodTag(label: '财务', emoji: '💰'),
    MoodTag(label: '社交', emoji: '🗣️'),
    MoodTag(label: '独处', emoji: '🧘'),
    MoodTag(label: '音乐', emoji: '🎵'),
    MoodTag(label: '旅行', emoji: '✈️'),
    MoodTag(label: '其他', emoji: '✨'),
  ];

  /// 可供自定义标签选择的 emoji 列表
  static const List<String> availableEmojis = [
    '💼', '📚', '🏠', '👫', '❤️', '💊', '🛏️', '🏃',
    '🍜', '🌤️', '💰', '🗣️', '🧘', '🎵', '✈️', '✨',
    '🐶', '🐱', '🌱', '☕', '🎮', '📺', '📱', '💻',
    '🎨', '📷', '✍️', '🎂', '🎉', '🎁', '🌧️', '🌈',
    '🚗', '⛰️', '🌊', '🌸', '🍂', '🔥', '⭐', '🌙',
    '💪', '🧠', '👀', '👂', '🤝', '💪', '🏋️', '🚶',
  ];

  /// 内存缓存的自定义标签
  static List<MoodTag> _customTags = [];

  /// 获取自定义标签
  static List<MoodTag> get customTags => _customTags;

  /// 所有标签（预设 + 自定义）
  static List<MoodTag> get allTags => [...presets, ..._customTags];

  /// 设置自定义标签缓存（在 app 启动时调用）
  static void setCustomTags(List<MoodTag> tags) {
    _customTags = tags;
  }

  /// 根据 label 获取 emoji（自动查找预设和自定义）
  static String? emojiFor(String label) {
    for (final tag in presets) {
      if (tag.label == label) return tag.emoji;
    }
    for (final tag in _customTags) {
      if (tag.label == label) return tag.emoji;
    }
    return null;
  }

  /// 检查 label 是否已存在（预设或自定义）
  static bool exists(String label) {
    return presets.any((t) => t.label == label) ||
        _customTags.any((t) => t.label == label);
  }
}
