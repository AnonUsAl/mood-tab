import 'mood_type.dart';

/// 情绪记录数据模型
/// 对应数据库中的一条情绪记录
class MoodRecord {
  final int? id;
  final MoodType moodType;
  final int intensity; // 情绪强度 1-5
  final String? note; // 短文字备注
  final List<String> tags; // 触发标签
  final String? diary; // 长文本日记（v2 新增）
  final DateTime createdAt; // 创建时间

  MoodRecord({
    this.id,
    required this.moodType,
    required this.intensity,
    this.note,
    required this.tags,
    this.diary,
    required this.createdAt,
  });

  /// 从数据库 Map 构造 MoodRecord
  factory MoodRecord.fromMap(Map<String, dynamic> map) {
    return MoodRecord(
      id: map['id'] as int?,
      moodType: MoodTypeExtension.fromIndex(map['mood_type'] as int),
      intensity: map['intensity'] as int,
      note: map['note'] as String?,
      tags:
          (map['tags'] as String?) != null && (map['tags'] as String).isNotEmpty
              ? (map['tags'] as String).split(',')
              : [],
      diary: map['diary'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// 转为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mood_type': moodType.index,
      'intensity': intensity,
      'note': note,
      'tags': tags.join(','),
      'diary': diary,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// 创建副本，可覆盖部分字段
  MoodRecord copyWith({
    int? id,
    MoodType? moodType,
    int? intensity,
    String? note,
    List<String>? tags,
    String? diary,
    DateTime? createdAt,
  }) {
    return MoodRecord(
      id: id ?? this.id,
      moodType: moodType ?? this.moodType,
      intensity: intensity ?? this.intensity,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      diary: diary ?? this.diary,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
