import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:granoflow/generated/l10n/app_localizations.dart';

import '../../core/providers/app_providers.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../core/services/task_service.dart';
import '../../data/models/task.dart';

class TrashPage extends ConsumerWidget {
  const TrashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskSectionsProvider(TaskSection.trash));
    final l10n = AppLocalizations.of(context);
    return tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return _EmptyState(message: l10n.trashEmptyMessage);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _TrashTile(task: task);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorState(message: '$error'),
      );
  }

  Future<void> _emptyTrash(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.trashConfirmTitle),
        content: Text(l10n.trashConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.trashConfirmAccept),
          ),
        ],
      ),
    );
    if (confirm != true) {
      return;
    }

    try {
      final repository = ref.read(taskRepositoryProvider);
      final service = ref.read(taskServiceProvider);
      final allTasks = await repository.listAll();
      final trashed = allTasks.where((task) => task.status == TaskStatus.trashed);
      for (final task in trashed) {
        await service.updateDetails(
          taskId: task.id,
          payload: const TaskUpdate(status: TaskStatus.pseudoDeleted),
        );
      }
      await repository.purgeObsolete(DateTime.now());
      messenger.showSnackBar(SnackBar(content: Text(l10n.trashEmptySuccess)));
    } catch (error, stackTrace) {
      debugPrint('Failed to empty trash: $error\n$stackTrace');
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.trashEmptyError)),
        );
      }
    }
  }
}

class _TrashTile extends ConsumerWidget {
  const _TrashTile({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final service = ref.read(taskServiceProvider);
    final l10n = AppLocalizations.of(context);
    return ListTile(
      tileColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(task.title, style: theme.textTheme.titleMedium),
      subtitle: Text('ID: ${task.taskId}'),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            tooltip: l10n.actionRestore,
            icon: const Icon(Icons.restore_outlined),
            onPressed: () => _restore(context, service),
          ),
          IconButton(
            tooltip: l10n.trashConfirmAccept,
            icon: const Icon(Icons.delete_forever_outlined),
            onPressed: () => _delete(context, ref, service),
          ),
        ],
      ),
    );
  }

  Future<void> _restore(BuildContext context, TaskService service) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await service.updateDetails(
        taskId: task.id,
        payload: const TaskUpdate(status: TaskStatus.pending),
      );
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.trashRestoreSuccess)));
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to restore task: $error\n$stackTrace');
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.trashRestoreError)));
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    TaskService service,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await service.updateDetails(
        taskId: task.id,
        payload: const TaskUpdate(status: TaskStatus.pseudoDeleted),
      );
      await ref.read(taskRepositoryProvider).purgeObsolete(DateTime.now());
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.trashDeleteSuccess)));
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to permanently delete task: $error\n$stackTrace');
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.trashDeleteError)));
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
