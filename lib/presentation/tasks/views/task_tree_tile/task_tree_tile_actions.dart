import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/service_providers.dart';
import '../../../../data/models/task.dart';
import '../../../../generated/l10n/app_localizations.dart';

/// 显示添加子任务对话框
Future<void> showAddSubtaskDialog(
  BuildContext context,
  WidgetRef ref,
  String parentId,
) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.actionAddSubtask),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 100,
        decoration: InputDecoration(hintText: l10n.taskTitleHint),
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
          child: Text(l10n.commonAdd),
        ),
      ],
    ),
  );

  if (result == null || result.isEmpty) {
    return;
  }

  final notifier = ref.read(taskEditActionsNotifierProvider.notifier);
  try {
    await notifier.addSubtask(parentId: parentId, title: result);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.taskListSubtaskCreatedToast)));
  } catch (error, stackTrace) {
    debugPrint('Failed to create subtask: $error\n$stackTrace');
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.taskListSubtaskError)));
  }
}

/// 显示重命名对话框
Future<void> showRenameDialog(
  BuildContext context,
  WidgetRef ref,
  Task task,
) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController(text: task.title);
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.taskListRenameDialogTitle),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 100,
        decoration: InputDecoration(hintText: l10n.taskTitleHint),
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

  if (result == null || result == task.title) {
    return;
  }

  final taskService = await ref.read(taskServiceProvider.future);
  await taskService.updateDetails(
    taskId: task.id,
    payload: TaskUpdate(title: result),
  );
}

/// 归档任务
Future<void> archiveTask(
  BuildContext context,
  WidgetRef ref,
  String taskId,
) async {
  final notifier = ref.read(taskEditActionsNotifierProvider.notifier);
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  try {
    await notifier.archive(taskId);
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.taskListTaskArchivedToast)),
    );
  } catch (error, stackTrace) {
    debugPrint('Failed to archive task: $error\n$stackTrace');
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.taskListTaskArchivedError)),
    );
  }
}

