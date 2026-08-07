import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/mood_record.dart';
import '../models/mood_tag.dart';
import '../models/mood_type.dart';
import '../providers/mood_provider.dart';
import '../theme/app_theme.dart';
import 'crisis_support_page.dart';

/// 情绪记录页面
/// 选择情绪类型 → 设置强度 → 选择标签 → 添加备注 → 写日记（可选） → 保存
/// 支持补记：传入 initialDate 即可记录过去某天的情绪
/// 支持编辑：传入 existingRecord 即可修改已有记录
class MoodRecordPage extends StatefulWidget {
  final DateTime? initialDate;
  final MoodRecord? existingRecord;

  const MoodRecordPage({super.key, this.initialDate, this.existingRecord});

  @override
  State<MoodRecordPage> createState() => _MoodRecordPageState();
}

class _MoodRecordPageState extends State<MoodRecordPage> {
  MoodType? _selectedMood;
  int _intensity = 3;
  final Set<String> _selectedTags = {};
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _diaryController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  List<String> _diaryImages = [];
  bool _isSaving = false;
  bool _showDiary = false;

  /// 补记日期（如果是补记模式）
  DateTime? _backfillDate;

  /// 编辑的已有记录（如果是编辑模式）
  MoodRecord? _editingRecord;

  @override
  void initState() {
    super.initState();
    _backfillDate = widget.initialDate;

    // 编辑模式：回填已有记录数据
    if (widget.existingRecord != null) {
      _editingRecord = widget.existingRecord;
      _selectedMood = _editingRecord!.moodType;
      _intensity = _editingRecord!.intensity;
      _selectedTags.addAll(_editingRecord!.tags);
      _noteController.text = _editingRecord!.note ?? '';
      _diaryController.text = _editingRecord!.diary ?? '';
      _diaryImages = List.from(_editingRecord!.diaryImages);
      if (_diaryController.text.isNotEmpty || _diaryImages.isNotEmpty) {
        _showDiary = true;
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _diaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBackfill = _backfillDate != null;
    final isEditing = _editingRecord != null;
    final title = isEditing ? '修改心情' : '记录心情';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _onSave,
            child: Text(
              '保存',
              style: TextStyle(
                color: _selectedMood == null
                    ? AppTheme.textHintOf(context)
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
              // 非编辑模式：可选择记录日期
              if (!isEditing) ...[
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isBackfill
                          ? AppTheme.primaryColor.withValues(alpha: 0.1)
                          : AppTheme.cardBgOf(context),
                      borderRadius: BorderRadius.circular(8),
                      border: isBackfill
                          ? null
                          : Border.all(color: AppTheme.dividerOf(context)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: isBackfill
                              ? AppTheme.primaryColor
                              : AppTheme.textSecondaryOf(context),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isBackfill
                              ? '补记 ${_backfillDate!.year}年${_backfillDate!.month}月${_backfillDate!.day}日的情绪'
                              : '记录今天的情绪 · 点击可切换日期',
                          style: TextStyle(
                            fontSize: 13,
                            color: isBackfill
                                ? AppTheme.primaryColor
                                : AppTheme.textSecondaryOf(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: isBackfill
                              ? AppTheme.primaryColor
                              : AppTheme.textHintOf(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              // 补记日期提示（保留旧逻辑兼容，编辑模式下不显示）
              // 步骤 1: 选择情绪
              _buildSectionLabel(_backfillDate != null ? '那天的心情是什么？' : '选择此刻的情绪'),
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
                const SizedBox(height: 20),
              ],

              // 步骤 5: 日记（可选展开）
              if (_selectedMood != null) ...[
                _buildDiarySection(),
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
                  : AppTheme.cardBgOf(context),
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
                        ? AppTheme.textPrimaryOf(context)
                        : AppTheme.textSecondaryOf(context),
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
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
        color: AppTheme.cardBgOf(context),
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
                    color: isActive ? moodColor : AppTheme.dividerOf(context),
                  ),
                  child: Center(
                    child: Text(
                      '$level',
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : AppTheme.textHintOf(context),
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
    final allTags = context.select<MoodProvider, List<MoodTag>>(
      (p) => p.allTags,
    );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allTags.map((tag) {
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
                  : AppTheme.cardBgOf(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.dividerOf(context),
              ),
            ),
            child: Text(
              '${tag.emoji} ${tag.label}',
              style: TextStyle(
                fontSize: 13,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondaryOf(context),
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

  /// 日记区域（可选展开）
  Widget _buildDiarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _showDiary = !_showDiary;
            });
          },
          child: Row(
            children: [
              Text(
                '写一篇日记',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              Icon(
                _showDiary ? Icons.expand_less : Icons.expand_more,
                color: AppTheme.textSecondaryOf(context),
              ),
              const Spacer(),
              if (_showDiary)
                Text(
                  '可选',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textHintOf(context),
                      ),
                ),
            ],
          ),
        ),
        if (_showDiary) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _diaryController,
            maxLines: 12,
            maxLength: 5000,
            decoration: const InputDecoration(
              hintText: '今天发生了什么？想深入写写的话，在这里记录你的故事和思考...',
            ),
          ),
          const SizedBox(height: 12),
          // 图片选择按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_outlined, size: 18),
                  label: const Text('从相册选择'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(color: AppTheme.dividerOf(context)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('拍照'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(color: AppTheme.dividerOf(context)),
                  ),
                ),
              ),
            ],
          ),
          // 已选图片预览
          if (_diaryImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _diaryImages.asMap().entries.map((entry) {
                final index = entry.key;
                final path = entry.value;
                return _buildImagePreview(path, index);
              }).toList(),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildImagePreview(String path, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(path),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 80,
              height: 80,
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image_outlined,
                  color: Colors.grey, size: 28),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _diaryImages.removeAt(index);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Future<String?> _saveImageToAppDir(File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          'diary_${DateTime.now().millisecondsSinceEpoch}_${_diaryImages.length}.jpg';
      final destPath = p.join(appDir.path, fileName);
      final bytes = await imageFile.readAsBytes();
      await File(destPath).writeAsBytes(bytes);
      return destPath;
    } catch (e) {
      debugPrint('保存图片失败: $e');
      return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (result != null) {
        final savedPath = await _saveImageToAppDir(File(result.path));
        if (savedPath != null) {
          setState(() => _diaryImages.add(savedPath));
        }
      }
    } catch (e) {
      debugPrint('选择图片失败: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final result = await _imagePicker.pickImage(source: ImageSource.camera);
      if (result != null) {
        final savedPath = await _saveImageToAppDir(File(result.path));
        if (savedPath != null) {
          setState(() => _diaryImages.add(savedPath));
        }
      }
    } catch (e) {
      debugPrint('拍照失败: $e');
    }
  }

  /// 检测是否需要危机支持
  bool _needsCrisisSupport() {
    // 负面情绪类型：难过、焦虑、愤怒、孤独
    const negativeMoods = {
      MoodType.sad,
      MoodType.anxious,
      MoodType.angry,
      MoodType.lonely,
    };
    // 强度 4-5 且为负面情绪时触发
    return negativeMoods.contains(_selectedMood) && _intensity >= 4;
  }

  /// 选择记录日期（仅新建模式下可用）
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _backfillDate ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: '选择记录的日期',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked == null) return;
    // 如果是今天，清空补记日期（使用默认 DateTime.now()）
    final today = DateTime(now.year, now.month, now.day);
    final pickedDay = DateTime(picked.year, picked.month, picked.day);
    setState(() {
      _backfillDate = pickedDay == today ? null : picked;
    });
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

    final needsSupport = _needsCrisisSupport();
    final navigator = Navigator.of(context);

    setState(() {
      _isSaving = true;
    });

    final note = _noteController.text.trim();
    final diary = _diaryController.text.trim();

    if (_editingRecord != null) {
      // 编辑模式：更新已有记录
      final updated = _editingRecord!.copyWith(
        moodType: _selectedMood!,
        intensity: _intensity,
        note: note.isEmpty ? null : note,
        diary: diary.isEmpty ? null : diary,
        diaryImages: _diaryImages,
        tags: _selectedTags.toList(),
      );
      await context.read<MoodProvider>().updateRecord(updated);
    } else {
      // 新建模式：新增记录
      await context.read<MoodProvider>().addRecord(
            moodType: _selectedMood!,
            intensity: _intensity,
            note: note.isEmpty ? null : note,
            diary: diary.isEmpty ? null : diary,
            diaryImages: _diaryImages,
            tags: _selectedTags.toList(),
            createdAt: _backfillDate,
          );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editingRecord != null
              ? '${_selectedMood!.emoji} 已修改心情记录'
              : _backfillDate != null
                  ? '${_selectedMood!.emoji} 已补记${_backfillDate!.month}月${_backfillDate!.day}日的心情'
                  : '${_selectedMood!.emoji} 已记录此刻的心情'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.primaryColor,
        ),
      );
      navigator.pop(true);

      // 如果是高强度负面情绪且不是编辑模式，延迟弹出关怀弹窗
      if (needsSupport && _editingRecord == null) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (navigator.mounted) {
            showCrisisSupportDialog(navigator.context);
          }
        });
      }
    }
  }
}
