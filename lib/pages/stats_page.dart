import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mood_record.dart';
import '../models/mood_tag.dart';
import '../models/mood_type.dart';
import '../providers/mood_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

/// 统计分析页面
/// 展示情绪趋势折线图、情绪分布统计，支持周/月维度切换
class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  bool _isWeekly = true; // true=周视图, false=月视图
  List<MoodRecord> _periodRecords = [];
  List<MoodRecord> _prevPeriodRecords = []; // 上期记录，用于对比
  bool _isLoading = false;
  MoodProvider? _providerRef;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _providerRef = context.read<MoodProvider>();
      _providerRef!.addListener(_onProviderChanged);
      _loadData();
    });
  }

  @override
  void dispose() {
    _providerRef?.removeListener(_onProviderChanged);
    super.dispose();
  }

  /// Provider 数据变化时重新加载统计数据
  void _onProviderChanged() {
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final provider = context.read<MoodProvider>();
    final days = _isWeekly ? 7 : 30;

    // 本期数据
    _periodRecords = await provider.getRecentRecords(days);

    // 上期数据（用于对比）
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentStart = today.subtract(Duration(days: days - 1));
    final prevStart = currentStart.subtract(Duration(days: days));
    final prevEnd = currentStart;
    _prevPeriodRecords = await provider.getRecordsBetween(prevStart, prevEnd);

    setState(() {
      _isLoading = false;
    });
  }

  void _switchMode(bool weekly) {
    if (_isWeekly == weekly) return;
    setState(() {
      _isWeekly = weekly;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<MoodProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.allRecords.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.allRecords.isEmpty) {
              return const EmptyState(
                emoji: '📊',
                title: '还没有足够的数据',
                subtitle: '记录几天情绪后就能看到统计分析了',
              );
            }

            return RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(
                      '情绪分析',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '了解自己的情绪规律',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondaryOf(context),
                          ),
                    ),
                    const SizedBox(height: 20),

                    // 周/月切换
                    _buildModeSwitcher(),
                    const SizedBox(height: 24),

                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      // 趋势折线图
                      _buildTrendCard(),
                      const SizedBox(height: 20),

                      // 情绪分布
                      _buildDistributionCard(),
                      const SizedBox(height: 20),

                      // 本期概况
                      _buildSummaryCard(),
                      const SizedBox(height: 20),

                      // 标签分析
                      _buildTagAnalysisCard(),
                      const SizedBox(height: 20),

                      // 时段分析
                      _buildTimeOfDayCard(),
                      const SizedBox(height: 20),

                      // 星期分析
                      _buildWeekdayCard(),
                      const SizedBox(height: 20),

                      // 环比对比
                      _buildComparisonCard(),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 周/月切换器
  Widget _buildModeSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.dividerOf(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _switchMode(true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isWeekly
                      ? AppTheme.cardBgOf(context)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _isWeekly
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    '本周',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isWeekly
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondaryOf(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _switchMode(false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isWeekly
                      ? AppTheme.cardBgOf(context)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !_isWeekly
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    '本月',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: !_isWeekly
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondaryOf(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 情绪趋势折线图
  Widget _buildTrendCard() {
    final trendData = _computeTrendData();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBgOf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '情绪强度趋势',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '平均强度',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: _buildLineChart(trendData),
          ),
        ],
      ),
    );
  }

  /// 计算每日平均强度
  List<_TrendPoint> _computeTrendData() {
    final days = _isWeekly ? 7 : 30;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = <_TrendPoint>[];

    for (int i = days - 1; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dayStart = date;
      final dayEnd = date.add(const Duration(days: 1));

      final dayRecords = _periodRecords.where((r) {
        return r.createdAt
                .isAfter(dayStart.subtract(const Duration(milliseconds: 1))) &&
            r.createdAt.isBefore(dayEnd);
      }).toList();

      double avgIntensity;
      if (dayRecords.isEmpty) {
        avgIntensity = 0;
      } else {
        avgIntensity =
            dayRecords.map((r) => r.intensity).reduce((a, b) => a + b) /
                dayRecords.length;
      }

      String label;
      if (_isWeekly) {
        const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
        label = weekdays[date.weekday - 1];
      } else {
        label = '${date.day}';
      }

      result.add(_TrendPoint(
        x: (days - 1 - i).toDouble(),
        y: avgIntensity,
        label: label,
        date: date,
        count: dayRecords.length,
      ));
    }

    return result;
  }

  Widget _buildLineChart(List<_TrendPoint> data) {
    // 过滤出有数据的天数用于绘制线段
    final hasData = data.where((d) => d.y > 0).toList();

    if (hasData.isEmpty) {
      return Center(
        child: Text(
          '本期暂无记录',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    // 仅在连续有数据的点之间画线
    final lineSpots =
        data.where((d) => d.y > 0).map((d) => FlSpot(d.x, d.y)).toList();

    final maxY = 5.0;
    final interval = _isWeekly ? 1.0 : 5.0;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.dividerOf(context),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == maxY) return const SizedBox.shrink();
                return Text(
                  '${value.toInt()}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textHintOf(context),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) {
                  return const SizedBox.shrink();
                }
                // 月视图时只在部分位置显示标签
                if (!_isWeekly && idx % 5 != 0 && idx != data.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    data[idx].label,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textHintOf(context),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: lineSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            preventCurveOverShooting: true,
            color: AppTheme.primaryColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.15),
                  AppTheme.primaryColor.withValues(alpha: 0.02),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.spotIndex;
                // 在 lineSpots 中找到对应的 data 点
                final point = hasData[idx];
                return LineTooltipItem(
                  '${point.label}\n平均 ${point.y.toStringAsFixed(1)} · ${point.count}条',
                  const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  /// 情绪分布统计
  Widget _buildDistributionCard() {
    final distribution = _computeDistribution();
    final totalCount = _periodRecords.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBgOf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '情绪分布',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '共 $totalCount 条记录',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          ...distribution.map((item) {
            final percent = totalCount > 0 ? item.count / totalCount : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        '${item.mood.emoji} ${item.mood.label}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      Text(
                        '${item.count} 次',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondaryOf(context),
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(percent * 100).toInt()}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textHintOf(context),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 6,
                      backgroundColor: AppTheme.dividerOf(context),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(item.mood.colorValue),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  List<_DistItem> _computeDistribution() {
    final counts = <MoodType, int>{};
    for (final record in _periodRecords) {
      counts[record.moodType] = (counts[record.moodType] ?? 0) + 1;
    }

    final items = counts.entries
        .map((e) => _DistItem(mood: e.key, count: e.value))
        .toList();
    items.sort((a, b) => b.count.compareTo(a.count));
    return items;
  }

  /// 本期概况
  Widget _buildSummaryCard() {
    if (_periodRecords.isEmpty) {
      return const SizedBox.shrink();
    }

    final distribution = _computeDistribution();
    final mostFrequent = distribution.first;
    final avgIntensity =
        _periodRecords.map((r) => r.intensity).reduce((a, b) => a + b) /
            _periodRecords.length;
    final recordDays = _computeTrendData().where((d) => d.count > 0).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '本期概况',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            '📅',
            '记录天数',
            '$recordDays / ${_isWeekly ? 7 : 30} 天',
          ),
          _buildSummaryRow(
            '📝',
            '记录次数',
            '${_periodRecords.length} 次',
          ),
          _buildSummaryRow(
            '📊',
            '平均强度',
            avgIntensity.toStringAsFixed(1),
          ),
          _buildSummaryRow(
            mostFrequent.mood.emoji,
            '最常出现',
            '${mostFrequent.mood.label} (${mostFrequent.count}次)',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryOf(context),
                ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  // ==================== 标签分析 ====================

  Widget _buildTagAnalysisCard() {
    final tagStats = _computeTagStats();
    if (tagStats.isEmpty) return const SizedBox.shrink();

    final maxCount = tagStats.first.$2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBgOf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '触发标签排行',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '本期最常出现的触发因素',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryOf(context),
                ),
          ),
          const SizedBox(height: 20),
          ...tagStats.map((item) {
            final label = item.$1;
            final count = item.$2;
            final emoji = MoodTags.emojiFor(label) ?? '';
            final percent = maxCount > 0 ? count / maxCount : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('$emoji $label',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const Spacer(),
                      Text('$count 次',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondaryOf(context),
                              )),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 6,
                      backgroundColor: AppTheme.dividerOf(context),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 统计标签出现次数，返回 Top 5
  List<(String, int)> _computeTagStats() {
    final counts = <String, int>{};
    for (final record in _periodRecords) {
      for (final tag in record.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    final items = counts.entries
        .map((e) => (e.key, e.value))
        .toList();
    items.sort((a, b) => b.$2.compareTo(a.$2));
    return items.take(5).toList();
  }

  // ==================== 时段分析 ====================

  Widget _buildTimeOfDayCard() {
    final stats = _computeTimeOfDayStats();
    if (stats.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBgOf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '时段情绪分析',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '不同时段的情绪分布',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryOf(context),
                ),
          ),
          const SizedBox(height: 20),
          ...stats.entries.map((entry) {
            final period = entry.key;
            final data = entry.value;
            final moodEmoji = data.dominantMood?.emoji ?? '—';
            final moodLabel = data.dominantMood?.label ?? '无';
            final moodColor = data.dominantMood != null
                ? Color(data.dominantMood!.colorValue)
                : AppTheme.textHintOf(context);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      period,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: moodColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(moodEmoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      moodLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: moodColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Text(
                    '${data.count} 条',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryOf(context),
                        ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 按时段分组统计
  Map<String, _PeriodStat> _computeTimeOfDayStats() {
    final periods = <String, _PeriodStat>{};
    for (final r in _periodRecords) {
      final hour = r.createdAt.hour;
      String period;
      if (hour >= 6 && hour < 9) {
        period = '清晨';
      } else if (hour >= 9 && hour < 12) {
        period = '上午';
      } else if (hour >= 12 && hour < 18) {
        period = '下午';
      } else if (hour >= 18 && hour < 22) {
        period = '晚间';
      } else {
        period = '深夜';
      }
      periods.putIfAbsent(period, () => _PeriodStat());
      periods[period]!.add(r.moodType);
    }
    return periods;
  }

  // ==================== 星期分析 ====================

  Widget _buildWeekdayCard() {
    final stats = _computeWeekdayStats();
    final maxAvg = stats.values
        .map((s) => s.avgIntensity)
        .fold(0.0, (a, b) => a > b ? a : b);

    const weekdayLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBgOf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '星期情绪分析',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '每天的平均情绪强度',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryOf(context),
                ),
          ),
          const SizedBox(height: 20),
          // 柱状图
          // 高度 160：88px 最大柱体 + 约 60px 顶部数字/底部标签区域 + 安全边距
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weekdayLabels.map((label) {
                final stat = stats[label];
                final hasData = stat != null && stat.count > 0;
                // 柱体最大高度 88px：保留 52px 给顶部数字和底部「周X/X条」标签
                // 避免 5.0 满柱时 Column 内容溢出 SizedBox
                const maxBarHeight = 88.0;
                final barHeight = hasData && maxAvg > 0
                    ? (stat.avgIntensity / 5.0 * maxBarHeight)
                    : 0.0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (hasData) ...[
                          Text(
                            stat.avgIntensity.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondaryOf(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Container(
                          width: double.infinity,
                          height: hasData ? barHeight : 4,
                          decoration: BoxDecoration(
                            color: hasData
                                ? AppTheme.primaryColor.withValues(alpha: 0.8)
                                : AppTheme.dividerOf(context),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textHintOf(context),
                          ),
                        ),
                        if (hasData) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${stat.count}条',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppTheme.textHintOf(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 按星期分组统计
  Map<String, _WeekdayStat> _computeWeekdayStats() {
    const weekdayLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final stats = <String, _WeekdayStat>{
      for (final label in weekdayLabels) label: _WeekdayStat(),
    };

    for (final r in _periodRecords) {
      final weekday = weekdayLabels[r.createdAt.weekday - 1];
      stats[weekday]!.add(r.intensity);
    }
    return stats;
  }

  // ==================== 环比对比 ====================

  Widget _buildComparisonCard() {
    if (_periodRecords.isEmpty && _prevPeriodRecords.isEmpty) {
      return const SizedBox.shrink();
    }

    final currCount = _periodRecords.length;
    final prevCount = _prevPeriodRecords.length;
    final currAvg = _periodRecords.isEmpty
        ? 0.0
        : _periodRecords.map((r) => r.intensity).reduce((a, b) => a + b) /
            _periodRecords.length;
    final prevAvg = _prevPeriodRecords.isEmpty
        ? 0.0
        : _prevPeriodRecords.map((r) => r.intensity).reduce((a, b) => a + b) /
            _prevPeriodRecords.length;

    final countDiff = currCount - prevCount;
    final avgDiff = currAvg - prevAvg;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '环比对比',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            _isWeekly ? '本周 vs 上周' : '本月 vs 上月',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryOf(context),
                ),
          ),
          const SizedBox(height: 16),
          // 记录次数对比
          _buildComparisonRow(
            '记录次数',
            prevCount,
            currCount,
            countDiff,
            isHigherBetter: true,
            unit: '次',
          ),
          const SizedBox(height: 12),
          // 平均强度对比
          _buildComparisonRow(
            '平均强度',
            prevAvg,
            currAvg,
            avgDiff,
            isHigherBetter: null,
            unit: '',
            isDecimal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    String label,
    num prevValue,
    num currValue,
    num diff, {
    required bool? isHigherBetter,
    required String unit,
    bool isDecimal = false,
  }) {
    String fmt(num v) =>
        isDecimal ? v.toStringAsFixed(1) : v.toInt().toString();

    // 变化趋势颜色
    Color? diffColor;
    String diffText;
    if (diff == 0) {
      diffText = '持平';
      diffColor = AppTheme.textHintOf(context);
    } else {
      final isPositive = diff > 0;
      diffText = isPositive ? '+${fmt(diff.abs())}' : '-${fmt(diff.abs())}';
      if (isHigherBetter == null) {
        diffColor = AppTheme.textSecondaryOf(context);
      } else if (isPositive == isHigherBetter) {
        diffColor = const Color(0xFF66BB6A); // 绿色 = 好
      } else {
        diffColor = const Color(0xFFEF5350); // 红色 = 需关注
      }
    }

    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryOf(context),
              ),
        ),
        const Spacer(),
        // 上期值
        Text(
          '${fmt(prevValue)}$unit',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textHintOf(context),
                decoration: TextDecoration.lineThrough,
              ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.arrow_forward, size: 14, color: AppTheme.textHintOf(context)),
        const SizedBox(width: 8),
        // 本期值
        Text(
          '${fmt(currValue)}$unit',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 10),
        // 变化量
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: diffColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            diffText,
            style: TextStyle(
              fontSize: 11,
              color: diffColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// 趋势数据点
class _TrendPoint {
  final double x;
  final double y;
  final String label;
  final DateTime date;
  final int count;

  _TrendPoint({
    required this.x,
    required this.y,
    required this.label,
    required this.date,
    required this.count,
  });
}

/// 分布统计项
class _DistItem {
  final MoodType mood;
  final int count;

  _DistItem({required this.mood, required this.count});
}

/// 时段统计
class _PeriodStat {
  int count = 0;
  final Map<MoodType, int> _moodCounts = {};

  MoodType? get dominantMood {
    if (_moodCounts.isEmpty) return null;
    final sorted = _moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  void add(MoodType mood) {
    count++;
    _moodCounts[mood] = (_moodCounts[mood] ?? 0) + 1;
  }
}

/// 星期统计
class _WeekdayStat {
  int count = 0;
  int _totalIntensity = 0;

  double get avgIntensity => count > 0 ? _totalIntensity / count : 0;

  void add(int intensity) {
    count++;
    _totalIntensity += intensity;
  }
}
