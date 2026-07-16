/// 自伤冲动监测日志数据模型
///
/// 这是一个自我觉察工具（借鉴 DBT 日记卡思路），用于帮助记录者
/// 觉察冲动出现的规律、诱因与自己用过的应对方式，从而更了解自己。
/// 它不记录、也不引导任何伤害行为。每一条记录都鼓励优先寻求支持。
class UrgeLog {
  final int? id;

  /// 事件名称（给这次记录起个名字，便于回顾）
  final String? title;

  /// 冲动强度 1-5
  final int intensity;

  /// 冲动是否演变为行为（用于自我觉察，非评判）
  final bool actedOn;

  /// 诱因（触发当下情绪的事件/想法）
  final String? trigger;

  /// 用过的应对方式（如：深呼吸、联系朋友、离开现场）
  final String? copingUsed;

  /// 补充备注
  final String? note;

  /// 关联图片的本地路径（复制进 app 文档目录后保存，绝不上传云端）
  final String? imagePath;

  /// 记录时间
  final DateTime createdAt;

  UrgeLog({
    this.id,
    this.title,
    required this.intensity,
    required this.actedOn,
    this.trigger,
    this.copingUsed,
    this.note,
    this.imagePath,
    required this.createdAt,
  });

  /// 从数据库 Map 构造
  factory UrgeLog.fromMap(Map<String, dynamic> map) {
    return UrgeLog(
      id: map['id'] as int?,
      title: map['title'] as String?,
      intensity: map['intensity'] as int? ?? 1,
      actedOn: (map['acted_on'] as int? ?? 0) == 1,
      trigger: map['trigger'] as String?,
      copingUsed: map['coping_used'] as String?,
      note: map['note'] as String?,
      imagePath: map['image_path'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// 转为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'intensity': intensity,
      'acted_on': actedOn ? 1 : 0,
      'trigger': trigger,
      'coping_used': copingUsed,
      'note': note,
      'image_path': imagePath,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  UrgeLog copyWith({
    int? id,
    String? title,
    int? intensity,
    bool? actedOn,
    String? trigger,
    String? copingUsed,
    String? note,
    String? imagePath,
    DateTime? createdAt,
  }) {
    return UrgeLog(
      id: id ?? this.id,
      title: title ?? this.title,
      intensity: intensity ?? this.intensity,
      actedOn: actedOn ?? this.actedOn,
      trigger: trigger ?? this.trigger,
      copingUsed: copingUsed ?? this.copingUsed,
      note: note ?? this.note,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
