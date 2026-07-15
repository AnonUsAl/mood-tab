import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 暖心寄语页面
/// 为精神类疾病患者提供温暖的支持与鼓励
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
                '点击下方卡片展开寄语',
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
            '这些话语写给每一个在与心灵风暴搏斗的你。',
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
                      ...msg.paragraphs.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              p,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    height: 1.8,
                                    color: AppTheme.textPrimaryOf(context),
                                  ),
                            ),
                          )),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: msg.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.favorite, size: 14, color: msg.color),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                msg.footer,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: msg.color,
                                  fontWeight: FontWeight.w500,
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
  final List<String> paragraphs;
  final String footer;

  const _WarmMessage({
    required this.emoji,
    required this.condition,
    required this.subtitle,
    required this.color,
    required this.paragraphs,
    required this.footer,
  });
}

/// 寄语内容
const List<_WarmMessage> _warmMessages = [
  _WarmMessage(
    emoji: '🌊',
    condition: '双相情感障碍',
    subtitle: '在躁狂与抑郁的浪潮中寻找平衡',
    color: Color(0xFF7E57C2),
    paragraphs: [
      '双相情感障碍的朋友，你好，我想对你说——',
      '你的世界可能在高潮与低谷之间剧烈摆荡，那种感觉就像被抛向云端又摔向地面。躁狂时的你精力充沛、思维奔涌，仿佛能征服世界；抑郁时的你却连起床的力气都没有，世界变得灰暗而沉重。',
      '但请记得，这不是你的错，也不是你「想太多」或「太脆弱」。这是大脑化学物质的节律在作祟，而你一直在努力与它共处，这份坚韧本身就是了不起的勇气。',
      '那些你以为自己在浪费生命的低谷期，其实是你身体在积蓄力量。那些你觉得失控的亢奋期，也是你生命力旺盛的证明。你不是两个人，你是一个在两极之间寻找平衡的旅人。',
      '坚持服药、定期复诊、规律作息——这些看似枯燥的事，正是你与疾病和解的方式。总有一天，浪潮会变得温柔一些，你会学会在风暴中航行。',
    ],
    footer: '你的每一次坚持，都是在为更好的明天铺路。',
  ),
  _WarmMessage(
    emoji: '🌧️',
    condition: '抑郁症',
    subtitle: '穿过那片灰色的迷雾',
    color: Color(0xFF5C6BC0),
    paragraphs: [
      '正在经历抑郁的朋友，你好，我想对你说——',
      '我知道，现在的世界可能对你来说像蒙了一层灰。那些曾经让你快乐的事情变得索然无味，每天早晨醒来都像背着一块巨石。你可能觉得是自己懒、是自己不够好，但不是的——',
      '抑郁不是性格缺陷，不是矫情，不是「想开点」就能好的。它是一场大脑的感冒，只不过这场感冒比普通的要漫长得多。你的疲惫、你的无力、你的迷茫，都是真实的症状，不是你的错。',
      '哪怕今天你只是从床上爬起来喝了一杯水，那也是胜利。哪怕今天你什么都没做，只是活着度过了这一天，那也足够了。',
      '灰色的迷雾会散的。也许不是今天，也许不是明天，但它终会散去。在那之前，请允许自己慢慢来，允许自己不够好。你已经很勇敢了。',
    ],
    footer: '活着本身，就是你最大的胜利。',
  ),
  _WarmMessage(
    emoji: '💨',
    condition: '焦虑症',
    subtitle: '当担忧成为一种习惯',
    color: Color(0xFF26A69A),
    paragraphs: [
      '总是被焦虑困扰的朋友，你好，我想对你说——',
      '你的大脑好像有一个永远关不掉的警报器，即使在安全的时刻也会拉响警报。心跳加速、手心出汗、呼吸急促、思绪翻涌——这些感觉真实而可怕，仿佛危险就在眼前。',
      '但你的焦虑其实是大脑在过度保护你。它太想让你安全了，以至于把所有的「万一」都当成了「一定」。这不是你的弱点，而是你的神经系统太过尽心尽责。',
      '当焦虑来袭时，试着告诉自己：「这只是警报响了，并不代表真的有危险。」然后慢慢呼吸，感受你的脚踩在地面上，你此时此刻是安全的。',
      '你不需要消除所有焦虑才能好好生活。带着焦虑生活，同时不被它完全控制，这本身就是一种了不起的能力。你已经在做了，而且做得比你自己以为的要好。',
    ],
    footer: '不安的时刻终会过去，你已经度过了无数次。',
  ),
  _WarmMessage(
    emoji: '🔄',
    condition: '强迫症',
    subtitle: '与反复出现的念头共处',
    color: Color(0xFFEC407A),
    paragraphs: [
      '被强迫思维困扰的朋友，你好，我想对你说——',
      '那些反复出现的念头、不得不做的仪式，可能让你觉得自己很「奇怪」。但强迫症的本质是你的大脑在试图通过重复来获得安全感，它只是用了一种不太有效的方式。',
      '那些侵入性的想法并不代表你这个人。念头只是念头，它不代表你的价值观，不代表你的本心，更不代表你会去做。大脑会随机产生各种想法，而你无法控制它的产出，但你可以选择如何回应。',
      '每一次你忍住不去执行那个仪式，哪怕只多忍了一秒钟，都是一次进步。每一次你允许那个念头存在而不与它对抗，都是一次胜利。',
      '康复不是强迫症完全消失，而是它不再掌控你的生活。你正在慢慢夺回方向盘，这需要时间，也值得等待。',
    ],
    footer: '念头只是念头，你比它强大得多。',
  ),
  _WarmMessage(
    emoji: '🛡️',
    condition: '创伤后应激障碍',
    subtitle: '从过去的阴影中走向光',
    color: Color(0xFFFF7043),
    paragraphs: [
      '经历过创伤的朋友，你好，我想对你说——',
      '那些闪回、噩梦、过度警觉，都是大脑在试图保护你——它记住那个可怕的经历，是想让你不再受伤害。只是这个保护机制太过敏感了，让你在安全的环境里也无法放松。',
      '请知道，你经历过的那些事不是你的错。你当时的反应——无论是什么——都是你在极端情况下的求生本能。你活下来了，这就够了。',
      '创伤不会定义你是谁。你是幸存者，不是受害者。那些破碎的经历可以被慢慢整合进你的人生故事里，成为你坚韧的注脚，而不是困住你的牢笼。',
      '疗愈是可能的。那些画面会慢慢变得模糊，那些触发点会慢慢失去力量。你值得一个不被过去绑架的未来。',
    ],
    footer: '你已经熬过了最黑暗的时刻，接下来只会更好。',
  ),
  _WarmMessage(
    emoji: '⚡',
    condition: '注意力缺陷多动障碍',
    subtitle: '在纷乱的思绪中找到自己的节奏',
    color: Color(0xFFFFA726),
    paragraphs: [
      'ADHD 的朋友，你好，我想对你说——',
      '你的大脑像一台同时开了无数个标签页的浏览器，有时候卡顿，有时候过热，但也有很多时刻能迸发出惊人的创造力和能量。',
      '你可能在成长过程中听过太多次「你就是不努力」「你怎么又走神了」「你就不能专心一点」。但 ADHD 不是态度问题，不是懒惰，不是智商问题——它是神经发育的差异，你的大脑就是用不同的方式处理信息。',
      '那些忘带的东西、错过的时间、没做完的事情，不是因为你不在乎，而是你的执行功能系统和别人不一样。这不代表你做不到，只是你需要找到属于自己的方法。',
      '你的发散性思维、你的 hyperfocus、你的创造力——这些都是 ADHD 给你的礼物。当你找到适合自己的节奏，你会发现自己能做到远超想象的事情。',
    ],
    footer: '你的大脑不是坏掉了，只是运转方式不同而已。',
  ),
];
