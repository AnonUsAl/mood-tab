import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mood_tag.dart';
import '../models/mood_type.dart';
import '../providers/mood_provider.dart';
import '../theme/app_theme.dart';

/// 情绪记录页面
/// 选择情绪类型 → 设置强度 → 选择标签 → 添加备注 → 保存
class MoodRecordPage extends StatefulWidget {
  const MoodRecordPage({super.key});

  @override
  State<MoodRecordPage> createState() => _MoodRecordPageState();
}

class _MoodRecordPageState extends State<MoodRecordPage> {
  MoodType? _selectedMood;
  int _intensity = 3;
  final Set<String> _selectedTags = {};
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('记录心情'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _onSave,
            child: Text(
              '保存',
              style: TextStyle(
                color: _selectedMood == null
                    ? AppTheme.textHint
                    : AppTheme.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // 步骤 1: 选择情绪
              _buildSectionLabel('选择此刻的情绪'),
              const SizedBox(height: 12),
              _buildMoodGrid(),
              const SizedBox(height: 28),

              // 步骤 2: 情绪强度
              if (_selectedMood != null) ...[
                _buildSectionLabel('情绪强度'),
                const SizedBox(height: 16),
                _buildIntensitySelector(),
                const SizedBox(height: 28),
              ],

              // 步骤 3: 触发标签
              if (_selectedMood != null) ...[
                _buildSectionLabel('什么触发了这个情绪？'),
                const SizedBox(height: 12),
                _buildTagChips(),
                const SizedBox(height: 28),
              ],

              // 步骤 4: 备注
              if (_selectedMood != null) ...[
                _buildSectionLabel('想说点什么？'),
                const SizedBox(height: 12),
                _buildNoteField(),
                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }

  /// 情绪类型网格
  Widget _buildMoodGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: MoodType.values.length,
      itemBuilder: (context, index) {
        final mood = MoodType.values[index];
        final isSelected = _selectedMood == mood;
        final moodColor = Color(mood.colorValue);

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedMood = mood;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? moodColor.withValues(alpha: 0.15)
                  : AppTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? moodColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  mood.emoji,
                  style: TextStyle(
                    fontSize: isSelected ? 30 : 26,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mood.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 强度选择器
  Widget _buildIntensitySelector() {
    final moodColor = Color(_selectedMood!.colorValue);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              final level = index + 1;
              final isActive = level <= _intensity;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _intensity = level;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? moodColor : const Color(0xFFF0F0F0),
                  ),
                  child: Center(
                    child: Text(
                      '$level',
                      style: TextStyle(
                        color: isActive ? Colors.white : AppTheme.textHint,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            _intensityLabel(_intensity),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: moodColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  String _intensityLabel(int level) {
    switch (level) {
      case 1:
        return '微微一点';
      case 2:
        return '有些明显';
      case 3:
        return '中等程度';
      case 4:
        return '比较强烈';
      case 5:
        return '非常强烈';
      default:
        return '';
    }
  }

  /// 标签选择
  Widget _buildTagChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MoodTags.presets.map((tag) {
        final isSelected = _selectedTags.contains(tag.label);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedTags.remove(tag.label);
              } else {
                _selectedTags.add(tag.label);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.12)
                  : AppTheme.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : const Color(0xFFE8E8E8),
              ),
            ),
            child: Text(
              '${tag.emoji} ${tag.label}',
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 备注输入框
  Widget _buildNoteField() {
    return TextField(
      controller: _noteController,
      maxLines: 4,
      maxLength: 200,
      decoration: const InputDecoration(
        hintText: '记录下此刻的想法、感受或发生的事情...',
      ),
    );
  }

  /// 保存记录
  Future<void> _onSave() async {
    if (_selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先选择一个情绪'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final note = _noteController.text.trim();
    await context.read<MoodProvider>().addRecord(
          moodType: _selectedMood!,
          intensity: _intensity,
          note: note.isEmpty ? null : note,
          tags: _selectedTags.toList(),
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedMood!.emoji} 已记录此刻的心情'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.primaryColor,
        ),
      );
      Navigator.of(context).pop();
    }
  }
}
