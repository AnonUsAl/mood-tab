import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mood_record.dart';
import '../models/mood_type.dart';
import '../providers/mood_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/intensity_dots.dart';
import 'mood_record_page.dart';
import 'diary_page.dart';
import 'history_page.dart';
import 'breathing_exercise_page.dart';
import 'mood_garden_page.dart';
import 'urge_log_page.dart';
import 'conflict_care_page.dart';

/// 首页 - 今日情绪概览
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 数据由启动流程（main.dart 的 _AppEntrance）统一加载，
  // 首页不再重复触发 loadAllData，避免启动时的双重加载。

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<MoodProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.totalCount == 0) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: () => provider.loadAllData(),
              child: CustomScrollView(
                slivers: [
                  // 问候语头部
                  SliverToBoxAdapter(child: _buildHeader()),
                  // 情绪天气播报
                  SliverToBoxAdapter(child: _buildWeatherForecast(provider)),
                  // 今日情绪卡片
                  SliverToBoxAdapter(child: _buildTodaySection(provider)),
                  // 快速记录按钮
                  SliverToBoxAdapter(child: _buildQuickRecordButton()),
                  // 快捷入口
                  SliverToBoxAdapter(child: _buildQuickActions()),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 6) {
      greeting = '夜深了';
    } else if (hour < 12) {
      greeting = '早上好';
    } else if (hour < 14) {
      greeting = '中午好';
    } else if (hour < 18) {
      greeting = '下午好';
    } else {
      greeting = '晚上好';
    }

    final provider = context.read<MoodProvider>();
    final userName = provider.userName;
    final greetingText = userName.isNotEmpty ? '$greeting，$userName' : greeting;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                greetingText,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              _buildCheckinButton(provider),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '今天的心情怎么样？',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryOf(context),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckinButton(MoodProvider provider) {
    return GestureDetector(
      onTap: () async {
        if (!provider.hasCheckedInToday) {
          await provider.checkinToday();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('打卡成功！🎉')),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: provider.hasCheckedInToday
              ? AppTheme.primaryLight
              : AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              provider.hasCheckedInToday ? '✅' : '📅',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 4),
            Text(
              provider.hasCheckedInToday
                  ? '已打卡'
                  : '打卡',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: provider.hasCheckedInToday
                    ? AppTheme.primaryColor
                    : Colors.white,
              ),
            ),
            if (provider.checkinStreak > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: provider.hasCheckedInToday
                      ? AppTheme.primaryColor.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${provider.checkinStreak}天',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: provider.hasCheckedInToday
                        ? AppTheme.primaryColor
                        : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 情绪天气播报
  Widget _buildWeatherForecast(MoodProvider provider) {
    final todayRecords = provider.todayRecords;
    final allRecords = provider.allRecords;

    // 没有足够数据时不显示天气播报
    if (allRecords.isEmpty) return const SizedBox.shrink();

    // 计算今日天气
    String weatherEmoji;
    String weatherDesc;
    Color weatherColor;

    if (todayRecords.isEmpty) {
      // 今日还没记录 — 根据历史趋势播报
      weatherEmoji = '🌤️';
      weatherDesc = '新的一天，心情待记录';
      weatherColor = const Color(0xFF81C7E4);
    } else {
      // 今日已有记录 — 根据主导情绪播报
      final dominant = _getDominantMood(todayRecords);

      // 情绪→天气映射
      final weatherMap = {
        MoodType.happy: ('☀️', '心情晴朗，阳光灿烂', const Color(0xFFFFB74D)),
        MoodType.excited: ('⛅', '热情洋溢，风起云涌', const Color(0xFFFF8A65)),
        MoodType.calm: ('🌤️', '内心平静，微风轻拂', const Color(0xFF81C7E4)),
        MoodType.grateful: ('🌈', '感恩满溢，彩虹初现', const Color(0xFFA5D6A7)),
        MoodType.neutral: ('☁️', '波澜不惊，云层平稳', const Color(0xFFB0BEC5)),
        MoodType.tired: ('🌫️', '精力低迷，晨雾弥漫', const Color(0xFF9575CD)),
        MoodType.sad: ('🌧️', '情绪低落，细雨绵绵', const Color(0xFF64B5F6)),
        MoodType.anxious: ('⛈️', '内心不安，雷雨将至', const Color(0xFFE57373)),
        MoodType.angry: ('🔥', '怒火中烧，高温预警', const Color(0xFFEF5350)),
        MoodType.lonely: ('❄️', '孤立感加重，霜降时节', const Color(0xFF78909C)),
      };

      final w = weatherMap[dominant]!;
      weatherEmoji = w.$1;
      weatherDesc = w.$2;
      weatherColor = w.$3;
    }

    // 周趋势
    String trendText;
    final weekRecords = allRecords.where((r) {
      final now = DateTime.now();
      final diff = now.difference(r.createdAt);
      return diff.inDays <= 7;
    }).toList();

    if (weekRecords.length < 3) {
      trendText = '数据积累中 📊';
    } else {
      // 看近3天 vs 前4天的趋势
      final now = DateTime.now();
      final recent3 = weekRecords.where((r) {
        return now.difference(r.createdAt).inDays <= 3;
      }).toList();
      final earlier4 = weekRecords.where((r) {
        final diff = now.difference(r.createdAt).inDays;
        return diff > 3 && diff <= 7;
      }).toList();

      if (earlier4.isEmpty) {
        trendText = '正在起步 🌱';
      } else {
        final recentAvg = recent3.isEmpty
            ? 0
            : recent3.map((r) => r.intensity).reduce((a, b) => a + b) /
                recent3.length;
        final earlierAvg = earlier4
                .map((r) => r.intensity)
                .reduce((a, b) => a + b) /
            earlier4.length;

        final diff = recentAvg - earlierAvg;
        if (diff > 0.3) {
          trendText = '升温中 📈';
        } else if (diff < -0.3) {
          trendText = '降温中 📉';
        } else {
          trendText = '平稳 📊';
        }
      }
    }

    // 降雨概率（负面情绪占比）
    final negativeMoods = [
      MoodType.sad,
      MoodType.anxious,
      MoodType.angry,
      MoodType.lonely,
      MoodType.tired,
    ];
    final negativeCount = weekRecords
        .where((r) => negativeMoods.contains(r.moodType))
        .length;
    final rainProb =
        weekRecords.isEmpty ? 0 : (negativeCount / weekRecords.length * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              weatherColor.withValues(alpha: 0.12),
              weatherColor.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: weatherColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 天气标题
            Row(
              children: [
                Text(
                  weatherEmoji,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '情绪天气预报',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: weatherColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        weatherDesc,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 底部数据
            Row(
              children: [
                _buildWeatherStat('周趋势', trendText),
                const SizedBox(width: 16),
                _buildWeatherStat('情绪降雨', '$rainProb%'),
                const SizedBox(width: 16),
                _buildWeatherStat('本周记录', '${weekRecords.length}条'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  MoodType _getDominantMood(List<MoodRecord> records) {
    final counts = <MoodType, int>{};
    for (final r in records) {
      counts[r.moodType] = (counts[r.moodType] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  Widget _buildWeatherStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textHintOf(context),
                  fontSize: 11,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySection(MoodProvider provider) {
    final todayRecords = provider.todayRecords;

    if (todayRecords.isEmpty) {
      return const EmptyState(
        emoji: '🌱',
        title: '今天还没有记录情绪',
        subtitle: '点击下方按钮，记录此刻的感受吧',
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            '今日记录 · ${todayRecords.length} 条',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          // 今日情绪列表
          ...todayRecords.map((record) => _buildTodayRecordCard(record)),
        ],
      ),
    );
  }

  Widget _buildTodayRecordCard(MoodRecord record) {
    final moodColor = Color(record.moodType.colorValue);
    final timeStr = _formatTime(record.createdAt);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MoodRecordPage(existingRecord: record),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBgOf(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: moodColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: moodColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  record.moodType.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        record.moodType.label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 8),
                      IntensityDots(
                        intensity: record.intensity,
                        color: moodColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (record.note != null && record.note!.isNotEmpty)
                    Text(
                      record.note!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      timeStr,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (record.note != null && record.note!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      timeStr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textHintOf(context),
                            fontSize: 11,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRecordButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MoodRecordPage(),
              ),
            );
          },
          icon: const Icon(Icons.edit_note, size: 22),
          label: const Text('记录此刻心情'),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              icon: Icons.local_florist,
              label: '花园',
              color: const Color(0xFFA5D6A7),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const MoodGardenPage()),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionCard(
              icon: Icons.air,
              label: '呼吸',
              color: const Color(0xFF8BE9C1),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const BreathingExercisePage()),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionCard(
              icon: Icons.menu_book_outlined,
              label: '日记',
              color: const Color(0xFF9575CD),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DiaryPage()),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionCard(
              icon: Icons.access_time_outlined,
              label: '历史',
              color: const Color(0xFF4FC3F7),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistoryPage()),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionCard(
              icon: Icons.shield_outlined,
              label: '冲突关怀',
              color: const Color(0xFFE57373),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ConflictCarePage()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: AppTheme.cardBgOf(context),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
