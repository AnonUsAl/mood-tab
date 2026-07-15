import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import '../models/mood_record.dart';
import '../models/mood_type.dart';
import '../providers/mood_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

/// 情绪花园页面
/// 每条情绪记录长出一朵花，花色映射情绪类型
/// 最近7天无记录的花会枯萎（灰色半透明）
/// 花园是情绪旅程的活地图
class MoodGardenPage extends StatefulWidget {
  const MoodGardenPage({super.key});

  @override
  State<MoodGardenPage> createState() => _MoodGardenPageState();
}

/// 画笔类型
enum BrushType {
  pen,
  eraser,
}



/// 一笔涂鸦数据
class Stroke {
  final List<Offset> points;
  final Color color;
  final double size;
  final BrushType brushType;

  Stroke({
    required this.points,
    required this.color,
    required this.size,
    required this.brushType,
  });
}

class _MoodGardenPageState extends State<MoodGardenPage> {
  List<MoodRecord> _recentRecords = [];
  bool _isLoading = false;
  MoodProvider? _providerRef;

  BrushType _brushType = BrushType.pen;
  Color _brushColor = Colors.pink;
  double _brushSize = 4.0;
  List<Stroke> _strokes = [];
  List<Offset> _currentPoints = [];

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

  void _startDrawing(Offset point) {
    setState(() {
      _currentPoints = [point];
    });
  }

  void _draw(Offset point) {
    if (_currentPoints.isEmpty) return;
    setState(() {
      _currentPoints.add(point);
    });
  }

  void _endDrawing() {
    if (_currentPoints.length >= 2) {
      setState(() {
        _strokes.add(Stroke(
          points: List.from(_currentPoints),
          color: _brushColor,
          size: _brushSize,
          brushType: _brushType,
        ));
        _currentPoints = [];
      });
    }
  }

  void _clearDrawing() {
    setState(() {
      _strokes = [];
      _currentPoints = [];
    });
  }

  void _undoDrawing() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });
    }
  }

  void _toggleEraser() {
    setState(() {
      _brushType = _brushType == BrushType.pen ? BrushType.eraser : BrushType.pen;
    });
  }

  void _onProviderChanged() {
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final provider = context.read<MoodProvider>();
    _recentRecords = await provider.getRecentRecords(30);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('情绪花园'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Consumer<MoodProvider>(
          builder: (context, provider, _) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_recentRecords.isEmpty) {
              return const EmptyState(
                emoji: '🌱',
                title: '花园还是一片空地',
                subtitle: '记录情绪后，这里会开出属于你的花',
              );
            }

            return RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '情绪花园',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '你的每一段心情，都是一朵花',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondaryOf(context),
                          ),
                    ),
                    const SizedBox(height: 24),

                    _buildGardenStats(),
                    const SizedBox(height: 20),

                    _buildGardenCanvas(),
                    const SizedBox(height: 16),

                    _buildDrawingToolbar(),
                    const SizedBox(height: 24),

                    _buildFlowerLegend(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGardenStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bloomingCount = _recentRecords.where((r) {
      final diff = today.difference(DateTime(
        r.createdAt.year,
        r.createdAt.month,
        r.createdAt.day,
      ));
      return diff.inDays < 7;
    }).length;
    final wiltingCount = _recentRecords.length - bloomingCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildStatItem('🌸', '$bloomingCount', '绽放中'),
          const SizedBox(width: 24),
          _buildStatItem('🥀', '$wiltingCount', '已凋零'),
          const SizedBox(width: 24),
          _buildStatItem('🌱', '${_recentRecords.length}', '总花朵'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryOf(context),
              ),
        ),
      ],
    );
  }

  Widget _buildGardenCanvas() {
    return Container(
      height: 380,
      decoration: BoxDecoration(
        color: AppTheme.cardBgOf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            CustomPaint(
              painter: _GardenPainter(
                records: _recentRecords,
                isDark: context.read<MoodProvider>().isDarkMode,
              ),
            ),
            _buildButterflyAnimation(),
            _buildStarAnimation(),
            _buildDrawingLayer(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawingLayer() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) {
        final renderBox = context.findRenderObject() as RenderBox;
        final point = renderBox.globalToLocal(details.globalPosition);
        _startDrawing(point);
      },
      onPanUpdate: (details) {
        final renderBox = context.findRenderObject() as RenderBox;
        final point = renderBox.globalToLocal(details.globalPosition);
        _draw(point);
      },
      onPanEnd: (_) {
        _endDrawing();
      },
      onVerticalDragStart: (_) {},
      onHorizontalDragStart: (_) {},
      onVerticalDragUpdate: (_) {},
      onHorizontalDragUpdate: (_) {},
      onVerticalDragEnd: (_) {},
      onHorizontalDragEnd: (_) {},
      child: CustomPaint(
        painter: _DrawingPainter(
          strokes: _strokes,
          currentPoints: _currentPoints,
          currentColor: _brushColor,
          currentSize: _brushSize,
          currentBrushType: _brushType,
          bgColor: context.read<MoodProvider>().isDarkMode
              ? const Color(0xFF1A2332)
              : const Color(0xFFF0FDF4),
        ),
      ),
    );
  }

  Widget _buildButterflyAnimation() {
    if (_recentRecords.length < 5) return const SizedBox.shrink();
    return const _ButterflyAnimation();
  }

  Widget _buildStarAnimation() {
    final isDark = context.read<MoodProvider>().isDarkMode;
    if (!isDark || _recentRecords.isEmpty) return const SizedBox.shrink();
    return const _StarAnimation();
  }

  Widget _buildFlowerLegend() {
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
            '花语解读',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: MoodType.values.map((mood) {
              return _buildLegendItem(mood);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(MoodType mood) {
    final color = Color(mood.colorValue);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${mood.emoji} ${mood.label}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildDrawingToolbar() {
    final colors = [
      Colors.pink,
      Colors.pinkAccent,
      Colors.orange,
      Colors.orangeAccent,
      Colors.yellow,
      Colors.yellowAccent,
      Colors.green,
      Colors.greenAccent,
      Colors.blue,
      Colors.blueAccent,
      Colors.purple,
      Colors.purpleAccent,
      Colors.red,
      Colors.redAccent,
      Colors.cyan,
      Colors.cyanAccent,
      Colors.white,
      Colors.black,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBgOf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🎨 涂鸦',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Row(
                children: [
                  _buildToolButton(
                    icon: Icons.undo,
                    label: '撤销',
                    onPressed: _strokes.isNotEmpty ? _undoDrawing : null,
                  ),
                  const SizedBox(width: 8),
                  _buildToolButton(
                    icon: Icons.clear,
                    label: '清空',
                    onPressed: _strokes.isNotEmpty ? _clearDrawing : null,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: colors.map((color) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _brushColor = color;
                    _brushType = BrushType.pen;
                  });
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _brushColor == color && _brushType == BrushType.pen
                          ? AppTheme.primaryColor
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: _brushColor == color && _brushType == BrushType.pen
                        ? [const BoxShadow(blurRadius: 4)]
                        : [],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              const Text('粗细'),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _brushSize,
                  min: 2,
                  max: 20,
                  divisions: 9,
                  onChanged: (value) => setState(() => _brushSize = value),
                  activeColor: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _brushType == BrushType.eraser
                      ? Colors.grey.withValues(alpha: 0.3)
                      : _brushColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Container(
                  width: _brushSize,
                  height: _brushSize,
                  decoration: BoxDecoration(
                    color: _brushType == BrushType.eraser
                        ? Colors.white
                        : Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildToolButton(
                icon: _brushType == BrushType.eraser
                    ? Icons.brush
                    : Icons.edit,
                label: _brushType == BrushType.eraser ? '画笔' : '橡皮',
                onPressed: _toggleEraser,
                isActive: _brushType == BrushType.eraser,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isActive = false,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          color: isActive ? AppTheme.primaryColor : (onPressed != null ? null : Colors.grey),
          disabledColor: Colors.grey,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isActive ? AppTheme.primaryColor : (onPressed != null ? null : Colors.grey),
              ),
        ),
      ],
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentSize;
  final BrushType currentBrushType;
  final Color bgColor;

  _DrawingPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentSize,
    required this.currentBrushType,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    if (currentPoints.length >= 2) {
      _drawStroke(canvas, Stroke(
        points: currentPoints,
        color: currentColor,
        size: currentSize,
        brushType: currentBrushType,
      ));
    }
  }

  void _drawStroke(Canvas canvas, Stroke stroke) {
    final paint = Paint()
      ..strokeWidth = stroke.size
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (stroke.brushType == BrushType.eraser) {
      paint
        ..color = bgColor
        ..blendMode = BlendMode.src;
    } else {
      paint.color = stroke.color;
    }

    if (stroke.points.length >= 2) {
      final path = ui.Path()..moveTo(stroke.points[0].dx, stroke.points[0].dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_DrawingPainter oldDelegate) {
    return oldDelegate.strokes.length != strokes.length ||
        oldDelegate.currentPoints != currentPoints ||
        oldDelegate.currentColor != currentColor ||
        oldDelegate.currentSize != currentSize ||
        oldDelegate.currentBrushType != currentBrushType;
  }
}

class _GardenPainter extends CustomPainter {
  final List<MoodRecord> records;
  final bool isDark;

  _GardenPainter({required this.records, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF0F172A), const Color(0xFF1A2744)]
            : [const Color(0xFFDCFCE7), const Color(0xFFBBF7D0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      skyPaint,
    );

    _drawCamouflagePattern(canvas, size);

    final groundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF1E3A3A), const Color(0xFF152E2E)]
            : [const Color(0xFF86EFAC), const Color(0xFF4ADE80)],
      ).createShader(
          Rect.fromLTWH(0, size.height * 0.65, size.width, size.height * 0.35));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.65, size.width, size.height * 0.35),
      groundPaint,
    );

    final byDay = <String, List<MoodRecord>>{};
    for (final r in records) {
      final key =
          '${r.createdAt.year}-${r.createdAt.month}-${r.createdAt.day}';
      byDay.putIfAbsent(key, () => []).add(r);
    }

    final days = byDay.keys.toList().reversed.toList();
    final totalDays = days.length;
    final gardenTop = size.height * 0.15;
    final gardenBottom = size.height * 0.68;
    final gardenHeight = gardenBottom - gardenTop;

    for (int dayIdx = 0; dayIdx < totalDays && dayIdx < 8; dayIdx++) {
      final dayRecords = byDay[days[dayIdx]]!;
      final dayDate = DateTime.parse(days[dayIdx]);
      final daysSinceRecord = today.difference(DateTime(
        dayDate.year,
        dayDate.month,
        dayDate.day,
      ));
      final isWilting = daysSinceRecord.inDays >= 7;

      final yRatio = dayIdx / math.max(totalDays - 1, 7);
      final baseY = gardenBottom - yRatio * gardenHeight;

      final count = dayRecords.length;
      final spacing = size.width / (count + 1);

      for (int flowerIdx = 0; flowerIdx < count && flowerIdx < 6; flowerIdx++) {
        final record = dayRecords[flowerIdx];
        final flowerX = spacing * (flowerIdx + 1);
        final flowerY = baseY;

        final flowerSize = 14.0 + record.intensity * 4.0;

        if (isWilting) {
          _drawWiltingFlower(canvas, flowerX, flowerY, flowerSize);
        } else {
          _drawBloomingFlower(
            canvas,
            flowerX,
            flowerY,
            flowerSize,
            Color(record.moodType.colorValue),
            record.moodType.emoji,
          );
        }

        final stemPaint = Paint()
          ..color = isWilting
              ? (isDark ? const Color(0xFF4A5568) : const Color(0xFF9E9E9E))
              : (isDark ? const Color(0xFF66BB6A) : const Color(0xFF4CAF50))
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(flowerX, flowerY),
          Offset(flowerX, flowerY + flowerSize * 2.5),
          stemPaint,
        );
      }

      final labelPaint = TextPainter(
        text: TextSpan(
          text: '${dayDate.month}/${dayDate.day}',
          style: TextStyle(
            fontSize: 10,
            color: isWilting
                ? (isDark ? const Color(0xFF6B7280) : const Color(0xFF9E9E9E))
                : (isDark ? const Color(0xFFB0BEC5) : const Color(0xFF607D8B)),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPaint.layout();
      labelPaint.paint(
        canvas,
        Offset(8, baseY - 8),
      );
    }
  }

  void _drawBloomingFlower(
    Canvas canvas,
    double x,
    double y,
    double size,
    Color color,
    String emoji,
  ) {
    const petalCount = 5;
    final petalPaint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < petalCount; i++) {
      final angle = i * (360 / petalCount) * math.pi / 180;
      final petalX = x + size * 0.4 * math.cos(angle);
      final petalY = y + size * 0.4 * math.sin(angle);

      canvas.drawCircle(Offset(petalX, petalY), size * 0.35, petalPaint);
    }

    final centerPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), size * 0.25, centerPaint);

    final hlPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(x - size * 0.08, y - size * 0.08),
      size * 0.12,
      hlPaint,
    );
  }

  void _drawWiltingFlower(Canvas canvas, double x, double y, double size) {
    final wiltPaint = Paint()
      ..color = (isDark ? const Color(0xFF4A5568) : const Color(0xFFBDBDBD))
          .withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final angle = i * (360 / 4) * math.pi / 180 + 0.2;
      final petalX = x + size * 0.35 * math.cos(angle);
      final petalY = y + size * 0.35 * math.sin(angle);
      canvas.drawCircle(Offset(petalX, petalY), size * 0.25, wiltPaint);
    }

    canvas.drawCircle(
      Offset(x, y),
      size * 0.15,
      Paint()
        ..color = (isDark ? const Color(0xFF4A5568) : const Color(0xFF9E9E9E))
            .withValues(alpha: 0.4)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawCamouflagePattern(Canvas canvas, Size size) {
    final patternColors = isDark
        ? [
            const Color(0xFF1E3A3A).withValues(alpha: 0.3),
            const Color(0xFF152E2E).withValues(alpha: 0.2),
            const Color(0xFF2D4A4A).withValues(alpha: 0.25),
          ]
        : [
            const Color(0xFFBBF7D0).withValues(alpha: 0.4),
            const Color(0xFF86EFAC).withValues(alpha: 0.3),
            const Color(0xFF4ADE80).withValues(alpha: 0.25),
          ];

    final random = math.Random(12345);

    for (int i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.6;
      final radius = 15 + random.nextDouble() * 30;
      final color = patternColors[i % patternColors.length];

      canvas.drawCircle(Offset(x, y), radius, Paint()..color = color);
    }

    for (int i = 0; i < 10; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.6;
      final width = 20 + random.nextDouble() * 40;
      final height = 10 + random.nextDouble() * 20;
      final angle = random.nextDouble() * math.pi * 2;
      final color = patternColors[i % patternColors.length];

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromLTWH(-width / 2, -height / 2, width, height),
        Paint()..color = color,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_GardenPainter oldDelegate) {
    return oldDelegate.records != records || oldDelegate.isDark != isDark;
  }
}

class _ButterflyAnimation extends StatefulWidget {
  const _ButterflyAnimation();

  @override
  State<_ButterflyAnimation> createState() => _ButterflyAnimationState();
}

class _ButterflyAnimationState extends State<_ButterflyAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _xAnimation;
  late Animation<double> _yAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _xAnimation = Tween<double>(begin: 0.1, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _yAnimation = Tween<double>(begin: 0.2, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 1)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 1)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: MediaQuery.of(context).size.width * _xAnimation.value,
          top: 380 * _yAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: const Text(
              '🦋',
              style: TextStyle(fontSize: 24),
            ),
          ),
        );
      },
    );
  }
}

class _StarAnimation extends StatefulWidget {
  const _StarAnimation();

  @override
  State<_StarAnimation> createState() => _StarAnimationState();
}

class _StarAnimationState extends State<_StarAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildStar(0.15, 0.1, 1.0),
        _buildStar(0.35, 0.15, 0.7),
        _buildStar(0.55, 0.08, 0.9),
        _buildStar(0.75, 0.12, 0.6),
        _buildStar(0.85, 0.18, 0.8),
      ],
    );
  }

  Widget _buildStar(double left, double top, double delay) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = (math.sin(_controller.value * math.pi * 2 + delay) + 1) / 2;
        return Positioned(
          left: MediaQuery.of(context).size.width * left,
          top: 380 * top,
          child: Opacity(
            opacity: opacity * 0.8,
            child: const Text('⭐', style: TextStyle(fontSize: 12)),
          ),
        );
      },
    );
  }
}
