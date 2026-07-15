import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tab/models/mood_record.dart';
import 'package:mood_tab/models/mood_type.dart';

void main() {
  test('MoodRecord can round-trip through its database map', () {
    final createdAt = DateTime(2026, 7, 15, 9, 30);
    final record = MoodRecord(
      id: 1,
      moodType: MoodType.calm,
      intensity: 4,
      note: '状态不错',
      tags: const ['工作', '睡眠'],
      diary: '今天比较平静。',
      createdAt: createdAt,
    );

    final restored = MoodRecord.fromMap(record.toMap());

    expect(restored.id, 1);
    expect(restored.moodType, MoodType.calm);
    expect(restored.intensity, 4);
    expect(restored.note, '状态不错');
    expect(restored.tags, ['工作', '睡眠']);
    expect(restored.diary, '今天比较平静。');
    expect(restored.createdAt, createdAt);
  });
}
