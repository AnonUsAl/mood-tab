import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mood_record.dart';
import '../models/mood_type.dart';
import '../providers/mood_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/intensity_dots.dart';
import 'mood_record_page.dart';

/// 日历视图页面
/// 月历展示每日情绪颜色，点击某天查看当天所有记录
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;
  int _monthChangeDirection = 1;

  // 本月记录的分组缓存：provider.allRecords 换了对象、或者切了月份才重算。
  List<MoodRecord>? _cachedSource;
  int? _cachedYear;
  int? _cachedMonth;
  Map<String, List<MoodRecord>> _cachedGrouped = const {};

  @override
  void initState() {
    super.initState();
    // 自动选中今天，使首次打开日历时直接显示当天记录
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  /// 分组 / 查表用的日期键，必须与 `_buildCalendarGrid` 里保持一致。
  static String _dayKey(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';

  /// 按天分组当前聚焦月份的记录。
  ///
  /// 这里**不再按日期范围查库**，而是直接从 `provider.allRecords` 内存筛选：
  ///
  /// - provider 启动时已经用 `getAllRecords()`（无 WHERE 条件）把所有记录读进
  ///   内存，日历再往返一次数据库是多余的；
  /// - 那条带 `whereArgs` 的范围查询是本页唯一的异步依赖，一旦它卡住或抛异常，
  ///   页面就会一直转圈、月份数据永远出不来。改走内存筛选后本页不再有异步加载，
  ///   从结构上消除「月份数据一直无法加载」。
  Map<String, List<MoodRecord>> _groupedMonths(MoodProvider provider) {
    final all = provider.allRecords;
    if (identical(_cachedSource, all) &&
        _cachedYear == _focusedMonth.year &&
        _cachedMonth == _focusedMonth.month) {
      return _cachedGrouped;
    }

    final grouped = <String, List<MoodRecord>>{};
    for (final r in all) {
      if (r.createdAt.year != _focusedMonth.year ||
          r.createdAt.month != _focusedMonth.month) {
        continue;
      }
      grouped.putIfAbsent(_dayKey(r.createdAt), () => []).add(r);
    }

    _cachedSource = all;
    _cachedYear = _focusedMonth.year;
    _cachedMonth = _focusedMonth.month;
    _cachedGrouped = grouped;
    return grouped;
  }

  void _loadSelectedDay(DateTime date) {
    setState(() => _selectedDate = date);
  }

  void _changeMonth(int delta) {
    setState(() {
      _monthChangeDirection = delta > 0 ? 1 : -1;
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + delta,
        1,
      );
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 直接监听 provider：记录增删改后 provider 会 notify，日历自动跟着刷新，
    // 不需要再自己注册 listener + 手动重载一轮数据。
    final provider = context.watch<MoodProvider>();
    final monthRecords = _groupedMonths(provider);

    // 仅「首次启动、provider 还在读库」时转圈；读完就一律渲染日历本体，
    // 不再存在「页面自己加载失败」这种中间态。
    final bool initialLoading =
        provider.isLoading && provider.allRecords.isEmpty;

    final String? selectedKey = _selectedDate == null
        ? null
        : _dayKey(_selectedDate!);
    final List<MoodRecord> selectedDayRecords = selectedKey == null
        ? const <MoodRecord>[]
        : (monthRecords[selectedKey] ?? const <MoodRecord>[]);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildWeekdayLabels(),
            Expanded(
              child: Stack(
                children: [
                  _buildAnimatedCalendarGrid(monthRecords),
                  if (initialLoading)
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: ColoredBox(
                          color: Colors.transparent,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_selectedDate != null)
              _buildSelectedDayDetail(selectedDayRecords),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCalendarGrid(
    Map<String, List<MoodRecord>> monthRecords,
  ) {
    final monthKey = '${_focusedMonth.year}-${_focusedMonth.month}';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 360),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) =>
          currentChild ?? const SizedBox.shrink(),
      transitionBuilder: (child, animation) {
        final begin = Offset(-_monthChangeDirection.toDouble(), 0);
        return SlideTransition(
          position: animation.drive(
            Tween<Offset>(
              begin: begin,
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic)),
          ),
          child: child,
        );
      },
      child: KeyedSubtree(
        key: ValueKey(monthKey),
        child: _buildCalendarGrid(monthRecords),
      ),
    );
  }

  Widget _buildHeader() {
    final monthNames = [
      '一月',
      '二月',
      '三月',
      '四月',
      '五月',
      '六月',
      '七月',
      '八月',
      '九月',
      '十月',
      '十一月',
      '十二月',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Text(
            '${_focusedMonth.year}年 ${monthNames[_focusedMonth.month - 1]}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left, size: 28),
            color: AppTheme.textSecondaryOf(context),
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right, size: 28),
            color: AppTheme.textSecondaryOf(context),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayLabels() {
    final labels = ['一', '二', '三', '四', '五', '六', '日'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: labels.map((label) {
          return Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textHintOf(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(Map<String, List<MoodRecord>> monthRecords) {
    final firstOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    // 周一=1, 周日=7 → 转为索引 0-6
    final firstWeekday = (firstOfMonth.weekday - 1);

    final today = DateTime.now();
    final isCurrentMonth =
        today.year == _focusedMonth.year && today.month == _focusedMonth.month;

    final int rowCount = ((firstWeekday + daysInMonth) / 7).ceil();

    return ClipRect(
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < -300) {
            _changeMonth(1); // 左滑 → 下个月
          } else if (details.primaryVelocity! > 300) {
            _changeMonth(-1); // 右滑 → 上个月
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            const double hPadding = 12;
            const double spacing = 4;
            // 低于这个高度，日格里的「日期 + 情绪圆点」就挤不下了。
            // 与其把内容裁掉，不如让网格可以滚动。
            const double minCellHeight = 46;

            final double availableWidth = constraints.maxWidth - hPadding * 2;
            double cellWidth = (availableWidth - spacing * 6) / 7;
            if (cellWidth <= 0) cellWidth = 1;

            // 竖屏原设计比例：宽高比 0.85 → 单元格高 = 宽 / 0.85
            final double idealCellHeight = cellWidth / 0.85;

            final double fittedCellHeight = constraints.maxHeight.isFinite
                ? (constraints.maxHeight - spacing * (rowCount - 1)) / rowCount
                : idealCellHeight;

            // 高度宽裕 → 用理想比例，但压到可用高度内，保证每行都看得见；
            // 高度不足 → 锁在最小可读高度，并允许滚动。
            final bool scrollable = fittedCellHeight < minCellHeight;
            final double cellHeight;
            if (scrollable) {
              cellHeight = minCellHeight;
            } else {
              cellHeight = fittedCellHeight < idealCellHeight
                  ? fittedCellHeight
                  : idealCellHeight;
            }

            final double aspectRatio = cellHeight <= 0
                ? 1.0
                : cellWidth / cellHeight;

            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: hPadding),
              // 关键：装得下就不滚（保留左右滑动切月的手势），
              // 装不下必须能滚。原来一律 NeverScrollableScrollPhysics，
              // 窗口一拉宽单元格跟着变大，后面几行就被压出可视区且无法滚动。
              physics: scrollable
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: aspectRatio,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
              ),
              itemCount: firstWeekday + daysInMonth,
              itemBuilder: (context, index) {
                if (index < firstWeekday) {
                  return const SizedBox.shrink();
                }
                final day = index - firstWeekday + 1;
                final date = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month,
                  day,
                );
                final dayRecords = monthRecords[_dayKey(date)] ?? const [];
                final isToday = isCurrentMonth && day == today.day;
                final isSelected =
                    _selectedDate?.day == day &&
                    _selectedDate?.month == _focusedMonth.month &&
                    _selectedDate?.year == _focusedMonth.year;

                return _buildDayCell(
                  date: date,
                  day: day,
                  records: dayRecords,
                  isToday: isToday,
                  isSelected: isSelected,
                  onTap: () => _loadSelectedDay(date),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDayCell({
    required DateTime date,
    required int day,
    required List<MoodRecord> records,
    required bool isToday,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final hasRecords = records.isNotEmpty;

    // 如果有记录，取最主要情绪的颜色
    Color? moodColor;
    if (hasRecords) {
      final counts = <MoodType, int>{};
      for (final r in records) {
        counts[r.moodType] = (counts[r.moodType] ?? 0) + 1;
      }
      final topMood = counts.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      moodColor = Color(topMood.key.colorValue);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.15)
              : (moodColor != null
                    ? moodColor.withValues(alpha: 0.12)
                    : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
          border: isToday
              ? Border.all(color: AppTheme.primaryColor, width: 1.5)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          // 格子高度会随窗口变化，固定字号的「日期 + 圆点 + 条数」很容易撑破
          // 单元格（黄色溢出条纹）。scaleDown 只在不合身时等比缩小，正常尺寸
          // 下完全不生效。
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday || isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isToday
                        ? AppTheme.primaryColor
                        : (hasRecords
                              ? AppTheme.textPrimaryOf(context)
                              : AppTheme.textHintOf(context)),
                  ),
                ),
                const SizedBox(height: 2),
                if (hasRecords) ...[
                  // 情绪圆点指示
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: records.take(3).map((r) {
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(r.moodType.colorValue),
                        ),
                      );
                    }).toList(),
                  ),
                  if (records.length > 3)
                    Text(
                      '${records.length}',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppTheme.textHintOf(context),
                      ),
                    ),
                ] else
                  const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 选中日期的详情。记录由 `build` 从 provider 派生后传进来，
  /// 这里不再自己持有数据、也不再触发重载 —— 新增/编辑后 provider 会 notify，
  /// `context.watch` 会让整页（含这里）自动刷新。
  Widget _buildSelectedDayDetail(List<MoodRecord> records) {
    if (records.isEmpty) {
      // 无记录 — 显示补记按钮
      final now = DateTime.now();
      final isToday =
          _selectedDate!.year == now.year &&
          _selectedDate!.month == now.month &&
          _selectedDate!.day == now.day;
      final isFuture = _selectedDate!.isAfter(
        DateTime(now.year, now.month, now.day),
      );

      return Container(
        height: 100,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isFuture ? '未来的日期还没到来' : '这天没有记录',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textHintOf(context),
              ),
            ),
            if (!isFuture) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MoodRecordPage(
                        initialDate: isToday ? null : _selectedDate!,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.event_note, size: 16),
                label: Text(isToday ? '记录今天的心情' : '补记这天的心情'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_selectedDate!.month}月${_selectedDate!.day}日 · ${records.length} 条记录',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                // 继续补记按钮
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            MoodRecordPage(initialDate: _selectedDate!),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('追加'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    textStyle: const TextStyle(fontSize: 12),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return _buildDayRecordCard(record);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayRecordCard(MoodRecord record) {
    final moodColor = Color(record.moodType.colorValue);
    final hour = record.createdAt.hour.toString().padLeft(2, '0');
    final minute = record.createdAt.minute.toString().padLeft(2, '0');

    return GestureDetector(
      onTap: () => _editRecord(record),
      onLongPress: () => _showRecordActions(record),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBgOf(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: moodColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: Text(
                  record.moodType.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        record.moodType.label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 8),
                      IntensityDots(
                        intensity: record.intensity,
                        color: moodColor,
                        size: 6,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$hour:$minute',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textHintOf(context),
                    ),
                  ),
                  if (record.note != null && record.note!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      record.note!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 点击记录卡片 → 直接进入编辑。
  /// 编辑保存后 provider 会 notifyListeners，`context.watch` 会让日历自动刷新，
  /// 因此这里不需要（也不应该）再手动重载一次。
  Future<void> _editRecord(MoodRecord record) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MoodRecordPage(existingRecord: record)),
    );
  }

  /// 长按记录卡片 → 弹出编辑/删除操作菜单
  void _showRecordActions(MoodRecord record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBgOf(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 拖拽条
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.textHintOf(context).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      Text(
                        record.moodType.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        record.moodType.label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('修改这条记录'),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MoodRecordPage(existingRecord: record),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: Colors.red.shade400,
                  ),
                  title: Text(
                    '删除这条记录',
                    style: TextStyle(color: Colors.red.shade400),
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final shouldDelete = await _confirmDelete(record) ?? false;
                    if (shouldDelete && mounted) {
                      await context.read<MoodProvider>().deleteRecord(
                        record.id!,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('记录已删除'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDelete(MoodRecord record) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('删除这条记录？'),
          content: Text('删除后无法恢复。确定要删除这条${record.moodType.label}记录吗？'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }
}
