import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:granoflow/generated/l10n/app_localizations.dart';

import '../../core/providers/app_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../core/services/task_service.dart';
import '../../data/models/task.dart';
import '../widgets/page_app_bar.dart';
import '../widgets/main_drawer.dart';
import '../widgets/gradient_page_scaffold.dart';

class ArchivedPage extends ConsumerWidget {
  const ArchivedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    
    return GradientPageScaffold(
      appBar: PageAppBar(
        title: l10n.archivedTabLabel,
      ),
      drawer: const MainDrawer(),
      body: const _ArchivedList(),
    );
  }
}

class _ArchivedList extends ConsumerWidget {
  const _ArchivedList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tasksAsync = ref.watch(taskSectionsProvider(TaskSection.archived));
    return tasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return _EmptyState(message: l10n.completedEmptyMessage);
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final task = tasks[index];
            return _ArchivedTile(task: task);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _ErrorState(message: '$error'),
    );
  }
}

class _ArchivedTile extends ConsumerWidget {
  const _ArchivedTile({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final subtitle = 'ID: ${task.taskId}';
    final taskService = ref.read(taskServiceProvider);
    
    return ListTile(
      tileColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(task.title, style: theme.textTheme.titleMedium),
      subtitle: Text(subtitle),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            tooltip: l10n.actionRestore,
            icon: const Icon(Icons.unarchive_outlined),
            onPressed: () => _reactivate(context, ref, task, taskService),
          ),
          IconButton(
            tooltip: l10n.actionMoveToTrash,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _moveToTrash(context, ref, task, taskService),
          ),
        ],
      ),
    );
  }

  Future<void> _reactivate(
    BuildContext context,
    WidgetRef ref,
    Task task,
    TaskService service,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await service.updateDetails(
        taskId: task.id,
        payload: const TaskUpdate(status: TaskStatus.pending),
      );
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.completedReactivateSuccess)),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to reactivate task: $error\n$stackTrace');
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.completedReactivateError)),
        );
      }
    }
  }

  Future<void> _moveToTrash(
    BuildContext context,
    WidgetRef ref,
    Task task,
    TaskService service,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await service.softDelete(task.id);
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.completedTrashSuccess)),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to move task to trash: $error\n$stackTrace');
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.completedTrashError)),
        );
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
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
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

