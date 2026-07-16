import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';

/// 冲突关怀模块
/// 提供情绪冲突时的自我关怀指导图片，支持点击图片全屏查看。
/// 打开页面时自动检查并申请图片读取权限。
class ConflictCarePage extends StatefulWidget {
  const ConflictCarePage({super.key});

  @override
  State<ConflictCarePage> createState() => _ConflictCarePageState();
}

class _ConflictCarePageState extends State<ConflictCarePage> {
  bool _permissionGranted = false;
  bool _checkingPermission = true;

  /// 关怀卡片数据源（占位示例，可替换为实际本地图片路径）
  final List<Map<String, dynamic>> _careCards = [
    {
      'title': '深呼吸',
      'subtitle': '让自己停下来，深呼吸三次',
      'gradient': [const Color(0xFF81D4FA), const Color(0xFF4FC3F7)],
      'icon': Icons.air,
    },
    {
      'title': '自我接纳',
      'subtitle': '允许自己有情绪，不必完美',
      'gradient': [const Color(0xFFCE93D8), const Color(0xFFBA68C8)],
      'icon': Icons.self_improvement,
    },
    {
      'title': '暂时离开',
      'subtitle': '离开冲突场景，给自己空间',
      'gradient': [const Color(0xFFA5D6A7), const Color(0xFF81C784)],
      'icon': Icons.directions_walk,
    },
    {
      'title': '寻求支持',
      'subtitle': '联系信任的人聊聊',
      'gradient': [const Color(0xFFFFCC80), const Color(0xFFFFB74D)],
      'icon': Icons.chat_bubble_outline,
    },
    {
      'title': '写下感受',
      'subtitle': '把情绪写下来，不用发送给任何人',
      'gradient': [const Color(0xFF90CAF9), const Color(0xFF64B5F6)],
      'icon': Icons.edit_note,
    },
    {
      'title': '身体扫描',
      'subtitle': '关注身体的感觉，放松紧绷的部位',
      'gradient': [const Color(0xFFEF9A9A), const Color(0xFFE57373)],
      'icon': Icons.accessibility_new,
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  /// 检查并申请图片/媒体权限
  Future<void> _checkPermission() async {
    setState(() => _checkingPermission = true);

    final status = await _resolvePhotoPermission();

    if (status.isGranted) {
      setState(() {
        _permissionGranted = true;
        _checkingPermission = false;
      });
      return;
    }

    if (status.isPermanentlyDenied) {
      // 用户已永久拒绝，引导去设置
      setState(() => _checkingPermission = false);
      _showGoToSettingsDialog();
      return;
    }

    // 请求权限
    final result = await _resolvePhotoPermission(request: true);
    setState(() {
      _permissionGranted = result.isGranted;
      _checkingPermission = false;
    });

    if (!result.isGranted) {
      _showPermissionDeniedDialog();
    }
  }

  /// 根据平台返回合适的照片权限
  Future<PermissionStatus> _resolvePhotoPermission({bool request = false}) async {
    if (Platform.isAndroid) {
      // Android 13+ 使用 READ_MEDIA_IMAGES
      final photos = Permission.photos;
      if (request) {
        return await photos.request();
      }
      return await photos.status;
    } else if (Platform.isIOS) {
      final photos = Permission.photos;
      if (request) {
        return await photos.request();
      }
      return await photos.status;
    }
    return PermissionStatus.granted;
  }

  /// 权限被拒绝时的提示
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('需要图片权限'),
        content: const Text(
          '冲突关怀模块需要访问相册权限来加载关怀图片。'
          '你可以在设置中随时开启。',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('稍后再说'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _checkPermission();
            },
            child: const Text('重新申请'),
          ),
        ],
      ),
    );
  }

  /// 永久拒绝时引导去系统设置
  void _showGoToSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('权限已被永久拒绝'),
        content: const Text(
          '你需要在系统设置中手动开启相册权限，'
          '冲突关怀模块才能正常加载图片。',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  /// 打开图片全屏查看
  void _openImageViewer(Map<String, dynamic> card) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CareImageViewer(card: card),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('冲突关怀'),
        actions: [
          if (!_permissionGranted && !_checkingPermission)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _checkPermission,
              tooltip: '重新检查权限',
            ),
        ],
      ),
      body: _checkingPermission
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildGrid(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFCDD2).withValues(alpha: 0.6),
            const Color(0xFFF8BBD0).withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE57373).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('🤝', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '当你感到冲突时',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '点击图片查看关怀指导，'
                      '不必急着解决问题，先照顾好自己',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryOf(context),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!_permissionGranted) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 18, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '图片权限未开启，部分功能可能受限',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _checkPermission,
                    child: const Text('开启'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _careCards.length,
      itemBuilder: (context, index) {
        final card = _careCards[index];
        return _buildCareCard(card);
      },
    );
  }

  Widget _buildCareCard(Map<String, dynamic> card) {
    final gradient = card['gradient'] as List<Color>;
    final icon = card['icon'] as IconData;
    final title = card['title'] as String;
    final subtitle = card['subtitle'] as String;

    return GestureDetector(
      onTap: () => _openImageViewer(card),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient[1].withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openImageViewer(card),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '点击查看',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 图片全屏查看器（使用 photo_view）
class _CareImageViewer extends StatelessWidget {
  final Map<String, dynamic> card;

  const _CareImageViewer({required this.card});

  @override
  Widget build(BuildContext context) {
    final gradient = card['gradient'] as List<Color>;
    final icon = card['icon'] as IconData;
    final title = card['title'] as String;
    final subtitle = card['subtitle'] as String;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PhotoView(
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2.5,
        initialScale: PhotoViewComputedScale.contained,
        imageProvider: _GradientImageProvider(
          gradient: gradient,
          icon: icon,
          title: title,
          subtitle: subtitle,
        ),
      ),
    );
  }
}

/// 自定义 ImageProvider，将渐变卡片渲染为可查看的图片
class _GradientImageProvider extends ImageProvider<_GradientImageProvider> {
  final List<Color> gradient;
  final IconData icon;
  final String title;
  final String subtitle;

  const _GradientImageProvider({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Future<_GradientImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_GradientImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _GradientImageProvider key,
    ImageDecoderCallback decode,
  ) {
    final stream = ImageStreamController();
    _loadImage(stream, decode);
    return stream;
  }

  Future<void> _loadImage(
    ImageStreamController stream,
    ImageDecoderCallback decode,
  ) async {
    try {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(800, 1200);

      // 绘制渐变背景
      final paint = Paint()
        ..shader = LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

      // 绘制图标
      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: 180,
            fontFamily: icon.fontFamily,
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          size.height * 0.25,
        ),
      );

      // 绘制标题
      final titlePainter = TextPainter(
        text: TextSpan(
          text: title,
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      titlePainter.layout(maxWidth: size.width - 80);
      titlePainter.paint(
        canvas,
        Offset(
          (size.width - titlePainter.width) / 2,
          size.height * 0.55,
        ),
      );

      // 绘制副标题
      final subtitlePainter = TextPainter(
        text: TextSpan(
          text: subtitle,
          style: TextStyle(
            fontSize: 32,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      subtitlePainter.layout(maxWidth: size.width - 80);
      subtitlePainter.paint(
        canvas,
        Offset(
          (size.width - subtitlePainter.width) / 2,
          size.height * 0.55 + titlePainter.height + 20,
        ),
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final codec = await decode(await ImmutableBuffer.fromUint8List(bytes));
      final frame = await codec.getNextFrame();
      stream.setImage(frame.image);
    } catch (e) {
      stream.setError(e, StackTrace.current);
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is _GradientImageProvider &&
        other.gradient == gradient &&
        other.icon == icon &&
        other.title == title &&
        other.subtitle == subtitle;
  }

  @override
  int get hashCode => Object.hash(gradient, icon, title, subtitle);
}
