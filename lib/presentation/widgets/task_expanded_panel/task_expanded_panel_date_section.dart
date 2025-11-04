import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import 'task_expanded_panel_date_actions.dart';

/// 任务展开面板的日期部分组件
class TaskExpandedPanelDateSection extends StatelessWidget {
  const TaskExpandedPanelDateSection({
    super.key,
    required this.task,
    required this.localeName,
    this.taskLevel,
    this.onDateChanged,
  });

  final Task task;
  final String localeName;
  final int? taskLevel;
  final ValueChanged<DateTime?>? onDateChanged;

  @override
  Widget build(BuildContext context) {
    // 如果是子任务（level > 1），不显示日期部分
    if (taskLevel != null && taskLevel! > 1) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            task.dueAt == null
                ? l10n.noDueDateSet
                : DateFormat.yMMMd(localeName).format(task.dueAt!),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => selectTaskDate(context, task, localeName, onDateChanged),
          icon: const Icon(Icons.calendar_today, size: 16),
          label: Text(l10n.inboxPlanButtonLabel),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }
}

