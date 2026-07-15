import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../models/mood_record.dart';
import '../models/mood_type.dart';
import '../providers/mood_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

/// 绪花园页面
/// 每条情绪记录长出一朵花，花色映射情绪类型
/// 最近7天无记录的花会枯萎（灰色半透明）
/// 花园是情绪旅程的活地图
class MoodGardenPage extends StatefulWidget {
  const MoodGardenPage({super.key});

  @override
  State<MoodGardenPage> createState() => _MoodGardenPageState();
}

class _MoodGardenPageState extends State<MoodGardenPage> {
  List<MoodRecord> _recentRecords = [];
  bool _isLoading = false;
  MoodProvider? _providerRef;

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

                    // 花园概览统计
                    _buildGardenStats(),
                    const SizedBox(height: 20),

                    // 花园画布
                    _buildGardenCanvas(),
                    const SizedBox(height: 24),

                    // 花语解读
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

  /// 花园统计
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

  /// 花园画布 — 用 CustomPainter 绘制花朵
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
          ],
        ),
      ),
    );
  }

  /// 蝴蝶动画
  Widget _buildButterflyAnimation() {
    if (_recentRecords.length < 5) return const SizedBox.shrink();
    
    return const _ButterflyAnimation();
  }

  /// 星星动画（夜间模式）
  Widget _buildStarAnimation() {
    final isDark = context.read<MoodProvider>().isDarkMode;
    if (!isDark || _recentRecords.isEmpty) return const SizedBox.shrink();
    
    return const _StarAnimation();
  }

  /// 花语解读（颜色→情绪对照表）
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
}

/// 花园画笔
class _GardenPainter extends CustomPainter {
  final List<MoodRecord> records;
  final bool isDark;

  _GardenPainter({required this.records, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 背景渐变（天空）
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF0A0D12), const Color(0xFF1A1D24)]
            : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.7));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.7),
      skyPaint,
    );

    // 地面
    final groundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF1A1D24), const Color(0xFF2D3340)]
            : [const Color(0xFFA5D6A7), const Color(0xFF66BB6A)],
      ).createShader(
          Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.3));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.3),
      groundPaint,
    );

    // 按日期分组，同一天的记录排成一行
    final byDay = <String, List<MoodRecord>>{};
    for (final r in records) {
      final key =
          '${r.createdAt.year}-${r.createdAt.month}-${r.createdAt.day}';
      byDay.putIfAbsent(key, () => []).add(r);
    }

    // 按日期排序（最近在上）
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

      // Y 坐标：越近越高
      final yRatio = dayIdx / math.max(totalDays - 1, 7);
      final baseY = gardenBottom - yRatio * gardenHeight;

      // X 坐标：按记录数量均匀分布
      final count = dayRecords.length;
      final spacing = size.width / (count + 1);

      for (int flowerIdx = 0; flowerIdx < count && flowerIdx < 6; flowerIdx++) {
        final record = dayRecords[flowerIdx];
        final flowerX = spacing * (flowerIdx + 1);
        final flowerY = baseY;

        // 花朵大小根据强度
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

        // 茎
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

      // 日期标签
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
    // 花瓣（5片）
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

    // 中心
    final centerPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), size * 0.25, centerPaint);

    // 高光
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
    // 枯萎的花 — 灰色半透明
    final wiltPaint = Paint()
      ..color = (isDark ? const Color(0xFF4A5568) : const Color(0xFFBDBDBD))
          .withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    // 稍微歪斜的花瓣
    for (int i = 0; i < 4; i++) {
      final angle = i * (360 / 4) * math.pi / 180 + 0.2; // 偏斜
      final petalX = x + size * 0.35 * math.cos(angle);
      final petalY = y + size * 0.35 * math.sin(angle);
      canvas.drawCircle(Offset(petalX, petalY), size * 0.25, wiltPaint);
    }

    // 中心
    canvas.drawCircle(
      Offset(x, y),
      size * 0.15,
      Paint()
        ..color = (isDark ? const Color(0xFF4A5568) : const Color(0xFF9E9E9E))
            .withValues(alpha: 0.4)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_GardenPainter oldDelegate) {
    return oldDelegate.records != records || oldDelegate.isDark != isDark;
  }
}

/// 蝴蝶飞舞动画
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

/// 星星闪烁动画（夜间模式）
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
