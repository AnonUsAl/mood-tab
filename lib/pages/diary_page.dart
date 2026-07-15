import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mood_record.dart';
import '../models/mood_type.dart';
import '../providers/mood_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

/// 日记本页
/// 展示所有包含日记内容的情绪记录，按日期倒序排列
class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  /// 记录每条日记的展开状态
  final Set<int> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MoodProvider>().loadAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<MoodProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.diaryRecords.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final diaryRecords = provider.diaryRecords;

            if (diaryRecords.isEmpty) {
              return const EmptyState(
                emoji: '📖',
                title: '还没有写下日记',
                subtitle: '记录情绪时可以写一段日记，\n它会出现在这里',
              );
            }

            return RefreshIndicator(
              onRefresh: () => provider.loadAllData(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(
                      '日记本',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '共 ${diaryRecords.length} 篇日记',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondaryOf(context),
                          ),
                    ),
                    const SizedBox(height: 20),
                    // 日记列表
                    ...diaryRecords.map((record) {
                      return _buildDiaryCard(record);
                    }),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDiaryCard(MoodRecord record) {
    final moodColor = Color(record.moodType.colorValue);
    final isExpanded = _expandedIds.contains(record.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardBgOf(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: moodColor.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedIds.remove(record.id);
              } else {
                _expandedIds.add(record.id!);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头部：日期 + 情绪
                Row(
                  children: [
                    // 情绪 emoji
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: moodColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          record.moodType.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 日期和情绪名
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(record.createdAt),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                record.moodType.label,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: moodColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatTime(record.createdAt),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textHintOf(context),
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 展开/收起图标
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppTheme.textHintOf(context),
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 分隔线
                Container(
                  height: 1,
                  color: AppTheme.dividerOf(context),
                ),
                const SizedBox(height: 12),
                // 日记内容
                Text(
                  record.diary ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.7,
                        color: AppTheme.textPrimaryOf(context),
                      ),
                  maxLines: isExpanded ? null : 2,
                  overflow:
                      isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(date).inDays;

    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    if (diff == 2) return '前天';

    return '${dt.year}年${dt.month}月${dt.day}日';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
