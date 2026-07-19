import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 冲突关怀模块
/// 提供情绪冲突时的自我关怀指导卡片，支持点击全屏查看。
class ConflictCarePage extends StatefulWidget {
  const ConflictCarePage({super.key});

  @override
  State<ConflictCarePage> createState() => _ConflictCarePageState();
}

class _ConflictCarePageState extends State<ConflictCarePage> {
  /// 关怀卡片数据源
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
      ),
      body: _buildBody(),
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
                      '点击卡片查看关怀指导，'
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

/// 图片全屏查看器（使用 InteractiveViewer，无需第三方依赖）
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
      body: Stack(
        children: [
          InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: _buildGradientCard(gradient, icon, title, subtitle),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
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
    );
  }

  Widget _buildGradientCard(
      List<Color> gradient, IconData icon, String title, String subtitle) {
    return Container(
      width: 320,
      height: 480,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.3), size: 120),
          const SizedBox(height: 32),
          Text(
            title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
