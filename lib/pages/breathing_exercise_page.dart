import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/mood_type.dart';
import '../providers/mood_provider.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';

/// 呼吸阶段
enum BreathPhase {
  inhale, // 吸气
  holdIn, // 屏息（吸气后）
  exhale, // 呼气
  holdOut, // 屏息（呼气后）
}

/// 呼吸练习页面
/// 交互式呼吸动画 — 花瓣开合引导深呼吸放松
/// 支持 4-4-4-4 方块呼吸法（吸气-屏息-呼气-屏息各4秒）
/// 完成后可选记录一条「平静」情绪
class BreathingExercisePage extends StatefulWidget {
  const BreathingExercisePage({super.key});

  @override
  State<BreathingExercisePage> createState() => _BreathingExercisePageState();
}

class _BreathingExercisePageState extends State<BreathingExercisePage> {
  // 状态
  bool _isRunning = false;
  bool _isCompleted = false;
  BreathPhase _phase = BreathPhase.inhale;
  int _remainingSeconds = 4;
  int _cycleCount = 0;
  int _totalCycles = 4; // 默认4个循环
  double _breathScale = 0.5; // 动画缩放 0.5~1.0
  Timer? _timer;

  // 颜色
  static const _phaseColors = {
    BreathPhase.inhale: Color(0xFF8BE9C1), // 绿 — 吸气
    BreathPhase.holdIn: Color(0xFF9575CD), // 紫 — 屏息
    BreathPhase.exhale: Color(0xFF81C7E4), // 蓝 — 呼气
    BreathPhase.holdOut: Color(0xFFFFB74D), // 橙 — 屏息
  };

  static const _phaseLabels = {
    BreathPhase.inhale: '吸气',
    BreathPhase.holdIn: '屏息',
    BreathPhase.exhale: '呼气',
    BreathPhase.holdOut: '屏息',
  };

  static const _phaseHints = {
    BreathPhase.inhale: '缓缓深吸...',
    BreathPhase.holdIn: '保持...',
    BreathPhase.exhale: '慢慢释放...',
    BreathPhase.holdOut: '安静等待...',
  };

  // 每个阶段的持续时间（秒）
  static const _phaseDuration = {
    BreathPhase.inhale: 4,
    BreathPhase.holdIn: 4,
    BreathPhase.exhale: 4,
    BreathPhase.holdOut: 4,
  };

  // 花瓣路径相位（用于花瓣动画）
  double _petalRotation = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startExercise() {
    setState(() {
      _isRunning = true;
      _isCompleted = false;
      _phase = BreathPhase.inhale;
      _remainingSeconds = _phaseDuration[BreathPhase.inhale]!;
      _cycleCount = 0;
      _breathScale = 0.5;
    });
    _tick();
  }

  void _tick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;

        // 更新呼吸动画缩放
        _updateBreathScale();

        if (_remainingSeconds <= 0) {
          _advancePhase();
        }
      });
    });
  }

  void _updateBreathScale() {
    final totalSec = _phaseDuration[_phase]!;
    final progress = 1 - (_remainingSeconds / totalSec);

    switch (_phase) {
      case BreathPhase.inhale:
        _breathScale = 0.5 + 0.5 * progress; // 0.5 → 1.0
        _petalRotation = progress * 30; // 花瓣展开
        break;
      case BreathPhase.holdIn:
        _breathScale = 1.0; // 保持满
        break;
      case BreathPhase.exhale:
        _breathScale = 1.0 - 0.5 * progress; // 1.0 → 0.5
        _petalRotation = 30 - progress * 30; // 花瓣收拢
        break;
      case BreathPhase.holdOut:
        _breathScale = 0.5; // 保持空
        break;
    }
  }

  void _advancePhase() {
    final phases = BreathPhase.values;
    final currentIdx = phases.indexOf(_phase);
    final nextIdx = currentIdx + 1;

    if (nextIdx >= phases.length) {
      // 一个循环完成
      _cycleCount++;
      if (_cycleCount >= _totalCycles) {
        _completeExercise();
        return;
      }
      _phase = BreathPhase.inhale;
    } else {
      _phase = phases[nextIdx];
    }
    _remainingSeconds = _phaseDuration[_phase]!;
  }

  void _completeExercise() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isCompleted = true;
      _breathScale = 0.75;
    });
  }

  void _stopExercise() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _breathScale = 0.5;
    });
  }

  Future<void> _recordCalm() async {
    final provider = context.read<MoodProvider>();
    await provider.addRecord(
      moodType: MoodType.calm,
      intensity: 3,
      note: '完成呼吸练习 · ${_totalCycles}个循环',
      tags: ['呼吸练习'],
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('已记录：呼吸练习 · 平静 😌'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final phaseColor = _phaseColors[_phase] ?? const Color(0xFF8BE9C1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('呼吸练习'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: _isCompleted
            ? _buildCompletedView()
            : Column(
                children: [
                  const Spacer(flex: 1),
                  // 核心呼吸动画
                  _buildBreathAnimation(phaseColor),
                  const Spacer(flex: 1),
                  // 阶段指示器
                  if (_isRunning) _buildPhaseIndicator(phaseColor),
                  // 进度 & 计数
                  if (_isRunning) _buildProgressInfo(),
                  // 按钮
                  _buildControls(),
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }

  /// 核心呼吸动画 — 花瓣开合
  Widget _buildBreathAnimation(Color phaseColor) {
    return AnimatedScale(
      scale: _breathScale,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
      child: SizedBox(
        width: 240,
        height: 240,
        child: CustomPaint(
          painter: _BreathFlowerPainter(
            phaseColor: phaseColor,
            petalOpenness: _breathScale,
            rotation: _petalRotation,
          ),
        ),
      ),
    );
  }

  /// 阶段指示器
  Widget _buildPhaseIndicator(Color phaseColor) {
    final label = _phaseLabels[_phase] ?? '';
    final hint = _phaseHints[_phase] ?? '';

    return Column(
      children: [
        // 大标签
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: phaseColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: phaseColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hint,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryOf(context),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_remainingSeconds}s',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w300,
            color: phaseColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  /// 进度信息
  Widget _buildProgressInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 12),
      child: Row(
        children: [
          // 四阶段进度点
          for (final phase in BreathPhase.values)
            Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: BreathPhase.values.indexOf(phase) <=
                          BreathPhase.values.indexOf(_phase)
                      ? _phaseColors[phase]!.withValues(alpha: 0.8)
                      : AppTheme.dividerOf(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 控制按钮
  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _isRunning
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _stopExercise,
                    icon: const Icon(Icons.stop),
                    label: const Text('停止'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '第 ${_cycleCount + 1} / ${_totalCycles} 循环',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryOf(context),
                        ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                // 循环数选择
                if (!_isRunning && !_isCompleted)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '循环次数：',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 12),
                      for (final count in [2, 4, 6])
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: ChoiceChip(
                            label: Text('$count'),
                            selected: _totalCycles == count,
                            selectedColor:
                                AppTheme.primaryColor.withValues(alpha: 0.2),
                            onSelected: (_) {
                              setState(() {
                                _totalCycles = count;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                if (!_isRunning && !_isCompleted)
                  const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startExercise,
                    icon: const Icon(Icons.air, size: 22),
                    label: const Text('开始呼吸练习'),
                  ),
                ),
                const SizedBox(height: 12),
                // 说明文字
                Text(
                  '方块呼吸法：吸气 4s → 屏息 4s → 呼气 4s → 屏息 4s\n适合焦虑、紧张时放松身心',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textHintOf(context),
                      ),
                ),
              ],
            ),
    );
  }

  /// 完成后的庆祝视图
  Widget _buildCompletedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 完成动画
            const Text(
              '🌸',
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 24),
            Text(
              '练习完成！',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF8BE9C1),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '你完成了 ${_totalCycles} 个呼吸循环',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondaryOf(context),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '方寸之间，心归宁静',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textHintOf(context),
                  ),
            ),
            const SizedBox(height: 40),
            // 记录按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _recordCalm,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('记录这次练习 · 😌 平静'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8BE9C1),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 花瓣呼吸动画画笔
class _BreathFlowerPainter extends CustomPainter {
  final Color phaseColor;
  final double petalOpenness; // 0.5~1.0
  final double rotation; // 花瓣旋转角度

  _BreathFlowerPainter({
    required this.phaseColor,
    required this.petalOpenness,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.18;
    final petalLength = baseRadius * petalOpenness * 1.8;

    // 外圈光晕
    final glowPaint = Paint()
      ..color = phaseColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * 0.45 * petalOpenness, glowPaint);

    // 8片花瓣
    const petalCount = 8;
    for (int i = 0; i < petalCount; i++) {
      final angle = (i * 360 / petalCount) + rotation;
      final radians = angle * 3.14159 / 180;

      final petalPath = Path();
      final tipX = center.dx + petalLength * math.cos(radians);
      final tipY = center.dy + petalLength * math.sin(radians);

      // 花瓣宽度随开合变化
      final petalWidth = baseRadius * 0.35 * petalOpenness;
      final perpAngle = radians + math.pi / 2;

      final leftX = center.dx +
          (baseRadius * 0.3) * math.cos(radians) +
          petalWidth * math.cos(perpAngle);
      final leftY = center.dy +
          (baseRadius * 0.3) * math.sin(radians) +
          petalWidth * math.sin(perpAngle);
      final rightX = center.dx +
          (baseRadius * 0.3) * math.cos(radians) -
          petalWidth * math.cos(perpAngle);
      final rightY = center.dy +
          (baseRadius * 0.3) * math.sin(radians) -
          petalWidth * math.sin(perpAngle);

      petalPath.moveTo(center.dx, center.dy);
      petalPath.quadraticBezierTo(leftX, leftY, tipX, tipY);
      petalPath.quadraticBezierTo(rightX, rightY, center.dx, center.dy);

      // 花瓣渐变
      final petalPaint = Paint()
        ..color = phaseColor.withValues(alpha: 0.3 + 0.4 * (i % 2))
        ..style = PaintingStyle.fill;

      canvas.drawPath(petalPath, petalPaint);
    }

    // 中心圆
    final centerPaint = Paint()
      ..color = phaseColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, baseRadius * 0.35, centerPaint);

    // 中心高光
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(center.dx - baseRadius * 0.08, center.dy - baseRadius * 0.08),
      baseRadius * 0.15,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(_BreathFlowerPainter oldDelegate) {
    return oldDelegate.petalOpenness != petalOpenness ||
        oldDelegate.phaseColor != phaseColor ||
        oldDelegate.rotation != rotation;
  }
}
