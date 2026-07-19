import 'dart:math';
import '../models/mood_record.dart';
import '../models/mood_type.dart';

/// 情绪分析结果
class MoodAnalysisResult {
  /// 最近7天情绪强度波动幅度（标准差）
  final double volatility;

  /// 平均强度
  final double averageIntensity;

  /// 最近7天记录数
  final int recentRecordCount;

  /// 是否需要预警
  final bool hasWarning;

  /// 预警原因列表
  final List<String> warningReasons;

  /// 情绪周期规律：时段名称 → 常见情绪名称
  final Map<String, String> cyclePatterns;

  /// 情绪周期详细数据：时段名称 → 各情绪出现次数
  final Map<String, Map<MoodType, int>> cycleDetails;

  MoodAnalysisResult({
    required this.volatility,
    required this.averageIntensity,
    required this.recentRecordCount,
    required this.hasWarning,
    required this.warningReasons,
    required this.cyclePatterns,
    required this.cycleDetails,
  });

  /// 是否有足够数据进行分析（至少需要 2 条记录）
  bool get hasEnoughData => recentRecordCount >= 2;

  /// 波动等级描述
  String get volatilityLevel {
    if (volatility < 0.5) return '平稳';
    if (volatility < 1.0) return '轻微波动';
    if (volatility < 1.5) return '中度波动';
    return '剧烈波动';
  }
}

/// 情绪分析服务
/// 对情绪记录数据进行统计分析，检测异常波动和周期规律
class MoodAnalysisService {
  /// 分析情绪数据
  ///
  /// [records] 为情绪记录列表（正序或倒序均可）
  /// 返回包含波动幅度、预警信息和周期规律的 [MoodAnalysisResult]
  MoodAnalysisResult analyze(List<MoodRecord> records) {
    if (records.isEmpty) {
      return MoodAnalysisResult(
        volatility: 0,
        averageIntensity: 0,
        recentRecordCount: 0,
        hasWarning: false,
        warningReasons: [],
        cyclePatterns: {},
        cycleDetails: {},
      );
    }

    // 筛选最近 7 天的记录
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final recentRecords = records.where((r) {
      return r.createdAt.isAfter(sevenDaysAgo) ||
          r.createdAt.isAtSameMomentAs(sevenDaysAgo);
    }).toList();

    if (recentRecords.isEmpty) {
      return MoodAnalysisResult(
        volatility: 0,
        averageIntensity: 0,
        recentRecordCount: 0,
        hasWarning: false,
        warningReasons: [],
        cyclePatterns: {},
        cycleDetails: {},
      );
    }

    // 计算强度标准差和平均值
    final intensities =
        recentRecords.map((r) => r.intensity.toDouble()).toList();
    final volatility = _stdDev(intensities);
    final avgIntensity =
        intensities.reduce((a, b) => a + b) / intensities.length;

    // ==================== 异常波动检测 ====================

    final warningReasons = <String>[];

    // 规则 1：标准差 > 1.5
    if (volatility > 1.5) {
      warningReasons.add(
        '最近7天情绪波动较大（标准差 ${volatility.toStringAsFixed(2)}），'
        '建议关注情绪管理',
      );
    }

    // 规则 2：连续 3 天强度差异 > 2
    final consecutiveWarning = _checkConsecutiveDiff(recentRecords);
    if (consecutiveWarning != null) {
      warningReasons.add(consecutiveWarning);
    }

    // ==================== 情绪周期规律分析 ====================

    final cycleDetails = _analyzeCycles(recentRecords);
    final cyclePatterns = <String, String>{};
    for (final entry in cycleDetails.entries) {
      final sortedMoods = entry.value.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (sortedMoods.isNotEmpty) {
        cyclePatterns[entry.key] = sortedMoods.first.key.label;
      }
    }

    return MoodAnalysisResult(
      volatility: volatility,
      averageIntensity: avgIntensity,
      recentRecordCount: recentRecords.length,
      hasWarning: warningReasons.isNotEmpty,
      warningReasons: warningReasons,
      cyclePatterns: cyclePatterns,
      cycleDetails: cycleDetails,
    );
  }

  /// 计算标准差（总体标准差）
  double _stdDev(List<double> values) {
    if (values.length < 2) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
            values.length;
    return sqrt(variance);
  }

  /// 检测连续天数强度差异
  ///
  /// 按天分组计算每天平均强度，检查是否有连续 3 天
  /// 相邻两天的平均强度差异 > 2
  String? _checkConsecutiveDiff(List<MoodRecord> records) {
    // 按天分组
    final dailyIntensities = <DateTime, List<int>>{};
    for (final r in records) {
      final day =
          DateTime(r.createdAt.year, r.createdAt.month, r.createdAt.day);
      dailyIntensities.putIfAbsent(day, () => []);
      dailyIntensities[day]!.add(r.intensity);
    }

    // 计算每天平均强度，按日期排序
    final sortedDays = dailyIntensities.keys.toList()..sort();
    final dailyAvgs = sortedDays.map((day) {
      final ints = dailyIntensities[day]!;
      return ints.reduce((a, b) => a + b) / ints.length;
    }).toList();

    // 检查连续 3 天差异
    for (int i = 0; i < dailyAvgs.length - 2; i++) {
      final diff1 = (dailyAvgs[i] - dailyAvgs[i + 1]).abs();
      final diff2 = (dailyAvgs[i + 1] - dailyAvgs[i + 2]).abs();
      if (diff1 > 2 && diff2 > 2) {
        return '检测到连续3天情绪强度剧烈变化，建议关注情绪状态';
      }
    }

    return null;
  }

  /// 分析情绪周期规律
  ///
  /// 将记录按时段分组，统计各时段的常见情绪
  Map<String, Map<MoodType, int>> _analyzeCycles(List<MoodRecord> records) {
    final result = <String, Map<MoodType, int>>{
      '清晨 (06-09)': {},
      '上午 (09-12)': {},
      '下午 (12-18)': {},
      '晚间 (18-22)': {},
      '深夜 (22-06)': {},
    };

    for (final r in records) {
      final hour = r.createdAt.hour;
      String period;
      if (hour >= 6 && hour < 9) {
        period = '清晨 (06-09)';
      } else if (hour >= 9 && hour < 12) {
        period = '上午 (09-12)';
      } else if (hour >= 12 && hour < 18) {
        period = '下午 (12-18)';
      } else if (hour >= 18 && hour < 22) {
        period = '晚间 (18-22)';
      } else {
        period = '深夜 (22-06)';
      }

      result[period]!.update(r.moodType, (v) => v + 1, ifAbsent: () => 1);
    }

    // 移除没有数据的时段
    result.removeWhere((_, v) => v.isEmpty);

    return result;
  }
}
