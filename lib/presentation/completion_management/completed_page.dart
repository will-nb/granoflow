import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:granoflow/generated/l10n/app_localizations.dart';

import '../../core/providers/app_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../core/services/task_service.dart';
import '../../data/models/task.dart';
import '../widgets/page_app_bar.dart';
import '../widgets/main_drawer.dart';

class CompletedPage extends ConsumerWidget {
  const CompletedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const PageAppBar(
        title: 'Completed',
      ),
      drawer: const MainDrawer(),
      body: DefaultTabController(
        length: 2,
        child: const TabBarView(
          children: [
            _CompletionList(section: TaskSection.completed),
            _CompletionList(section: TaskSection.archived),
          ],
        ),
      ),
    );
  }
}

class _CompletionList extends ConsumerWidget {
  const _CompletionList({required this.section});

  final TaskSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tasksAsync = ref.watch(taskSectionsProvider(section));
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
            return _CompletionTile(section: section, task: task);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _ErrorState(message: '$error'),
    );
  }
}

class _CompletionTile extends ConsumerWidget {
  const _CompletionTile({required this.section, required this.task});

  final TaskSection section;
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final subtitle = 'ID: ${task.taskId}';
    final actions = _actions(context, ref, l10n);
    return ListTile(
      tileColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Text(task.title, style: theme.textTheme.titleMedium),
      subtitle: Text(subtitle),
      trailing: Wrap(spacing: 4, children: actions),
    );
  }

  List<Widget> _actions(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final taskService = ref.read(taskServiceProvider);
    switch (section) {
      case TaskSection.completed:
        return [
          IconButton(
            tooltip: l10n.actionReactivate,
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => _reactivate(context, ref, task, taskService),
          ),
          IconButton(
            tooltip: l10n.actionArchive,
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => _archive(context, ref, task, taskService),
          ),
          IconButton(
            tooltip: l10n.actionMoveToTrash,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _moveToTrash(context, ref, task, taskService),
          ),
        ];
      case TaskSection.archived:
        return [
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
        ];
      default:
        return const <Widget>[];
    }
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

  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    Task task,
    TaskService service,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await service.archive(task.id);
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.completedArchiveSuccess)),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to archive task: $error\n$stackTrace');
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.completedArchiveError)),
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
