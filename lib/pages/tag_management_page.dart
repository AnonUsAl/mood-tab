import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mood_tag.dart';
import '../providers/mood_provider.dart';
import '../theme/app_theme.dart';

/// 标签管理页面
/// 管理情绪触发标签：查看预设标签、添加/删除自定义标签
class TagManagementPage extends StatefulWidget {
  const TagManagementPage({super.key});

  @override
  State<TagManagementPage> createState() => _TagManagementPageState();
}

class _TagManagementPageState extends State<TagManagementPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('标签管理'),
        actions: [
          IconButton(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add),
            tooltip: '添加标签',
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<MoodProvider>(
          builder: (context, provider, _) {
            final customTags = provider.customTags;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 预设标签
                  _buildSectionTitle('预设标签'),
                  const SizedBox(height: 4),
                  Text(
                    '系统内置标签，不可修改',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textHintOf(context),
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildTagGrid(MoodTags.presets, editable: false),
                  const SizedBox(height: 28),

                  // 自定义标签
                  Row(
                    children: [
                      _buildSectionTitle('自定义标签'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${customTags.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '点击 + 添加你自己的触发标签',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textHintOf(context),
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (customTags.isEmpty)
                    _buildEmptyState()
                  else
                    _buildTagGrid(customTags, editable: true),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildTagGrid(List<MoodTag> tags, {required bool editable}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        return _buildTagChip(tag, editable: editable);
      }).toList(),
    );
  }

  Widget _buildTagChip(MoodTag tag, {required bool editable}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBgOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: editable
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : AppTheme.dividerOf(context),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tag.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            tag.label,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimaryOf(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (editable) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _confirmDelete(tag),
              child: Icon(
                Icons.close,
                size: 16,
                color: AppTheme.textHintOf(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppTheme.cardBgOf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '🏷️',
            style: TextStyle(fontSize: 36, color: AppTheme.textHintOf(context)),
          ),
          const SizedBox(height: 8),
          Text(
            '还没有自定义标签',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryOf(context),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '点击右下角 + 添加',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textHintOf(context),
                ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    String label = '';
    String selectedEmoji = MoodTags.availableEmojis.first;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              // 弹窗内容可滚动，避免弹出键盘时底部 emoji 选区溢出
              scrollable: true,
              title: const Text('添加自定义标签'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标签名称输入
                  TextField(
                    autofocus: true,
                    maxLength: 8,
                    decoration: const InputDecoration(
                      hintText: '输入标签名称（如：遛狗）',
                      counterText: '',
                    ),
                    onChanged: (value) {
                      label = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '选择图标',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  // Emoji 选择网格
                  SizedBox(
                    width: double.maxFinite,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        // 改成 7 列：每格更宽更矮，避免底部一行溢出 14 像素
                        crossAxisCount: 7,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                        childAspectRatio: 1,
                      ),
                      itemCount: MoodTags.availableEmojis.length,
                      itemBuilder: (_, index) {
                        final emoji = MoodTags.availableEmojis[index];
                        final isSelected = emoji == selectedEmoji;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedEmoji = emoji;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () async {
                    final trimmed = label.trim();
                    if (trimmed.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('请输入标签名称'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    if (MoodTags.exists(trimmed)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('该标签已存在'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    Navigator.of(ctx).pop();
                    await context
                        .read<MoodProvider>()
                        .addCustomTag(trimmed, selectedEmoji);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('已添加标签 "$trimmed"'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text('添加'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(MoodTag tag) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('删除标签'),
          content: Text('确定要删除 "${tag.emoji} ${tag.label}" 吗？\n\n'
              '已使用此标签的历史记录不受影响，但标签将不再显示在选择列表中。'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await context.read<MoodProvider>().deleteCustomTag(tag.label);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('已删除标签 "${tag.label}"'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }
}
