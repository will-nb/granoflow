import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../utils/tag_utils.dart';
import '../utils/date_utils.dart';
import 'status_chip.dart';

class TaskHeaderRow extends ConsumerWidget {
  const TaskHeaderRow({
    super.key,
    required this.task,
    this.showConvertAction = false,
    this.leading,
    this.useBodyText = false,
    this.taskLevel, // 任务的层级（level），用于判断是否是子任务
  });

  final Task task;
  final bool showConvertAction;
  final Widget? leading;
  final bool useBodyText;

  /// 任务的层级（level），用于判断是否是子任务
  /// level > 1 表示是子任务，子任务不显示截止日期
  final int? taskLevel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final tagChips = buildTagChips(context, task);
    final deadlineLabel = formatDeadline(context, task.dueAt);
    final overdue = task.dueAt != null && task.dueAt!.isBefore(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null)
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 4),
                child: leading!,
              ),
            Expanded(
              child: InkWell(
                onTap: () => _handleTitleTap(context, ref),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    task.title,
                    style: useBodyText
                        ? theme.textTheme.bodyLarge
                        : theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w400),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            if (showConvertAction)
              IconButton(
                onPressed: () => _confirmConvert(context, ref),
                tooltip: l10n.projectConvertTooltip,
                icon: Icon(Icons.autorenew, color: theme.colorScheme.primary),
              ),
          ],
        ),
        // 如果是子任务（level > 1），不显示截止日期
        if (deadlineLabel != null && (taskLevel == null || taskLevel! <= 1))
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${l10n.projectDeadlineLabel} $deadlineLabel',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
        if (tagChips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(spacing: 8, runSpacing: 6, children: tagChips),
          ),
        if (overdue)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: StatusChip(
              label: l10n.projectStatusOverdue,
              color: theme.colorScheme.error,
            ),
          ),
      ],
    );
  }

  Future<void> _handleTitleTap(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: task.title);

    final newTitle = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.taskEditTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 3000,
          decoration: InputDecoration(
            hintText: l10n.taskTitleHint,
            border: const OutlineInputBorder(),
            counterText: '',
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.of(dialogContext).pop(value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.of(dialogContext).pop(value);
              }
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );

    controller.dispose();

    if (newTitle != null && newTitle != task.title) {
      try {
        final taskService = await ref.read(taskServiceProvider.future);
        await taskService.updateDetails(
          taskId: task.id,
          payload: TaskUpdate(title: newTitle),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.taskUpdateSuccess),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.taskUpdateError}: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmConvert(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.projectConvertDialogTitle),
        content: Text(l10n.projectConvertDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.projectConvertConfirm),
          ),
        ],
      ),
    );
    if (result != true) {
      return;
    }

    try {
      final projectService = await ref.read(projectServiceProvider.future);
      await projectService.convertTaskToProject(task.id);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.projectConvertSuccess)));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.projectConvertError}: $error')),
      );
    }
  }
}
