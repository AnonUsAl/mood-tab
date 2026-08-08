import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

/// 关于软件页面 — 展示版本号、更新日志、技术信息、开源许可
class SoftwareInfoPage extends StatefulWidget {
  const SoftwareInfoPage({super.key});

  @override
  State<SoftwareInfoPage> createState() => _SoftwareInfoPageState();
}

class _SoftwareInfoPageState extends State<SoftwareInfoPage> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('关于软件'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Logo
            _buildAppLogo(isDark),
            const SizedBox(height: 16),

            // 版本号
            Text(
              _packageInfo != null ? '脑电波 v${_packageInfo!.version}' : '脑电波',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              _packageInfo != null
                  ? 'Build ${_packageInfo!.buildNumber} · ${_packageInfo!.appName}'
                  : '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textHintOf(context),
                  ),
            ),
            const SizedBox(height: 32),

            // 更新日志
            _buildSectionTitle(context, '更新日志'),
            const SizedBox(height: 8),
            _buildChangelogCard(isDark),
            const SizedBox(height: 24),

            // 技术信息
            _buildSectionTitle(context, '技术信息'),
            const SizedBox(height: 8),
            _buildTechInfoCard(),
            const SizedBox(height: 24),

            // 开源 & 链接
            _buildSectionTitle(context, '开源与链接'),
            const SizedBox(height: 8),
            _buildLinksCard(isDark),
            const SizedBox(height: 24),

            // 作者与团队
            _buildSectionTitle(context, '作者与团队'),
            const SizedBox(height: 8),
            _buildTeamCard(isDark),
            const SizedBox(height: 32),

            // 底部致谢
            Text(
              '仅本地存储 零云端上传  感谢 AnonUsAl 作者的倾尽全力',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textHintOf(context),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== App Logo ====================

  Widget _buildAppLogo(bool isDark) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.favorite_rounded,
          size: 40,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  // ==================== 分区标题 ====================

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryOf(context),
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }

  // ==================== 更新日志 ====================

  Widget _buildChangelogCard(bool isDark) {
    final versions = [
      _ChangelogEntry(
        version: 'v3.0.14',
        date: '2026-08',
        changes: [
          '🐛 修复「记录心情」页情绪网格底部溢出 2.6 像素的问题 — GridView 加高 mainAxisExtent 至 76',
          '🐛 修复「添加自定义标签」对话框 emoji 选区底部溢出 14 像素的问题 — 改为 7 列布局 + 弹窗 scrollable',
        ],
        isLatest: true,
      ),
      _ChangelogEntry(
        version: 'v3.0.13',
        date: '2026-08',
        changes: [
          '✨ 新增「关于作者」页面 — 首次启动时在隐私协议后展示，介绍作者背景、技能、团队与联系方式',
          '- 姓名卡片、个人简介、心理关怀说明',
          '- 技术能力标签云',
          '- ClouderyStudio 团队介绍与官网链接',
          '- GitHub / 邮箱 / QQ / Telegram / LINE / WhatsApp 联系方式（QQ 等支持一键复制）',
        ],
      ),
      _ChangelogEntry(
        version: 'v3.0.12',
        date: '2026-08',
        changes: [
          '✨ 新增隐私保护指引 — 首次启动时展示，涵盖数据存储、权限说明、免责声明等',
        ],
      ),
      _ChangelogEntry(
        version: 'v3.0.11',
        date: '2026-08',
        changes: [
          '✨ 日记卡片底部增加「长按可修改日记」操作提示文字',
          '✨ 日历页记录卡片支持点击直接进入编辑（长按操作菜单保留）',
          '✨ 情绪记录页支持选择历史日期 — 新建记录时可点击顶部日期行切换过去日期',
        ],
      ),
      _ChangelogEntry(
        version: 'v3.0.10',
        date: '2026-08',
        changes: [
          '🐛 修复用药提醒仅在应用前台运行时有效的问题 — 通知/闹钟模式均使用精确调度确保后台可靠触发',
          '🐛 修复闹钟模式与系统通知视觉无区分 — 闹钟模式持续展示、锁屏全屏弹出、使用系统闹钟提示音',
          '🐛 修复药物剂量文字过长时超出容器边界、覆盖药物名称的布局问题',
          '🐛 修复头像设置后退出重进丢失的问题 — 图片从临时缓存复制到应用文档目录永久存储',
        ],
      ),
      _ChangelogEntry(
        version: 'v3.0.9',
        date: '2026-07',
        changes: [
          '🖼️ 头像支持自定义图片 — 在「我的」页面点击头像即可从相册选择照片作为头像，右下角新增相机角标提示；未设置图片时仍显示昵称首字或默认图标',
        ],
      ),
      _ChangelogEntry(
        version: 'v3.0.8',
        date: '2026-07',
        changes: [
          '🎨 重做底部导航栏 — 移除中间半悬浮的记录按钮（及导航栏圆形缺口），改为「今日 / 日历 / 记录 / 统计 / 我的」五个标签平铺，记录入口融入导航栏，不再遮挡页面内容，视觉更统一',
        ],
      ),
      _ChangelogEntry(
        version: 'v3.0.7',
        date: '2026-07',
        changes: [
          '🐛 修复「星期情绪分析」柱状图底部再次溢出 2px 的问题 — 底部「星期 + 条数」标签区改为固定 32px 高度，并给中文文字显式设定 1.2 行高，同时让各列星期标签始终对齐同一基线',
        ],
      ),
      _ChangelogEntry(
        version: 'v3.0.6',
        date: '2026-07',
        changes: [
          '🐛 修复「星期情绪分析」柱状图底部再次溢出的问题 — 中文文字实际行高比预估大，将容器高度从 140px 提升至 160px，彻底解决 BOTTOM OVERFLOWED 警告',
        ],
      ),
      _ChangelogEntry(
        version: 'v3.0.5',
        date: '2026-07',
        changes: [
          '🐛 修复「星期情绪分析」柱状图溢出 bug — 当某天平均强度接近 5.0 时，柱体 + 顶部数字 + 底部「周X/几条」标签的总高度超过容器高度，导致底部标签被卡片裁切',
        ],
      ),
      _ChangelogEntry(
        version: 'v3.0.4',
        date: '2026-07',
        changes: [
          '🌙 修复 GitHub 源码图标在深色模式下不可见的问题',
          '🐛 修复已知 bug，增加用户体验(bush)',
        ],
      ),
      _ChangelogEntry(
        version: 'v3.0.2',
        date: '2026-07',
        changes: [
          '🛠️ 修复数据恢复功能 — 可以从备份 JSON 文件恢复数据',
          '📂 数据恢复支持文件选择器选择备份文件',
        ],
      ),
      _ChangelogEntry(
        version: 'v3.0.0',
        date: '2026-07',
        changes: [
          '🎉 脑电波 3.0.0 正式发布',
          '📦 应用包名更新为 com.anonusal.moodtab',
          '⚠️ 包名变更：安装新版前请先卸载旧版（或与旧版并存）',
        ],
      ),
      _ChangelogEntry(
        version: 'v2.7.26',
        date: '2025-07',
        changes: [
          '🐛 修复了一些 bug',
        ],
      ),
      _ChangelogEntry(
        version: 'v2.7.25',
        date: '2025-07',
        changes: [
          '🐛 修复了一些 bug',
        ],
      ),
      _ChangelogEntry(
        version: 'v2.7.23',
        date: '2025-07',
        changes: [
          '🐛 修复日历中点击今天显示"补记"而非正常记录 — 今天判定为正常记录入口',
        ],
      ),
      _ChangelogEntry(
        version: 'v2.7.22',
        date: '2025-07',
        changes: [
          '🐛 修复冲突关怀页面权限申请弹窗不出现 — iOS 缺少 NSPhotoLibraryUsageDescription',
          '🧹 移除冲突关怀页面多余的相册权限逻辑 — 卡片为硬编码数据无需权限',
          '🔧 修复 iOS release IPA 构建失败 — xattr 绕过方案',
        ],
      ),
      _ChangelogEntry(
        version: 'v2.7.21',
        date: '2025-07',
        changes: [
          '📧 关于作者页面增加企业邮箱 anonusal@cldery.com',
          '🌐 关于作者页面增加云术工作室官网链接 www.cldery.com',
        ],
      ),
      _ChangelogEntry(
        version: 'v2.7.20',
        date: '2025-07',
        changes: [
          '🔧 修复Android通知/闹钟系统重大bug',
          '   - 修复精确闹钟权限检查乐观返回导致每次调度都抛异常',
          '   - 修复批量调度中单个通知失败导致后续全部丢失',
          '   - 修复药物提醒数量无上限可能导致ID逃逸',
          '   - 修复启动时通知调度阻塞Splash进入主页',
          '   - 优化权限请求返回值处理',
        ],
      ),
      _ChangelogEntry(
        version: 'v2.7.19',
        date: '2025-07',
        changes: [
          '👥 新增关于团队 — 云术工作室官网 www.cldery.com',
        ],
      ),
      _ChangelogEntry(
        version: 'v2.7.18',
        date: '2025-07',
        changes: [
          '🏡 新增栖所 — 沉浸式套壳页面，安静的小角落让心歇一歇',
          '🌙 新增深色模式跟随系统 — 自动适配手机深色/浅色设置',
          '📕 修复日历页首次打开当天记录不显示 — 初始化时自动选中今天',
          '💬 文案润色 — 危机支持你不是一个人改为你并不孤单',
          '🎨 图标全面更新',
          '🔗 GitHub链接改为 ClouderyStudio 组织仓库',
        ],
      ),
      _ChangelogEntry(
        version: 'v2.7.16',
        date: '2025-07',
        changes: [
          '📕 修复日历页首次打开当天记录不显示 — 初始化时自动选中今天',
        ],
      ),
      _ChangelogEntry(
        version: 'v2.7.15',
        date: '2025-07',
        changes: [
          '🏡 新增栖所 — 沉浸式套壳页面，安静的小角落让心歇一歇',
        ],
      ),
      _ChangelogEntry(
        version: 'v2.7.14',
        date: '2025-07',
        changes: [
          '🔧 修复药物提醒不触发 — 通知 ID 溢出 Android 32-bit 整数上限',
          '🔧 修复取消药物提醒误删每日情绪提醒',
          '🔧 修复删除药物后剩余药物提醒失效',
          '🔧 修复通知/闹钟模式调度策略相同的问题',
          '🔧 修复更改时区后药物提醒不重新调度',
          '🖼️ 冲突关怀记录图片支持点击全屏查看 — 双指缩放、滑动浏览',
        ],
      ),
      _ChangelogEntry(
        version: 'v2.7.0',
        date: '2025-07',
        changes: [
          '🐛 修复情绪花园相关 bug',
          '🤝 新增冲突关怀功能 — 支持长按记录修改',
          '📷 日记支持添加图片 — 多张照片、拍照、编辑回显',
          '🌍 新增时区设置 — 20 个常用时区可选，通知按所选时区调度',
          '🔔 安卓提醒/闹钟全面修复 — 精确闹钟权限、全屏亮屏、release 图标裁剪',
        ],
      ),
      _ChangelogEntry(
        version: 'v2.6.0',
        date: '2025-07',
        changes: [
          '🎨 情绪花园涂鸦大升级 — 笔触贝塞尔平滑、重做功能、持久化',
          '🖌️ 独立橡皮擦尺寸 + 情绪系柔和色板',
          '🔔 消息提醒修复 — Android 13+ 权限适配 + iOS 通知代理注册',
          '🔧 浅色模式涂鸦坐标修复 + 单点点击渲染',
        ],
      ),
      _ChangelogEntry(
        version: 'v2.5.0',
        date: '2025-07',
        changes: [
          '❤️ 暖心寄语重构 — 科普认知 + 安慰支持',
          '🧠 新增精神分裂症、解离性人格障碍、社交恐惧症、进食障碍',
          '📅 日历补记 — 补录过去日期的心情',
          '🔧 快捷操作卡片布局优化',
        ],
      ),
      _ChangelogEntry(
        version: 'v2.4.0',
        date: '2025-07',
        changes: [
          '📱 应用名称改为"脑电波"',
          'ℹ️ 关于软件版本页',
          '🔢 动态版本号显示（package_info_plus）',
        ],
      ),
      _ChangelogEntry(
        version: 'v2.3.0',
        date: '2025-07',
        changes: [
          '🌸 呼吸练习 — 方块呼吸法 + 花瓣开合动画',
          '🌱 情绪花园 — 每条记录长出一朵花',
          '☀️ 情绪天气播报 — 首页天气预报式卡片',
          '🔧 药物刷新修复 — notifyListeners 顺序修正',
        ],
      ),
      _ChangelogEntry(
        version: 'v2.2.0',
        date: '2025-07',
        changes: [
          '💊 用药提醒 — 多时间点通知 + 药物管理',
          '👤 用户昵称 — 首页问候语 + PDF报告带用户名',
          '🔧 标签增删后统计页数据刷新修复',
          '📦 多平台构建修复（SPM/xattr）',
        ],
      ),
      _ChangelogEntry(
        version: 'v2.1.0',
        date: '2025-07',
        changes: [
          '📖 日记本 — 自由书写情绪日记',
          '❤️ 暖心寄语 — 随机励志语录',
          '🧪 心理测评 — PHQ-9 / GAD-7 专业量表',
          '🔒 隐私锁 — PIN码保护',
          '☀️🌙 深色/浅色主题切换',
        ],
      ),
      _ChangelogEntry(
        version: 'v2.0.0',
        date: '2025-07',
        changes: [
          '🎨 全新 UI 设计 — 温暖治愈配色',
          '📊 统计分析 — 情绪分布/趋势/标签',
          '🏷️ 自定义标签 — 触发因素标记',
          '📤 数据导出 — CSV / PDF / JSON备份',
          '☎️ 危机支持 — 心理援助热线',
        ],
      ),
      _ChangelogEntry(
        version: 'v1.0.0',
        date: '2025-07',
        changes: [
          '📝 情绪记录 — 6种情绪 + 强度选择',
          '📋 历史回顾 — 情绪时间线',
          '🔔 每日提醒 — 定时提醒记录',
        ],
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBgOf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: versions.map((v) => _buildVersionItem(v, isDark)).toList(),
      ),
    );
  }

  Widget _buildVersionItem(_ChangelogEntry entry, bool isDark) {
    final isLast = entry.version == 'v1.0.0';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 版本号 + 时间线圆点
          SizedBox(
            width: 56,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: entry.isLatest
                        ? AppTheme.primaryColor
                        : AppTheme.textHintOf(context),
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 28,
                    color: AppTheme.dividerOf(context),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.version,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 8),
                    if (entry.isLatest)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '当前版本',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      entry.date,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textHintOf(context),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...entry.changes.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      c,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryOf(context),
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 技术信息 ====================

  Widget _buildTechInfoCard() {
    final items = [
      ('框架', 'Flutter ${_packageInfo != null ? "" : ""}· Dart'),
      ('存储', 'SQLite 本地数据库 · SharedPreferences'),
      ('隐私', '100% 本地 · 零网络上传 · 无第三方统计'),
      ('平台', 'Android · iOS · macOS · Web'),
      ('许可', 'MIT License · 开源免费'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBgOf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Text(
                    item.$1,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textHintOf(context),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item.$2,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==================== 开源与链接 ====================

  Widget _buildLinksCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBgOf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildLinkTile(
            icon: Icons.code,
            iconColor: isDark ? Colors.white : const Color(0xFF24292e),
            title: 'GitHub 源码',
            subtitle: 'github.com/ClouderyStudio/mood-tab',
            onTap: () =>
                _launchUrl('https://github.com/ClouderyStudio/mood-tab'),
            isFirst: true,
          ),
          _buildDivider(),
          _buildLinkTile(
            icon: Icons.new_releases_outlined,
            iconColor: const Color(0xFF4CAF50),
            title: 'Release 下载',
            subtitle: '查看所有版本的安装包',
            onTap: () => _launchUrl(
                'https://github.com/ClouderyStudio/mood-tab/releases'),
          ),
          _buildDivider(),
          _buildLinkTile(
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF2196F3),
            title: '开源许可',
            subtitle: 'MIT License · 查看第三方依赖许可',
            onTap: () => showLicensePage(
              context: context,
              applicationName: '脑电波',
              applicationVersion: _packageInfo?.version ?? '',
              applicationIcon: const Icon(Icons.favorite_rounded,
                  size: 40, color: AppTheme.primaryColor),
            ),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isFirst ? 16 : 0),
      topRight: Radius.circular(isFirst ? 16 : 0),
      bottomLeft: Radius.circular(isLast ? 16 : 0),
      bottomRight: Radius.circular(isLast ? 16 : 0),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textHintOf(context),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: AppTheme.textHintOf(context), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: AppTheme.dividerOf(context)),
    );
  }

  // ==================== 作者与团队 ====================

  Widget _buildTeamCard(bool isDark) {
    final people = [
      _TeamMember(
        role: '作者',
        name: 'AnonUsAl',
        qq: '3353739856',
        icon: Icons.person_outline,
        iconColor: const Color(0xFF7E57C2),
      ),
      _TeamMember(
        role: '栖所作者',
        name: '云竹',
        qq: '2457483710',
        icon: Icons.eco,
        iconColor: const Color(0xFF43A047),
      ),
      _TeamMember(
        role: '栖所作者',
        name: '柒屹',
        qq: '2675256772',
        icon: Icons.landscape,
        iconColor: const Color(0xFF00897B),
      ),
      _TeamMember(
        role: 'QA',
        name: '屿',
        qq: '3801901707',
        icon: Icons.all_inclusive_rounded,
        iconColor: const Color(0xFFEF6C00),
      ),
      _TeamMember(
        role: 'QA',
        name: '轩不是车干',
        qq: '570969867',
        icon: Icons.emoji_emotions,
        iconColor: const Color(0xFF26A69A),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBgOf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // 团队成员
          ...people.map((m) => _buildTeamMemberTile(m)),
          _buildDivider(),
          // 团队
          _buildTeamTile(isDark),
        ],
      ),
    );
  }

  Widget _buildTeamMemberTile(_TeamMember m) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: m.iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(m.icon, color: m.iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      m.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.textHintOf(context)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        m.role,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textHintOf(context),
                              fontSize: 11,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                InkWell(
                  onTap: () => _copyQQ(m.qq),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'QQ：${m.qq}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondaryOf(context),
                                  ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.copy_outlined,
                          size: 13,
                          color: AppTheme.textHintOf(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamTile(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.group_outlined,
                color: AppTheme.primaryColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ClouderyStudio',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  '云术工作室',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryOf(context),
                      ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _launchUrl('https://www.cldery.com'),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '官网',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.open_in_new,
                    size: 14,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyQQ(String qq) {
    Clipboard.setData(ClipboardData(text: qq));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已复制 QQ 号：$qq')),
    );
  }

  // ==================== 工具 ====================

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('无法打开链接：$url')),
      );
    }
  }
}

/// 更新日志条目
class _ChangelogEntry {
  final String version;
  final String date;
  final List<String> changes;
  final bool isLatest;

  _ChangelogEntry({
    required this.version,
    required this.date,
    required this.changes,
    this.isLatest = false,
  });
}

/// 作者 / 团队成员
class _TeamMember {
  final String role;
  final String name;
  final String qq;
  final IconData icon;
  final Color iconColor;

  _TeamMember({
    required this.role,
    required this.name,
    required this.qq,
    required this.icon,
    required this.iconColor,
  });
}
