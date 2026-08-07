import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

/// 作者信息页
/// 隐私协议后展示，介绍作者背景与联系方式
class AuthorInfoPage extends StatelessWidget {
  final VoidCallback onContinue;

  const AuthorInfoPage({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部标题
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                children: [
                  Text(
                    '👋',
                    style: TextStyle(fontSize: 40),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '关于作者',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '了解脑电波的创作者',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryOf(context),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            // 可滚动正文
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 姓名卡片
                    _buildInfoCard(
                      context,
                      icon: Icons.person_outline,
                      label: '作者',
                      value: 'AnonUsAl',
                      subtitle: '高中生 · 计算机爱好者',
                    ),
                    const SizedBox(height: 16),

                    // 简介
                    _buildSectionHeader(context, '个人简介'),
                    const SizedBox(height: 8),
                    _buildTextBlock(
                      context,
                      '对计算机怀有浓厚的兴趣，喜欢钻研与学习新事物。从最初跟随教程敲下第一行代码，'
                          '到如今能够独立分析问题、查阅资料并动手解决，在实践中逐步建立起自己的技术节奏。'
                          '课余时间热衷于开发个人项目、编写实用脚本，享受将一个想法逐步实现为可运行工具的过程。',
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        '除了写代码，也喜欢逛开源项目，学习他人的设计思路与问题解决方法，从中汲取经验。',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              height: 1.6,
                              color: AppTheme.textSecondaryOf(context),
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 心理关怀
                    _buildSectionHeader(context, '心理关怀'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withValues(alpha: 0.08),
                            AppTheme.primaryColor.withValues(alpha: 0.02),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '作者患有双相情感障碍，这是生活的一部分，而非全部。',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  height: 1.7,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '希望精神类疾病能被更多人所理解，而非被贴标签或回避。'
                            '生病不等于脆弱，也不应成为被区别对待的理由。',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  height: 1.7,
                                  color: AppTheme.textSecondaryOf(context),
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '如果你也在经历类似的事情，不必感到孤单。愿意聊的话，欢迎随时联系。',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  height: 1.7,
                                  color: AppTheme.textSecondaryOf(context),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 技能
                    _buildSectionHeader(context, '技术能力'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTag(context, 'Python'),
                        _buildTag(context, 'JavaScript'),
                        _buildTag(context, 'HTML / CSS'),
                        _buildTag(context, 'Bash'),
                        _buildTag(context, 'C'),
                        _buildTag(context, '算法'),
                        _buildTag(context, 'Linux'),
                        _buildTag(context, '网络基础'),
                        _buildTag(context, 'Tor / I2P'),
                        _buildTag(context, 'Git'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 所属团队
                    _buildSectionHeader(context, '所属团队'),
                    const SizedBox(height: 8),
                    _buildLinkTile(
                      context,
                      icon: Icons.groups_outlined,
                      label: 'ClouderyStudio（云术工作室）',
                      subtitle: '团队官方站点',
                      onTap: () => _launchUrl(context, 'https://www.cldery.com/'),
                    ),
                    const SizedBox(height: 24),

                    // 联系方式
                    _buildSectionHeader(context, '联系方式'),
                    const SizedBox(height: 8),
                    _buildContactTile(
                      context,
                      icon: Icons.code,
                      label: 'GitHub',
                      value: 'github.com/ClouderyStudio',
                      onTap: () => _launchUrl(
                        context,
                        'https://github.com/ClouderyStudio/',
                      ),
                    ),
                    _buildContactTile(
                      context,
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: 'albusp486@gmail.com',
                      onTap: () => _launchUrl(
                        context,
                        'mailto:albusp486@gmail.com',
                      ),
                    ),
                    _buildContactTile(
                      context,
                      icon: Icons.work_outline,
                      label: '工作邮箱',
                      value: 'anonusal@cldery.com',
                      onTap: () => _launchUrl(
                        context,
                        'mailto:anonusal@cldery.com',
                      ),
                    ),
                    _buildCopyTile(
                      context,
                      icon: Icons.chat_outlined,
                      label: 'QQ',
                      value: '3353739856',
                    ),
                    _buildCopyTile(
                      context,
                      icon: Icons.send_outlined,
                      label: 'Telegram',
                      value: '@AnonUsAl',
                    ),
                    _buildCopyTile(
                      context,
                      icon: Icons.message_outlined,
                      label: 'LINE',
                      value: '@AnonUsAl',
                    ),
                    _buildCopyTile(
                      context,
                      icon: Icons.phone_iphone_outlined,
                      label: 'WhatsApp',
                      value: '@AnonUsAl',
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            // 底部按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onContinue,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '开始使用脑电波',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 构建组件 ====================

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBgOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerOf(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textHintOf(context),
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryOf(context),
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextBlock(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            height: 1.7,
            color: AppTheme.textSecondaryOf(context),
          ),
    );
  }

  Widget _buildTag(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLinkTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBgOf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.dividerOf(context)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor, size: 22),
        title: Text(label, style: const TextStyle(fontSize: 14)),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textHintOf(context),
          ),
        ),
        trailing: const Icon(Icons.open_in_new, size: 16),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildContactTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardBgOf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.dividerOf(context)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.textSecondaryOf(context), size: 20),
        title: Text(label, style: const TextStyle(fontSize: 13)),
        subtitle: Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildCopyTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardBgOf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.dividerOf(context)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.textSecondaryOf(context), size: 20),
        title: Text(label, style: const TextStyle(fontSize: 13)),
        subtitle: Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy, size: 18),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已复制 $value'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('无法打开链接'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
