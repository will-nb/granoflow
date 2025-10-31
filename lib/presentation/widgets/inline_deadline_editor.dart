import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../generated/l10n/app_localizations.dart';
import 'custom_date_picker.dart';

/// 可内联编辑的截止日期显示组件
/// 支持点击编辑、相对时间格式、过期警告
class InlineDeadlineEditor extends StatelessWidget {
  const InlineDeadlineEditor({
    super.key,
    required this.deadline,
    required this.onDeadlineChanged,
    this.showIcon = true,
  });

  final DateTime? deadline;
  final ValueChanged<DateTime?> onDeadlineChanged;
  final bool showIcon;

  /// 格式化截止日期为相对时间（不显示时间）
  String _formatDeadline(BuildContext context, DateTime deadline) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);
    final difference = deadlineDate.difference(today).inDays;

    // 特殊相对时间：只显示今天和明天
    if (difference == 0) {
      return l10n.dateToday;
    } else if (difference == 1) {
      return l10n.dateTomorrow;
    } else if (difference == -1) {
      return l10n.dateYesterday;
    }
    
    // 其他时间使用用户区域格式显示日期
    if (deadline.year == now.year) {
      // 同一年，显示月日：如 "10月29日" 或 "Oct 29"
      final dateFormat = DateFormat.MMMd(locale.toString());
      return dateFormat.format(deadline);
    } else {
      // 不同年，显示年月日：如 "2025年10月29日" 或 "Oct 29, 2025"
      final dateFormat = DateFormat.yMMMd(locale.toString());
      return dateFormat.format(deadline);
    }
  }

  /// 检查是否过期
  bool _isOverdue(DateTime deadline) {
    return deadline.isBefore(DateTime.now());
  }

  /// 检查是否即将到期（24小时内）
  bool _isDueSoon(DateTime deadline) {
    final now = DateTime.now();
    final diff = deadline.difference(now);
    return !_isOverdue(deadline) && diff.inHours <= 24 && diff.inHours > 0;
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate = deadline != null 
        ? DateTime(deadline!.year, deadline!.month, deadline!.day)
        : today;

    // 使用自定义日期选择器，支持特殊日期标签显示
    final pickedDate = await showCustomDatePicker(
      context: context,
      initialDate: initialDate.isBefore(today) ? today : initialDate,
      firstDate: today, // 不能选择今天之前的日期
      lastDate: DateTime(now.year + 10, 12, 31),
      helpText: l10n.taskEditDeadline,
    );

    if (pickedDate == null) return;

    // 统一设置为当天的 23:59:59
    final newDeadline = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      23,
      59,
      59,
    );

    onDeadlineChanged(newDeadline);
  }

  Future<void> _showClearConfirmation(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.taskClearDeadlineTitle),
        content: Text(l10n.taskClearDeadlineBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );

    if (result == true) {
      onDeadlineChanged(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // 无截止日期 - Minimal 风格
    if (deadline == null) {
      final color = theme.colorScheme.primary;
      return InkWell(
        onTap: () => _pickDateTime(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon)
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: color,
                ),
              if (showIcon) const SizedBox(width: 4),
              Text(
                l10n.taskSetDeadline,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 有截止日期 - Minimal 风格
    final isOverdue = _isOverdue(deadline!);
    final isDueSoon = _isDueSoon(deadline!);
    final formattedDeadline = _formatDeadline(context, deadline!);

    Color color;
    String displayText;
    IconData iconData;

    if (isOverdue) {
      color = theme.colorScheme.error;
      displayText = l10n.taskDeadlineOverdue;
      iconData = Icons.warning_outlined;
    } else if (isDueSoon) {
      color = theme.colorScheme.tertiary;
      displayText = l10n.taskDeadlineSoon;
      iconData = Icons.alarm_outlined;
    } else {
      color = theme.colorScheme.secondary;
      displayText = formattedDeadline;
      iconData = Icons.calendar_today_outlined;
    }

    return InkWell(
      onTap: () => _pickDateTime(context),
      onLongPress: () => _showClearConfirmation(context),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon)
              Icon(
                iconData,
                size: 14,
                color: color,
              ),
            if (showIcon) const SizedBox(width: 4),
            Text(
              displayText,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
