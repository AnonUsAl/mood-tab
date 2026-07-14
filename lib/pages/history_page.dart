import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mood_record.dart';
import '../models/mood_tag.dart';
import '../models/mood_type.dart';
import '../providers/mood_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/intensity_dots.dart';

/// 历史记录页面 - 时间线展示所有情绪记录
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
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
          builder: (context, provider, child) {
            if (provider.isLoading && provider.allRecords.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.allRecords.isEmpty) {
              return const EmptyState(
                emoji: '📔',
                title: '还没有任何记录',
                subtitle: '记录的情绪会在这里按时间线展示',
              );
            }

            // 按日期分组
            final grouped = _groupByDate(provider.allRecords);
            final dates = grouped.keys.toList();

            return RefreshIndicator(
              onRefresh: () => provider.loadAllData(),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: dates.length,
                itemBuilder: (context, index) {
                  final dateLabel = dates[index];
                  final records = grouped[dateLabel]!;
                  return _buildDateGroup(dateLabel, records, index == 0);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  /// 按日期分组记录
  Map<String, List<MoodRecord>> _groupByDate(List<MoodRecord> records) {
    final grouped = <String, List<MoodRecord>>{};
    for (final record in records) {
      final key = _formatDateLabel(record.createdAt);
      grouped.putIfAbsent(key, () => []).add(record);
    }
    return grouped;
  }

  String _formatDateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(date).inDays;

    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    if (diff == 2) return '前天';

    String weekday;
    switch (dt.weekday) {
      case 1: weekday = '周一'; break;
      case 2: weekday = '周二'; break;
      case 3: weekday = '周三'; break;
      case 4: weekday = '周四'; break;
      case 5: weekday = '周五'; break;
      case 6: weekday = '周六'; break;
      case 7: weekday = '周日'; break;
      default: weekday = '';
    }

    if (diff < 7) return weekday;

    return '${dt.month}月${dt.day}日';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildDateGroup(String dateLabel, List<MoodRecord> records, bool isFirst) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isFirst) const SizedBox(height: 20),
        // 日期标签
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            dateLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ),
        // 该日期下的记录卡片
        ...records.map((record) => _buildRecordCard(record)),
      ],
    );
  }

  Widget _buildRecordCard(MoodRecord record) {
    final moodColor = Color(record.moodType.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey(record.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        confirmDismiss: (direction) => _confirmDelete(context, record),
        child: GestureDetector(
          onTap: () => _showDetailSheet(context, record),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: moodColor.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 情绪 emoji
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: moodColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      record.moodType.emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 内容
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
                            size: 6,
                          ),
                          const Spacer(),
                          Text(
                            _formatTime(record.createdAt),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textHint,
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ),
                      if (record.note != null && record.note!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          record.note!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (record.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: record.tags.map((tag) {
                            final emoji = MoodTags.emojiFor(tag) ?? '';
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$emoji $tag',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 确认删除
  Future<bool?> _confirmDelete(BuildContext context, MoodRecord record) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('删除这条记录？'),
          content: Text('删除后无法恢复。确定要删除这条${record.moodType.label}记录吗？'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  /// 详情底部弹窗
  void _showDetailSheet(BuildContext context, MoodRecord record) {
    final moodColor = Color(record.moodType.colorValue);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 拖拽条
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // 情绪头部
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: moodColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          record.moodType.emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.moodType.label,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _fullDateTime(record.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // 强度
                _buildDetailRow('情绪强度', IntensityDots(
                  intensity: record.intensity,
                  color: moodColor,
                  size: 10,
                )),
                const SizedBox(height: 16),
                // 标签
                if (record.tags.isNotEmpty) ...[
                  _buildDetailRow('触发标签', Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: record.tags.map((tag) {
                      final emoji = MoodTags.emojiFor(tag) ?? '';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: moodColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$emoji $tag',
                          style: TextStyle(
                            fontSize: 13,
                            color: moodColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  )),
                  const SizedBox(height: 16),
                ],
                // 备注
                if (record.note != null && record.note!.isNotEmpty) ...[
                  Text(
                    '备注',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      record.note!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // 删除按钮
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      final shouldDelete = await _confirmDelete(context, record) ?? false;
                      if (shouldDelete && context.mounted) {
                        await context.read<MoodProvider>().deleteRecord(record.id!);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('记录已删除'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: const Text('删除记录'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, Widget child) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  String _fullDateTime(DateTime dt) {
    return '${dt.year}年${dt.month}月${dt.day}日 '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
