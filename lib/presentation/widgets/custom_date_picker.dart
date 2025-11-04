// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 日历组件已定稿，AI不得自动修改
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// Custom Date Picker Component - FINALIZED
// This component is production-ready and has been thoroughly tested.
// AI assistants MUST NOT modify this file without explicit user approval.
//
// 功能特性 (Features):
// • 底部弹出式日历 (Bottom sheet presentation)
// • 特殊日期标签：今天、明天、本周、月底 (Special date labels)
// • 快速日期选择按钮 (Quick date options)
// • 完整国际化支持 (Full i18n support)
// • 防止选择过去日期 (Prevents past date selection)
// • Material 3 设计规范 (Material 3 design compliance)
//
// 修改历史 (Change History):
// 2025-10-29: 初始版本，替换系统日期选择器 (Initial version, replaces system picker)
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../generated/l10n/app_localizations.dart';
import 'custom_date_picker/custom_date_picker_actions.dart';
import 'custom_date_picker/custom_date_picker_calendar.dart';

/// 自定义日期选择对话框，支持在特殊日期下方显示标签
/// 从底部弹出的 BottomSheet 形式
Future<DateTime?> showCustomDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
}) async {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _CustomDatePickerDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: helpText,
    ),
  );
}

class _CustomDatePickerDialog extends StatefulWidget {
  const _CustomDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.helpText,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String? helpText;

  @override
  State<_CustomDatePickerDialog> createState() => _CustomDatePickerDialogState();
}

class _CustomDatePickerDialogState extends State<_CustomDatePickerDialog> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  /// 获取特殊日期的标签
  String? _getSpecialLabel(DateTime date) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    // 今天
    if (targetDate == today) {
      return l10n.dateToday;
    }

    // 明天
    final tomorrow = today.add(const Duration(days: 1));
    if (targetDate == tomorrow) {
      return l10n.dateTomorrow;
    }

    // 本周六（本周的周六）
    final daysUntilSaturday = (DateTime.saturday - now.weekday) % 7;
    final thisSaturday = today.add(
      Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday),
    );
    if (targetDate == thisSaturday) {
      return l10n.datePickerThisWeek;
    }

    // 月底（本月最后一天）
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final lastDay = DateTime(
      lastDayOfMonth.year,
      lastDayOfMonth.month,
      lastDayOfMonth.day,
    );
    if (targetDate == lastDay) {
      return l10n.datePickerMonthEnd;
    }

    return null;
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    });
  }

  /// 构建星期标题（使用用户区域格式）
  List<Widget> _buildWeekdayHeaders(Locale locale) {
    final weekdayFormat = DateFormat.E(locale.toString());
    final theme = Theme.of(context);
    
    // 从周日开始：2024-01-07是周日
    final weekdays = List.generate(7, (index) {
      final date = DateTime(2024, 1, 7 + index); // 从周日开始
      return weekdayFormat.format(date);
    });

    return weekdays.map((day) => Expanded(
      child: Center(
        child: Text(
          day,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final screenHeight = MediaQuery.of(context).size.height;

    // 使用用户区域格式显示日期
    final selectedDateFormat = DateFormat.yMMMd(locale.toString());
    final monthYearFormat = DateFormat.yMMMM(locale.toString());

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: screenHeight * 0.85,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            // 顶部拖拽指示器
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 内容区域（可滚动）
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.helpText != null)
                    Text(
                      widget.helpText!,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    selectedDateFormat.format(_selectedDate),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // 月份导航
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _previousMonth,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    monthYearFormat.format(_displayedMonth),
                    style: theme.textTheme.titleMedium,
                  ),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),

            // 星期标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _buildWeekdayHeaders(locale),
              ),
            ),

            const SizedBox(height: 8),

            // 快捷选项按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: QuickDateOptions(
                onDateSelected: (date) {
                  Navigator.pop(context, date);
                },
              ),
            ),

            const Divider(height: 1),

            // 日历网格（根据内容自适应高度）
            CalendarGrid(
              displayedMonth: _displayedMonth,
              selectedDate: _selectedDate,
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
              getSpecialLabel: _getSpecialLabel,
            ),

            // 操作按钮
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.commonCancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, _selectedDate),
                    child: Text(l10n.commonConfirm),
                  ),
                ],
              ),
            ),
                  ],
                ),
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// _QuickDateOptions, _QuickOptionChip, _CalendarGrid, _DayCell 已移至独立文件
