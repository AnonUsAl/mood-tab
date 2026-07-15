import 'dart:convert';
import '../models/mood_type.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/mood_provider.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import 'about_page.dart';
import 'assessment_web_page.dart';
import 'crisis_support_page.dart';
import 'tag_management_page.dart';

/// 设置页（我的）
/// 个人信息、提醒设置、隐私锁、主题设置、数据管理、心理测评、关于作者
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _prefs = PreferencesService();
  final _dbService = DatabaseService();

  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _privacyLockEnabled = false;
  String _themeMode = 'light';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    await _prefs.init();
    setState(() {
      _reminderEnabled = _prefs.dailyReminderEnabled;
      _reminderTime = TimeOfDay(
        hour: _prefs.dailyReminderHour,
        minute: _prefs.dailyReminderMinute,
      );
      _privacyLockEnabled = _prefs.privacyLockEnabled;
      _themeMode = _prefs.themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<MoodProvider>(
          builder: (context, provider, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Text(
                    '我的',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),

                  // 个人信息卡片
                  _buildProfileCard(provider),
                  const SizedBox(height: 24),

                  // 提醒设置
                  _buildSectionTitle('提醒设置'),
                  const SizedBox(height: 8),
                  _buildReminderSection(),
                  const SizedBox(height: 24),

                  // 隐私锁
                  _buildSectionTitle('隐私与安全'),
                  const SizedBox(height: 8),
                  _buildPrivacySection(),
                  const SizedBox(height: 24),

                  // 主题设置
                  _buildSectionTitle('主题设置'),
                  const SizedBox(height: 8),
                  _buildThemeSection(),
                  const SizedBox(height: 24),

                  // 个性化
                  _buildSectionTitle('个性化'),
                  const SizedBox(height: 8),
                  _buildPersonalizationSection(),
                  const SizedBox(height: 24),

                  // 数据管理
                  _buildSectionTitle('数据管理'),
                  const SizedBox(height: 8),
                  _buildDataManagementSection(),
                  const SizedBox(height: 24),

                  // 心理测评
                  _buildSectionTitle('更多'),
                  const SizedBox(height: 8),
                  _buildMoreSection(),
                  const SizedBox(height: 24),

                  // 关于作者
                  _buildSectionTitle('关于'),
                  const SizedBox(height: 8),
                  _buildAboutSection(),

                  const SizedBox(height: 32),
                  // 版本信息
                  Center(
                    child: Text(
                      'mood-tab v2.0.2',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textHintOf(context),
                          ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ==================== 个人信息卡片 ====================

  Widget _buildProfileCard(MoodProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // 头像占位
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.person,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          // 统计信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildStatItem(
                      '${provider.totalCount}',
                      '记录总数',
                    ),
                    const SizedBox(width: 24),
                    _buildStatItem(
                      '${_prefs.streakDays}',
                      '连续打卡',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  // ==================== 分区标题 ====================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryOf(context),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  // ==================== 提醒设置 ====================

  Widget _buildReminderSection() {
    return _buildCard(
      children: [
        SwitchListTile(
          title: const Text('每日提醒'),
          subtitle: const Text('每天定时提醒你记录情绪'),
          value: _reminderEnabled,
          activeThumbColor: AppTheme.primaryColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          onChanged: (value) async {
            await _prefs.setDailyReminderEnabled(value);
            setState(() {
              _reminderEnabled = value;
            });
            if (value) {
              await _prefs.setDailyReminderHour(_reminderTime.hour);
              await _prefs.setDailyReminderMinute(_reminderTime.minute);
              _showSnackBar('已开启每日提醒');
            } else {
              _showSnackBar('已关闭每日提醒');
            }
          },
        ),
        if (_reminderEnabled)
          ListTile(
            leading:
                const Icon(Icons.access_time, color: AppTheme.primaryColor),
            title: const Text('提醒时间'),
            trailing: Text(
              '${_reminderTime.hour.toString().padLeft(2, '0')}:'
              '${_reminderTime.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryOf(context),
                  ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            onTap: () => _pickTime(),
          ),
      ],
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      await _prefs.setDailyReminderHour(picked.hour);
      await _prefs.setDailyReminderMinute(picked.minute);
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  // ==================== 隐私锁 ====================

  Widget _buildPrivacySection() {
    return _buildCard(
      children: [
        SwitchListTile(
          title: const Text('隐私锁'),
          subtitle: const Text('使用 PIN 码保护你的情绪记录'),
          value: _privacyLockEnabled,
          activeThumbColor: AppTheme.primaryColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          onChanged: (value) async {
            if (value) {
              // 开启时需要设置 PIN
              final pin = await _showPinSetupDialog();
              if (pin != null && pin.length == 4) {
                await _prefs.setPinCode(pin);
                await _prefs.setPrivacyLockEnabled(true);
                setState(() {
                  _privacyLockEnabled = true;
                });
                _showSnackBar('隐私锁已开启');
              }
            } else {
              await _prefs.setPrivacyLockEnabled(false);
              setState(() {
                _privacyLockEnabled = false;
              });
              _showSnackBar('隐私锁已关闭');
            }
          },
        ),
        if (_privacyLockEnabled)
          ListTile(
            leading:
                const Icon(Icons.lock_outline, color: AppTheme.primaryColor),
            title: const Text('修改 PIN 码'),
            trailing:
                Icon(Icons.chevron_right, color: AppTheme.textHintOf(context)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            onTap: () => _changePin(),
          ),
      ],
    );
  }

  Future<String?> _showPinSetupDialog() async {
    String pin = '';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('设置 PIN 码'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('请输入 4 位数字作为 PIN 码'),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '••••',
                  counterText: '',
                ),
                onChanged: (value) {
                  pin = value;
                },
              ),
            ],
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (pin.length == 4) {
                  Navigator.of(ctx).pop(pin);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入 4 位数字')),
                  );
                }
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changePin() async {
    final pin = await _showPinSetupDialog();
    if (pin != null && pin.length == 4) {
      await _prefs.setPinCode(pin);
      _showSnackBar('PIN 码已更新');
    }
  }

  // ==================== 主题设置 ====================

  Widget _buildThemeSection() {
    return _buildCard(
      children: [
        RadioGroup<String>(
          groupValue: _themeMode,
          onChanged: (value) {
            if (value != null) _switchTheme(value);
          },
          child: const Column(
            children: [
              RadioListTile<String>(
                title: Text('浅色模式'),
                value: 'light',
                activeColor: AppTheme.primaryColor,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
              RadioListTile<String>(
                title: Text('深色模式'),
                value: 'dark',
                activeColor: AppTheme.primaryColor,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _switchTheme(String mode) async {
    await context.read<MoodProvider>().setThemeMode(mode);
    setState(() {
      _themeMode = mode;
    });
    _showSnackBar(mode == 'dark' ? '已切换至深色模式' : '已切换至浅色模式');
  }

  // ==================== 个性化 ====================

  Widget _buildPersonalizationSection() {
    return _buildCard(
      children: [
        _buildActionTile(
          icon: Icons.label_outline,
          iconColor: const Color(0xFF26A69A),
          title: '标签管理',
          subtitle: '自定义情绪触发标签',
          isFirst: true,
          isLast: true,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TagManagementPage()),
            );
          },
        ),
      ],
    );
  }

  // ==================== 数据管理 ====================

  Widget _buildDataManagementSection() {
    return _buildCard(
      children: [
        _buildActionTile(
          icon: Icons.table_chart_outlined,
          iconColor: const Color(0xFF4CAF50),
          title: '导出 CSV',
          subtitle: '导出为表格文件',
          isFirst: true,
          onTap: _exportCsv,
        ),
        _buildDivider(),
        _buildActionTile(
          icon: Icons.picture_as_pdf_outlined,
          iconColor: const Color(0xFFE53935),
          title: '导出 PDF',
          subtitle: '导出为 PDF 报告',
          onTap: _exportPdf,
        ),
        _buildDivider(),
        _buildActionTile(
          icon: Icons.backup_outlined,
          iconColor: const Color(0xFF2196F3),
          title: '数据备份',
          subtitle: '备份所有数据为 JSON',
          onTap: _backupData,
        ),
        _buildDivider(),
        _buildActionTile(
          icon: Icons.restore,
          iconColor: const Color(0xFFFF9800),
          title: '数据恢复',
          subtitle: '从备份文件恢复数据',
          isLast: true,
          onTap: _restoreData,
        ),
      ],
    );
  }

  // ==================== 更多 ====================

  Widget _buildMoreSection() {
    return _buildCard(
      children: [
        _buildActionTile(
          icon: Icons.favorite_border,
          iconColor: const Color(0xFFE8B4B8),
          title: '危机支持',
          subtitle: '心理援助热线 · 你不是一个人',
          isFirst: true,
          isLast: false,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CrisisSupportPage()),
            );
          },
        ),
        _buildActionTile(
          icon: Icons.psychology_outlined,
          iconColor: const Color(0xFF7E57C2),
          title: '心理测评',
          subtitle: 'PHQ-9、GAD-7 等专业量表',
          isFirst: false,
          isLast: true,
          onTap: () {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AssessmentWebPage()));
          },
        ),
      ],
    );
  }

  // ==================== 关于 ====================

  Widget _buildAboutSection() {
    return _buildCard(
      children: [
        _buildActionTile(
          icon: Icons.info_outline,
          iconColor: AppTheme.primaryColor,
          title: '关于作者',
          subtitle: '了解 mood-tab 背后的故事',
          isFirst: true,
          isLast: true,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AboutPage(),
              ),
            );
          },
        ),
      ],
    );
  }

  // ==================== 通用组件 ====================

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBgOf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
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
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textHintOf(context),
                            ),
                      ),
                    ],
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

  // ==================== 数据操作 ====================

  Future<void> _exportCsv() async {
    try {
      final provider = context.read<MoodProvider>();
      final records = provider.allRecords;
      if (records.isEmpty) {
        _showSnackBar('暂无数据可导出');
        return;
      }

      final buffer = StringBuffer();
      buffer.writeln('日期,时间,情绪,强度,备注,标签,日记');

      for (final r in records) {
        final date =
            '${r.createdAt.year}-${r.createdAt.month.toString().padLeft(2, '0')}-${r.createdAt.day.toString().padLeft(2, '0')}';
        final time =
            '${r.createdAt.hour.toString().padLeft(2, '0')}:${r.createdAt.minute.toString().padLeft(2, '0')}';
        final mood = r.moodType.label;
        final intensity = r.intensity.toString();
        final note = _escapeCsv(r.note ?? '');
        final tags = _escapeCsv(r.tags.join(';'));
        final diary = _escapeCsv(r.diary ?? '');
        buffer.writeln('$date,$time,$mood,$intensity,$note,$tags,$diary');
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/mood_tab_export.csv');
      await file.writeAsString(buffer.toString());

      await Share.shareXFiles([XFile(file.path)], text: 'mood-tab 情绪记录导出');
    } catch (e) {
      _showSnackBar('导出失败：$e');
    }
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  Future<void> _exportPdf() async {
    try {
      final provider = context.read<MoodProvider>();
      final records = provider.allRecords;
      if (records.isEmpty) {
        _showSnackBar('暂无数据可导出');
        return;
      }

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'mood-tab 情绪记录报告',
                  style: const pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('导出时间：${DateTime.now().toString().substring(0, 19)}'),
              pw.Text('记录总数：${records.length} 条'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                headers: ['日期', '时间', '情绪', '强度', '备注'],
                data: records.map((r) {
                  return [
                    '${r.createdAt.month}/${r.createdAt.day}',
                    '${r.createdAt.hour.toString().padLeft(2, '0')}:${r.createdAt.minute.toString().padLeft(2, '0')}',
                    r.moodType.label,
                    r.intensity.toString(),
                    r.note ?? '',
                  ];
                }).toList(),
              ),
            ];
          },
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/mood_tab_report.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([XFile(file.path)], text: 'mood-tab 情绪记录报告');
    } catch (e) {
      _showSnackBar('导出失败：$e');
    }
  }

  Future<void> _backupData() async {
    try {
      final data = await _dbService.exportAll();
      if (data.isEmpty) {
        _showSnackBar('暂无数据可备份');
        return;
      }

      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/mood_tab_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonStr);

      await Share.shareXFiles([XFile(file.path)], text: 'mood-tab 数据备份');
    } catch (e) {
      _showSnackBar('备份失败：$e');
    }
  }

  Future<void> _restoreData() async {
    _showSnackBar('请通过文件管理器选择备份文件恢复');
  }

  // ==================== 工具 ====================

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
