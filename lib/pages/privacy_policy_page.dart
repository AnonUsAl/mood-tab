import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 隐私协议页面
/// 首次启动时展示，用户同意后方可进入应用
class PrivacyPolicyPage extends StatelessWidget {
  final VoidCallback onAccept;

  const PrivacyPolicyPage({super.key, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部标题区
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(
                children: [
                  Text(
                    '💊',
                    style: TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '隐私保护指引',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '请仔细阅读以下内容，了解我们如何保护你的隐私',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryOf(context),
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Divider(height: 1),
            // 可滚动的协议正文
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      context,
                      '1. 数据存储',
                      '你的所有数据（情绪记录、日记、药物提醒、打卡状态等）均存储在设备本地，不会上传到任何云端服务器。我们无法访问你的任何个人数据。',
                      isDark,
                    ),
                    _buildSection(
                      context,
                      '2. 收集的信息',
                      '本应用仅收集你在使用过程中主动输入的信息，包括但不限于：'
                          '\n  - 情绪类型与强度记录'
                          '\n  - 日记文本与图片'
                          '\n  - 自定义标签'
                          '\n  - 药物提醒设置（名称、剂量、时间）'
                          '\n  - 打卡记录'
                          '\n  - 自伤冲动监测日志',
                      isDark,
                    ),
                    _buildSection(
                      context,
                      '3. 信息的使用',
                      '你的数据仅用于以下目的：'
                          '\n  - 在本应用中展示你的情绪趋势与统计分析'
                          '\n  - 按你设定的时间发送用药提醒通知'
                          '\n  - 生成个人专属的情绪报告',
                      isDark,
                    ),
                    _buildSection(
                      context,
                      '4. 权限说明',
                      '本应用申请的部分敏感权限及其用途：'
                          '\n  - 通知权限：用于发送用药提醒和情绪记录提醒'
                          '\n  - 精确闹钟权限：用于确保药物提醒按时触发'
                          '\n  - 相册/相机权限：用于设置头像和日记配图'
                          '\n  - 生物识别权限：用于隐私锁功能（可选启用）\n'
                          '你可以在系统设置中随时管理这些权限。',
                      isDark,
                    ),
                    _buildSection(
                      context,
                      '5. 数据安全',
                      '我们重视你的数据安全。你可以通过以下方式保护数据：'
                          '\n  - 在「设置」中开启隐私锁'
                          '\n  - 定期导出数据备份'
                          '\n  - 卸载应用前确保已备份重要数据\n'
                          '卸载应用将清空所有本地数据，且无法恢复。',
                      isDark,
                    ),
                    _buildSection(
                      context,
                      '6. 免责声明',
                      '脑电波是一款情绪记录与自我觉察工具，不提供医疗诊断、治疗建议或心理咨询服务。'
                          '如果你正在经历严重的情绪困扰，请及时寻求专业医疗帮助。'
                          '药物提醒功能仅供参考，请遵从医嘱按时服药。',
                      isDark,
                    ),
                    _buildSection(
                      context,
                      '7. 联系我们',
                      '如果你对隐私保护有任何疑问，可以通过以下方式联系我们：'
                          '\n  QQ：3353739856\n  团队：ClouderyStudio（云术工作室）',
                      isDark,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '更新日期：2026年8月7日',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textHintOf(context),
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            // 底部按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _onDecline(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('不同意'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => _onAccept(context),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '同意并继续',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.6,
                  color: AppTheme.textSecondaryOf(context),
                ),
          ),
        ],
      ),
    );
  }

  void _onAccept(BuildContext context) {
    onAccept();
  }

  void _onDecline(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('无法继续使用'),
        content: const Text(
          '你需要同意隐私保护指引才能使用脑电波。\n\n'
          '你的所有数据仅存储在本地，我们不会收集或上传任何个人信息。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('我再看看'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onAccept();
            },
            child: const Text('同意并继续'),
          ),
        ],
      ),
    );
  }
}
