import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mood_record.dart';
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final provider = context.read<MoodProvider>();
    final days = _isWeekly ? 7 : 30;
    _periodRecords = await provider.getRecentRecords(days);

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
                            color: AppTheme.textSecondary,
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
        color: const Color(0xFFF0F0F0),
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
                  color: _isWeekly ? Colors.white : Colors.transparent,
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
                      color: _isWeekly ? AppTheme.primaryColor : AppTheme.textSecondary,
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
                  color: !_isWeekly ? Colors.white : Colors.transparent,
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
                      color: !_isWeekly ? AppTheme.primaryColor : AppTheme.textSecondary,
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
        color: AppTheme.cardBg,
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
        return r.createdAt.isAfter(dayStart.subtract(const Duration(milliseconds: 1))) &&
            r.createdAt.isBefore(dayEnd);
      }).toList();

      double avgIntensity;
      if (dayRecords.isEmpty) {
        avgIntensity = 0;
      } else {
        avgIntensity = dayRecords
                .map((r) => r.intensity)
                .reduce((a, b) => a + b) /
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

    final spots = data.map((d) {
      // 没有数据的点用 0，但会通过 belowBarData 控制显示
      return FlSpot(d.x, d.y == 0 ? 0 : d.y);
    }).toList();

    // 仅在连续有数据的点之间画线
    final lineSpots = data.where((d) => d.y > 0).map((d) => FlSpot(d.x, d.y)).toList();

    final maxY = 5.0;
    final interval = _isWeekly ? 1.0 : 5.0;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return const FlLine(
              color: Color(0xFFF0F0F0),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == maxY) return const SizedBox.shrink();
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textHint,
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
                if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                // 月视图时只在部分位置显示标签
                if (!_isWeekly && idx % 5 != 0 && idx != data.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    data[idx].label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textHint,
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
        color: AppTheme.cardBg,
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
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(percent * 100).toInt()}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textHint,
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
                      backgroundColor: const Color(0xFFF0F0F0),
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

    final items = counts.entries.map((e) => _DistItem(mood: e.key, count: e.value)).toList();
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
    final avgIntensity = _periodRecords.map((r) => r.intensity).reduce((a, b) => a + b) /
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
                  color: AppTheme.textSecondary,
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
