import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/urge_log.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class UrgeLogPage extends StatefulWidget {
  const UrgeLogPage({super.key});

  @override
  State<UrgeLogPage> createState() => _UrgeLogPageState();
}

class _UrgeLogPageState extends State<UrgeLogPage> {
  final _dbService = DatabaseService();
  final _imagePicker = ImagePicker();
  final _scrollController = ScrollController();
  List<UrgeLog> _logs = [];
  bool _isLoading = true;

  final _titleController = TextEditingController();
  final _triggerController = TextEditingController();
  final _copingController = TextEditingController();
  final _noteController = TextEditingController();
  int _intensity = 1;
  bool _actedOn = false;
  File? _selectedImage;
  UrgeLog? _editingLog;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _triggerController.dispose();
    _copingController.dispose();
    _noteController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      _logs = await _dbService.getUrgeLogs();
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    try {
      final result = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (result != null) {
        // 立即复制到 app 目录，避免临时文件被系统清理
        final savedPath = await _saveImageToAppDir(File(result.path));
        if (savedPath != null) {
          setState(() => _selectedImage = File(savedPath));
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
          setState(() => _selectedImage = File(savedPath));
        }
      }
    } catch (e) {
      debugPrint('拍照失败: $e');
    }
  }

  Future<String?> _saveImageToAppDir(File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'urge_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final destPath = p.join(appDir.path, fileName);
      // 用 readAsBytes + writeAsBytes 替代 copy，更可靠地处理跨路径读取
      final bytes = await imageFile.readAsBytes();
      final destFile = File(destPath);
      await destFile.writeAsBytes(bytes);
      return destPath;
    } catch (e) {
      debugPrint('保存图片失败: $e');
      return null;
    }
  }

  Future<void> _saveLog() async {
    // 图片在选图/拍照时已保存到 app 目录，直接使用路径
    final imagePath = _selectedImage?.path;

    if (_editingLog != null) {
      final updated = _editingLog!.copyWith(
        title: _titleController.text.trim(),
        intensity: _intensity,
        actedOn: _actedOn,
        trigger: _triggerController.text.trim(),
        copingUsed: _copingController.text.trim(),
        note: _noteController.text.trim(),
        imagePath: imagePath ?? _editingLog!.imagePath,
      );
      await _dbService.updateUrgeLog(updated);
      _cancelEdit();
      await _loadLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('记录已更新')),
        );
      }
      return;
    }

    final log = UrgeLog(
      title: _titleController.text.trim(),
      intensity: _intensity,
      actedOn: _actedOn,
      trigger: _triggerController.text.trim(),
      copingUsed: _copingController.text.trim(),
      note: _noteController.text.trim(),
      imagePath: imagePath,
      createdAt: DateTime.now(),
    );

    await _dbService.insertUrgeLog(log);

    _titleController.clear();
    _triggerController.clear();
    _copingController.clear();
    _noteController.clear();
    _intensity = 1;
    _actedOn = false;
    _selectedImage = null;

    await _loadLogs();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('记录已保存')),
      );
    }
  }

  void _startEdit(UrgeLog log) {
    setState(() {
      _editingLog = log;
      _titleController.text = log.title ?? '';
      _triggerController.text = log.trigger ?? '';
      _copingController.text = log.copingUsed ?? '';
      _noteController.text = log.note ?? '';
      _intensity = log.intensity;
      _actedOn = log.actedOn;
      _selectedImage = log.imagePath != null ? File(log.imagePath!) : null;
    });
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _cancelEdit() {
    setState(() {
      _editingLog = null;
      _titleController.clear();
      _triggerController.clear();
      _copingController.clear();
      _noteController.clear();
      _intensity = 1;
      _actedOn = false;
      _selectedImage = null;
    });
  }

  Future<void> _deleteLog(int id) async {
    await _dbService.deleteUrgeLog(id);
    await _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('冲突关怀'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAddSection(),
            const SizedBox(height: 32),
            _buildLogsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddSection() {
    final isEditing = _editingLog != null;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  isEditing ? '修改记录' : '记录当下感受',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                if (isEditing)
                  TextButton(
                    onPressed: _cancelEdit,
                    child: const Text('取消'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '事件名称',
                hintText: '给这次记录起个名字',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.dividerOf(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.dividerOf(context)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildImagePicker(),
            const SizedBox(height: 12),
            _buildIntensitySlider(),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('冲动是否演变为行为'),
              subtitle: const Text('用于自我觉察，非评判'),
              value: _actedOn,
              onChanged: (value) => setState(() => _actedOn = value),
              activeColor: AppTheme.primaryColor,
            ),
            TextField(
              controller: _triggerController,
              decoration: InputDecoration(
                labelText: '诱因',
                hintText: '触发当下情绪的事件或想法',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.dividerOf(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.dividerOf(context)),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _copingController,
              decoration: InputDecoration(
                labelText: '应对方式',
                hintText: '你尝试了哪些方法来缓解冲动',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.dividerOf(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.dividerOf(context)),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: '备注',
                hintText: '其他想说的话',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.dividerOf(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.dividerOf(context)),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  isEditing ? '更新记录' : '保存记录',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '关联图片',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        if (_selectedImage != null)
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: FileImage(_selectedImage!),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedImage = null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickImage,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: AppTheme.dividerOf(context)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image, size: 20),
                      SizedBox(width: 8),
                      Text('从相册选择'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _takePhoto,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: AppTheme.dividerOf(context)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 20),
                      SizedBox(width: 8),
                      Text('拍照'),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildIntensitySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '冲动强度',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              '$_intensity/5',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _intensity.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: _intensity.toString(),
          activeColor: AppTheme.primaryColor,
          onChanged: (value) => setState(() => _intensity = value.round()),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('微弱', style: TextStyle(fontSize: 12)),
            Text('轻微', style: TextStyle(fontSize: 12)),
            Text('中等', style: TextStyle(fontSize: 12)),
            Text('强烈', style: TextStyle(fontSize: 12)),
            Text('非常强烈', style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildLogsSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_logs.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.menu_book_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              '还没有记录',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '记录你的冲动与应对方式，帮助自己更好地了解自己',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '历史记录',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '长按记录可修改',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
                fontSize: 12,
              ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _logs.length,
          itemBuilder: (context, index) => _buildLogCard(_logs[index]),
        ),
      ],
    );
  }

  Widget _buildLogCard(UrgeLog log) {
    return GestureDetector(
      onLongPress: () => _startEdit(log),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (log.title != null && log.title!.isNotEmpty)
                    Text(
                      log.title!,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatDateTime(log.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getIntensityColor(log.intensity)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '强度 ${log.intensity}/5',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getIntensityColor(log.intensity),
                      ),
                    ),
                  ),
                  if (log.actedOn) const SizedBox(width: 8),
                  if (log.actedOn)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '已行动',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
              if (log.imagePath != null && log.imagePath!.isNotEmpty)
                const SizedBox(height: 12),
              if (log.imagePath != null && log.imagePath!.isNotEmpty)
                GestureDetector(
                  onTap: () => _showFullScreenImage(log.imagePath!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FutureBuilder<bool>(
                      future: File(log.imagePath!).exists(),
                      builder: (context, snapshot) {
                        if (snapshot.data == true) {
                          return Image.file(
                            File(log.imagePath!),
                            height: 80,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildImageErrorPlaceholder(),
                          );
                        }
                        return _buildImageErrorPlaceholder();
                      },
                    ),
                  ),
                ),
              if (log.trigger != null && log.trigger!.isNotEmpty)
                const SizedBox(height: 8),
              if (log.trigger != null && log.trigger!.isNotEmpty)
                _buildLogDetail('诱因', log.trigger!),
              if (log.copingUsed != null && log.copingUsed!.isNotEmpty)
                _buildLogDetail('应对方式', log.copingUsed!),
              if (log.note != null && log.note!.isNotEmpty)
                _buildLogDetail('备注', log.note!),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _startEdit(log),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text('修改'),
                  ),
                  TextButton(
                    onPressed: () => _deleteLog(log.id!),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('删除'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(String imagePath) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  Center(
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.file(
                        File(imagePath),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.broken_image_outlined,
                                color: Colors.white54, size: 64),
                            SizedBox(height: 16),
                            Text('图片无法加载',
                                style: TextStyle(color: Colors.white54)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 24),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageErrorPlaceholder() {
    return Container(
      height: 80,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 28),
      ),
    );
  }

  Widget _buildLogDetail(String label, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
        ),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Color _getIntensityColor(int intensity) {
    switch (intensity) {
      case 1:
        return const Color(0xFFA5D6A7);
      case 2:
        return const Color(0xFF81C7E4);
      case 3:
        return const Color(0xFFFFB74D);
      case 4:
        return const Color(0xFFFF8A65);
      case 5:
        return const Color(0xFFEF5350);
      default:
        return const Color(0xFFA5D6A7);
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
