import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 暖心寄语页面
/// 为精神类疾病患者提供科学认知与温暖支持
class WarmWordsPage extends StatefulWidget {
  const WarmWordsPage({super.key});

  @override
  State<WarmWordsPage> createState() => _WarmWordsPageState();
}

class _WarmWordsPageState extends State<WarmWordsPage> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('暖心寄语'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 24),
              Text(
                '致每一位正在努力的你',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '点击下方卡片了解更多',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryOf(context),
                    ),
              ),
              const SizedBox(height: 16),
              ..._warmMessages.asMap().entries.map((entry) {
                final index = entry.key;
                final msg = entry.value;
                return _buildConditionCard(index, msg);
              }),
              const SizedBox(height: 24),
              _buildFooterCard(),
            ],
          ),
        ),
      ),
    );
  }

  /// 顶部渐变卡片
  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7E57C2), Color(0xFF9575CD)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🫂', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            '你并不孤单',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            '无论你正在经历什么，都值得被温柔以待。\n'
            '了解它，才能更好地与自己相处。',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  /// 疾病寄语卡片
  Widget _buildConditionCard(int index, _WarmMessage msg) {
    final isExpanded = _expandedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBgOf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _expandedIndex = isExpanded ? null : index;
            });
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: msg.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(msg.emoji, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.condition,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            msg.subtitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondaryOf(context),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppTheme.textHintOf(context),
                    ),
                  ],
                ),
              ),
              if (isExpanded) ...[
                Divider(
                  height: 1,
                  color: AppTheme.dividerOf(context),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 科普一下
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: msg.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.auto_stories, size: 16, color: msg.color),
                                const SizedBox(width: 6),
                                Text(
                                  '科普一下',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: msg.color,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              msg.science,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    height: 1.7,
                                    color: AppTheme.textPrimaryOf(context),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 安慰支持
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: msg.color.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: msg.color.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.favorite, size: 16, color: msg.color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                msg.comfort,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: msg.color,
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 底部温馨提示
  Widget _buildFooterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                '温馨提示',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...[
            '脑电波 仅为情绪记录工具，不能替代专业的医疗诊断与治疗',
            '如果你正在服药，请遵医嘱按时服用，不要自行减药或停药',
            '定期复诊，与你的医生保持沟通，你们是同一个团队',
            '感到撑不下去的时候，拨打心理援助热线 12356 是勇敢的表现',
          ].map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('·',
                        style: TextStyle(
                            fontSize: 16, color: AppTheme.primaryColor)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textPrimaryOf(context),
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

/// 寄语数据模型
class _WarmMessage {
  final String emoji;
  final String condition;
  final String subtitle;
  final Color color;
  final String science;  // 简短科普 (~50-100字)
  final String comfort;  // 安慰支持 (~30字)

  const _WarmMessage({
    required this.emoji,
    required this.condition,
    required this.subtitle,
    required this.color,
    required this.science,
    required this.comfort,
  });
}

/// 寄语内容
const List<_WarmMessage> _warmMessages = [
  _WarmMessage(
    emoji: '🌊',
    condition: '双相情感障碍',
    subtitle: '在躁狂与抑郁的浪潮中寻找平衡',
    color: Color(0xFF7E57C2),
    science: '双相情感障碍是一种以情绪极端波动为特征的精神疾病，患者在躁狂期精力旺盛、思维奔涌，在抑郁期则情绪低落、精力匮乏，两种状态交替或混合出现。',
    comfort: '在浪潮之间寻找平衡，这本身就是了不起的勇气。',
  ),
  _WarmMessage(
    emoji: '🌧️',
    condition: '抑郁症',
    subtitle: '穿过那片灰色的迷雾',
    color: Color(0xFF5C6BC0),
    science: '抑郁症并非简单的"心情不好"，而是大脑神经递质失衡导致的持续情绪低落，核心症状包括兴趣丧失、精力减退和自我评价降低，严重时可出现自杀念头。',
    comfort: '哪怕今天只是从床上起来喝了杯水，那也是胜利。',
  ),
  _WarmMessage(
    emoji: '💨',
    condition: '焦虑症',
    subtitle: '当担忧成为一种习惯',
    color: Color(0xFF26A69A),
    science: '焦虑症是大脑杏仁核过度激活的结果，它把"万一"当成"一定"，让身体持续处于"战斗或逃跑"的警报状态，表现为心跳加速、呼吸急促和无法控制的担忧。',
    comfort: '警报响了不代表真的有危险，你此刻是安全的。',
  ),
  _WarmMessage(
    emoji: '🔄',
    condition: '强迫症',
    subtitle: '与反复出现的念头共处',
    color: Color(0xFFEC407A),
    science: '强迫症的特征是反复出现的侵入性念头（强迫思维）和不得不执行的重复行为（强迫行为），大脑试图通过仪式化的重复来获得安全感，但效果短暂且形成恶性循环。',
    comfort: '念头只是念头，不代表你的本心，你比它强大得多。',
  ),
  _WarmMessage(
    emoji: '🛡️',
    condition: '创伤后应激障碍',
    subtitle: '从过去的阴影中走向光',
    color: Color(0xFFFF7043),
    science: 'PTSD 是大脑对创伤事件的"过度保护"反应，杏仁核持续警觉，导致闪回、噩梦和回避行为——大脑记住了危险，却在安全的环境中也无法放松。',
    comfort: '你活下来了，这就够了。你值得一个不被过去绑架的未来。',
  ),
  _WarmMessage(
    emoji: '⚡',
    condition: '注意力缺陷多动障碍',
    subtitle: '在纷乱的思绪中找到自己的节奏',
    color: Color(0xFFFFA726),
    science: 'ADHD 是神经发育的差异而非态度问题，核心表现为注意力易分散、冲动和多动，但也伴随超专注能力和发散性思维——大脑只是用不同的方式处理信息。',
    comfort: '你的大脑不是坏掉了，只是运转方式不同而已。',
  ),
  _WarmMessage(
    emoji: '🌀',
    condition: '精神分裂症',
    subtitle: '在混乱的感知中守护真实的自我',
    color: Color(0xFF546E7A),
    science: '精神分裂症是一种严重的精神障碍，主要表现为幻觉（如听到不存在的声音）、妄想（坚信不真实的想法）和思维紊乱，并非"人格分裂"，而是大脑感知与认知功能的失调。',
    comfort: '那些声音不是真实的，但你的勇气是真实的。',
  ),
  _WarmMessage(
    emoji: '🪞',
    condition: '解离性人格障碍',
    subtitle: '在多重面孔背后守护同一个灵魂',
    color: Color(0xFF8D6E63),
    science: '解离性人格障碍（曾称多重人格障碍）是极端创伤后形成的心理防御机制，患者在不同人格状态间转换，每个部分承载着不同的记忆和情感，目的是保护核心自我免受进一步伤害。',
    comfort: '每一个部分都在保护你，你们是一个团队。',
  ),
  _WarmMessage(
    emoji: '🫣',
    condition: '社交恐惧症',
    subtitle: '当他人的目光变成风暴',
    color: Color(0xFF78909C),
    science: '社交恐惧症不只是"害羞"，而是对社交场景产生强烈的恐惧和回避，大脑将人际互动误判为威胁，导致心跳加速、出汗颤抖，甚至完全回避一切社交。',
    comfort: '你的紧张不是懦弱，是大脑在过度保护你。',
  ),
  _WarmMessage(
    emoji: '🍽️',
    condition: '进食障碍',
    subtitle: '在食物与情绪之间找到平衡',
    color: Color(0xFFAB47BC),
    science: '进食障碍（如厌食症、暴食症）是以异常饮食行为为特征的精神疾病，核心是对体重和体型的过度关注与控制，往往掩盖了更深层的情绪需求和自我认同困境。',
    comfort: '你的价值不由体重定义，你值得被温柔以待。',
  ),
];
