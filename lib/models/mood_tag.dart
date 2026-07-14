/// 触发标签预设
/// 用户记录情绪时可选择哪些情境/事件触发了当前情绪
class MoodTag {
  final String label;
  final String emoji;

  const MoodTag({required this.label, required this.emoji});
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

  /// 根据 label 获取 emoji
  static String? emojiFor(String label) {
    for (final tag in presets) {
      if (tag.label == label) return tag.emoji;
    }
    return null;
  }
}
