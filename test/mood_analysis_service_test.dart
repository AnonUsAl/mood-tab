import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tab/models/mood_record.dart';
import 'package:mood_tab/models/mood_type.dart';
import 'package:mood_tab/services/mood_analysis_service.dart';

MoodRecord record({
  required MoodType mood,
  required int intensity,
  required DateTime createdAt,
}) {
  return MoodRecord(
    moodType: mood,
    intensity: intensity,
    tags: const [],
    createdAt: createdAt,
  );
}

void main() {
  final service = MoodAnalysisService();

  test('returns an empty result when there are no records', () {
    final result = service.analyze(const []);

    expect(result.hasEnoughData, isFalse);
    expect(result.hasWarning, isFalse);
    expect(result.recentRecordCount, 0);
    expect(result.cyclePatterns, isEmpty);
  });

  test('detects high volatility in recent records', () {
    final now = DateTime.now();
    final result = service.analyze([
      record(mood: MoodType.happy, intensity: 1, createdAt: now),
      record(
        mood: MoodType.anxious,
        intensity: 5,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
    ]);

    expect(result.volatility, 2);
    expect(result.hasWarning, isTrue);
    expect(result.warningReasons.first, contains('情绪波动较大'));
  });

  test('reports the most common mood for each time period', () {
    final now = DateTime.now();
    final morning = DateTime(now.year, now.month, now.day, 10);
    final result = service.analyze([
      record(mood: MoodType.calm, intensity: 3, createdAt: morning),
      record(
        mood: MoodType.calm,
        intensity: 4,
        createdAt: morning.add(const Duration(minutes: 30)),
      ),
      record(mood: MoodType.sad, intensity: 2, createdAt: morning),
    ]);

    expect(result.cyclePatterns['上午 (09-12)'], '平静');
    expect(result.cycleDetails['上午 (09-12)']?[MoodType.calm], 2);
  });
}
