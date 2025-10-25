import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_color_tokens.dart';
import '../../data/models/tag.dart';
import '../../data/models/task.dart';
import '../../data/models/task_template.dart';
import '../../generated/l10n/app_localizations.dart';
import '../navigation/navigation_destinations.dart';
import '../widgets/chip_toggle_group.dart';
import '../widgets/page_app_bar.dart';
import '../widgets/main_drawer.dart';

class InboxPage extends ConsumerStatefulWidget {
  const InboxPage({super.key});

  @override
  ConsumerState<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends ConsumerState<InboxPage> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _isSubmitting = false;
  String _currentQuery = '';

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filter = ref.watch(inboxFilterProvider);
    final tasksAsync = ref.watch(inboxTasksProvider);
    final templateSuggestions = ref.watch(
      templateSuggestionsProvider(
        TemplateSuggestionQuery(text: _currentQuery.isEmpty ? null : _currentQuery, limit: 6),
      ),
    );
    final contextTagsAsync = ref.watch(contextTagOptionsProvider);
    final priorityTagsAsync = ref.watch(priorityTagOptionsProvider);

    return Scaffold(
      appBar: const PageAppBar(
        title: 'Inbox',
      ),
      drawer: const MainDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PersistentInboxInput(
                    controller: _inputController,
                    focusNode: _inputFocusNode,
                    placeholder: l10n.inboxQuickAddPlaceholder,
                    isSubmitting: _isSubmitting,
                    onChanged: (value) {
                      setState(() {
                        _currentQuery = value;
                      });
                    },
                    onSubmit: (value) => _handleSubmit(context, value),
                  ),
                  const SizedBox(height: 12),
                  templateSuggestions.when(
                    data: (templates) => TemplateSuggestionWrap(
                      templates: templates,
                      onApply: (template) => _applyTemplate(context, template),
                      emptyLabel: l10n.inboxTemplateEmpty,
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => _ErrorBanner(message: '$error'),
                  ),
                  const SizedBox(height: 16),
                  contextTagsAsync.when(
                    data: (tags) => ChipToggleGroup(
                      options: _toChipOptions(tags, l10n.localeName),
                      selectedValues: {if (filter.contextTag != null) filter.contextTag!},
                      onSelectionChanged: (values) {
                        final next = values.isEmpty ? null : values.first;
                        ref.read(inboxFilterProvider.notifier).setContextTag(next);
                      },
                      multiSelect: false,
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (error, stackTrace) => _ErrorBanner(message: '$error'),
                  ),
                  const SizedBox(height: 8),
                  priorityTagsAsync.when(
                    data: (tags) => ChipToggleGroup(
                      options: _toChipOptions(tags, l10n.localeName),
                      selectedValues: {if (filter.priorityTag != null) filter.priorityTag!},
                      onSelectionChanged: (values) {
                        final next = values.isEmpty ? null : values.first;
                        ref.read(inboxFilterProvider.notifier).setPriorityTag(next);
                      },
                      multiSelect: false,
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (error, stackTrace) => _ErrorBanner(message: '$error'),
                  ),
                ],
              ),
            ),
          ),
          tasksAsync.when(
            data: (tasks) {
              if (tasks.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: InboxEmptyStateCard(
                      title: l10n.inboxEmptyTitle,
                      message: l10n.inboxEmptyMessage,
                      actionLabel: l10n.inboxEmptyAction,
                      onAction: () {
                        final navigator = Navigator.of(context);
                        navigator.popUntil((route) => route.isFirst);
                        ref.read(navigationIndexProvider.notifier).state =
                            NavigationDestinations.tasks.index;
                      },
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final task = tasks[index];
                  return InboxTaskTile(task: task, localeName: l10n.localeName);
                }, childCount: tasks.length),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, stackTrace) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _ErrorBanner(message: '$error'),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }

  Future<void> _handleSubmit(BuildContext context, String value) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final title = value.trim();
    if (title.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.inboxInputEmpty)));
      return;
    }
    setState(() => _isSubmitting = true);
    final taskService = ref.read(taskServiceProvider);
    try {
      await taskService.captureInboxTask(title: title);
      if (!context.mounted) {
        return;
      }
      _inputController.clear();
      _focusNodeRequest();
      messenger.showSnackBar(SnackBar(content: Text(l10n.inboxAddedToast)));
    } catch (error, stackTrace) {
      debugPrint('Failed to add inbox task: $error\n$stackTrace');
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text('${l10n.inboxAddError}: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _applyTemplate(BuildContext context, TaskTemplate template) async {
    final templateService = ref.read(taskTemplateServiceProvider);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await templateService.applyTemplate(templateId: template.id);
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.inboxTemplateApplied)));
    } catch (error, stackTrace) {
      debugPrint('Failed to apply template in inbox: $error\n$stackTrace');
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text('${l10n.inboxTemplateError}: $error')));
    }
  }

  void _focusNodeRequest() {
    Future.microtask(() {
      if (_inputFocusNode.canRequestFocus) {
        _inputFocusNode.requestFocus();
      }
    });
  }

  List<ChipToggleOption> _toChipOptions(List<Tag> tags, String localeName) {
    return tags
        .map((tag) => ChipToggleOption(value: tag.slug, label: tag.labelForLocale(localeName)))
        .toList(growable: false);
  }
}

class PersistentInboxInput extends StatelessWidget {
  const PersistentInboxInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.placeholder,
    required this.isSubmitting,
    required this.onChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String placeholder;
  final bool isSubmitting;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: !isSubmitting,
      textInputAction: TextInputAction.done,
      onChanged: onChanged,
      onSubmitted: onSubmit,
      decoration: InputDecoration(
        hintText: placeholder,
        suffixIcon: isSubmitting
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.send),
                tooltip: l10n.commonAdd,
                onPressed: () => onSubmit(controller.text),
              ),
      ),
    );
  }
}

class TemplateSuggestionWrap extends StatelessWidget {
  const TemplateSuggestionWrap({
    super.key,
    required this.templates,
    required this.onApply,
    required this.emptyLabel,
  });

  final List<TaskTemplate> templates;
  final ValueChanged<TaskTemplate> onApply;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(emptyLabel, style: Theme.of(context).textTheme.bodySmall),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: templates
          .map(
            (template) => ActionChip(
              label: Text(template.title),
              avatar: const Icon(Icons.auto_awesome_outlined),
              onPressed: () => onApply(template),
            ),
          )
          .toList(growable: false),
    );
  }
}

class InboxTaskTile extends ConsumerWidget {
  const InboxTaskTile({super.key, required this.task, required this.localeName});

  final Task task;
  final String localeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expandedId = ref.watch(inboxExpandedTaskIdProvider);
    final isExpanded = expandedId == task.id;
    final l10n = AppLocalizations.of(context);

    final contextTag = task.tags.firstWhere((tag) => tag.startsWith('@'), orElse: () => '');
    final priorityTag = task.tags.firstWhere((tag) => tag.startsWith('#'), orElse: () => '');

    final messenger = ScaffoldMessenger.of(context);
    final taskService = ref.read(taskServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.colorTokens;

    return Dismissible(
      key: ValueKey('inbox-${task.id}-${task.updatedAt.millisecondsSinceEpoch}'),
      background: _DismissBackground(
        alignment: Alignment.centerLeft,
        icon: Icons.calendar_today,
        label: l10n.inboxQuickPlanAction,
        backgroundColor: tokens.success,
        foregroundColor: tokens.onSuccess,
      ),
      secondaryBackground: _DismissBackground(
        alignment: Alignment.centerRight,
        icon: Icons.delete_outline,
        label: l10n.inboxDeleteAction,
        backgroundColor: colorScheme.error,
        foregroundColor: colorScheme.onError,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _quickPlan(context, ref, task);
          return false;
        }
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.inboxDeleteConfirmTitle),
            content: Text(l10n.inboxDeleteConfirmMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.commonDelete),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await taskService.softDelete(task.id);
          if (!context.mounted) {
            return false;
          }
          messenger.showSnackBar(SnackBar(content: Text(l10n.inboxDeletedToast)));
        }
        return false;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: InkWell(
          onTap: () {
            ref.read(inboxExpandedTaskIdProvider.notifier).state = isExpanded ? null : task.id;
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(task.title, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text('ID: ${task.taskId}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                  ],
                ),
                if (contextTag.isNotEmpty || priorityTag.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (contextTag.isNotEmpty) Chip(label: Text(contextTag)),
                      if (priorityTag.isNotEmpty) Chip(label: Text(priorityTag)),
                    ],
                  ),
                ],
                if (isExpanded) ...[
                  const SizedBox(height: 12),
                  _ExpandedInboxControls(task: task, localeName: localeName),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _quickPlan(BuildContext context, WidgetRef ref, Task task) async {
    final taskService = ref.read(taskServiceProvider);
    final now = DateTime.now();
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await taskService.planTask(taskId: task.id, dueDateLocal: now, section: TaskSection.today);
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.inboxQuickPlanSuccess)));
    } catch (error, stackTrace) {
      debugPrint('Failed to quick plan task: $error\n$stackTrace');
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text('${l10n.inboxPlanError}: $error')));
    }
  }
}

class _ExpandedInboxControls extends ConsumerStatefulWidget {
  const _ExpandedInboxControls({required this.task, required this.localeName});

  final Task task;
  final String localeName;

  @override
  ConsumerState<_ExpandedInboxControls> createState() => _ExpandedInboxControlsState();
}

class _ExpandedInboxControlsState extends ConsumerState<_ExpandedInboxControls> {
  bool _isPlanning = false;
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final contextTags = ref.watch(contextTagOptionsProvider);
    final priorityTags = ref.watch(priorityTagOptionsProvider);
    final task = widget.task;
    final contextTag = task.tags.firstWhere((tag) => tag.startsWith('@'), orElse: () => '');
    final priorityTag = task.tags.firstWhere((tag) => tag.startsWith('#'), orElse: () => '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                DateFormat.yMMMd().add_jm().format(task.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            IconButton(
              tooltip: l10n.taskListRenameDialogTitle,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _renameTask(context, task),
            ),
            IconButton(
              tooltip: l10n.inboxPlanButtonLabel,
              icon: const Icon(Icons.upload),
              onPressed: _isPlanning ? null : () => _planTask(context, task),
            ),
            IconButton(
              tooltip: l10n.inboxDeleteAction,
              icon: const Icon(Icons.delete_outline),
              onPressed: _isDeleting ? null : () => _deleteTask(context, task),
            ),
          ],
        ),
        const SizedBox(height: 12),
        contextTags.when(
          data: (tags) => TagPanel(
            contextOptions: _toChipOptions(tags, widget.localeName),
            priorityOptions: priorityTags.maybeWhen(
              data: (value) => _toChipOptions(value, widget.localeName),
              orElse: () => const <ChipToggleOption>[],
            ),
            selectedContext: contextTag.isEmpty ? null : contextTag,
            selectedPriority: priorityTag.isEmpty ? null : priorityTag,
            onContextChanged: (tag) => _updateTags(context, task.id, tag, priorityTag),
            onPriorityChanged: (tag) => _updateTags(context, task.id, contextTag, tag),
          ),
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => _ErrorBanner(message: '$error'),
        ),
        const SizedBox(height: 12),
        _ParentSelectorTile(task: task),
        const SizedBox(height: 8),
        Text(l10n.inboxSwipeHint, style: Theme.of(context).textTheme.bodySmall),
        if (_isPlanning || _isDeleting)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }

  Future<void> _renameTask(BuildContext context, Task task) async {
    final controller = TextEditingController(text: task.title);
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.inboxRenameTitle),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.commonCancel)),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty || result == task.title) {
      return;
    }
    try {
      await ref
          .read(taskServiceProvider)
          .updateDetails(
            taskId: task.id,
            payload: TaskUpdate(title: result),
          );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.inboxRenameSuccess)));
    } catch (error, stackTrace) {
      debugPrint('Failed to rename inbox task: $error\n$stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.inboxRenameError}: $error')));
      }
    }
  }

  Future<void> _planTask(BuildContext context, Task task) async {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (selectedDate == null) {
      return;
    }
    setState(() {
      _isPlanning = true;
    });
    try {
      final section = _sectionForDate(selectedDate);
      await ref
          .read(taskServiceProvider)
          .planTask(taskId: task.id, dueDateLocal: selectedDate, section: section);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.inboxPlanSuccess)));
    } catch (error, stackTrace) {
      debugPrint('Failed to plan inbox task: $error\n$stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.inboxPlanError}: $error')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPlanning = false;
        });
      }
    }
  }

  Future<void> _deleteTask(BuildContext context, Task task) async {
    setState(() {
      _isDeleting = true;
    });
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(taskServiceProvider).softDelete(task.id);
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.inboxDeletedToast)));
    } catch (error, stackTrace) {
      debugPrint('Failed to delete inbox task: $error\n$stackTrace');
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text('${l10n.inboxDeleteError}: $error')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<void> _updateTags(
    BuildContext context,
    int taskId,
    String? contextTag,
    String? priorityTag,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(taskServiceProvider)
          .updateTags(taskId: taskId, contextTag: contextTag, priorityTag: priorityTag);
    } catch (error, stackTrace) {
      debugPrint('Failed to update tags: $error\n$stackTrace');
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text('${l10n.inboxTagError}: $error')));
      }
    }
  }

  TaskSection _sectionForDate(DateTime date) {
    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final difference = normalizedDate.difference(normalizedNow).inDays;
    if (difference <= 0) {
      return TaskSection.today;
    }
    if (difference == 1) {
      return TaskSection.tomorrow;
    }
    return TaskSection.later;
  }

  List<ChipToggleOption> _toChipOptions(List<Tag> tags, String localeName) {
    return tags
        .map((tag) => ChipToggleOption(value: tag.slug, label: tag.labelForLocale(localeName)))
        .toList(growable: false);
  }
}

class TagPanel extends StatelessWidget {
  const TagPanel({
    super.key,
    required this.contextOptions,
    required this.priorityOptions,
    required this.selectedContext,
    required this.selectedPriority,
    required this.onContextChanged,
    required this.onPriorityChanged,
  });

  final List<ChipToggleOption> contextOptions;
  final List<ChipToggleOption> priorityOptions;
  final String? selectedContext;
  final String? selectedPriority;
  final ValueChanged<String?> onContextChanged;
  final ValueChanged<String?> onPriorityChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.inboxContextFilterLabel, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        ChipToggleGroup(
          options: contextOptions,
          selectedValues: {if (selectedContext != null) selectedContext!},
          onSelectionChanged: (values) {
            onContextChanged(values.isEmpty ? null : values.first);
          },
          multiSelect: false,
        ),
        const SizedBox(height: 12),
        Text(l10n.inboxPriorityFilterLabel, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        ChipToggleGroup(
          options: priorityOptions,
          selectedValues: {if (selectedPriority != null) selectedPriority!},
          onSelectionChanged: (values) {
            onPriorityChanged(values.isEmpty ? null : values.first);
          },
          multiSelect: false,
        ),
      ],
    );
  }
}

class _ParentSelectorTile extends ConsumerWidget {
  const _ParentSelectorTile({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final taskRepository = ref.read(taskRepositoryProvider);
    return FutureBuilder<Task?>(
      future: task.parentId == null
          ? Future<Task?>.value(null)
          : taskRepository.findById(task.parentId!),
      builder: (context, snapshot) {
        final parentTask = snapshot.data;
        final title = parentTask?.title ?? l10n.inboxParentNone;
        final messenger = ScaffoldMessenger.of(context);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.account_tree_outlined),
          title: Text(l10n.inboxParentLabel),
          subtitle: Text(title),
          trailing: TextButton(
            onPressed: () async {
              final selected = await showModalBottomSheet<int?>(
                context: context,
                isScrollControlled: true,
                builder: (context) =>
                    ParentSelectorSheet(excludeTaskId: task.id, initialParentId: task.parentId),
              );
              if (selected == null && task.parentId == null) {
                return;
              }
              if (selected == task.parentId) {
                return;
              }
              await ref
                  .read(taskServiceProvider)
                  .updateDetails(
                    taskId: task.id,
                    payload: TaskUpdate(parentId: selected),
                  );
              if (!context.mounted) {
                return;
              }
              messenger.showSnackBar(SnackBar(content: Text(l10n.inboxParentUpdated)));
            },
            child: Text(l10n.inboxParentChange),
          ),
        );
      },
    );
  }
}

class ParentSelectorSheet extends ConsumerStatefulWidget {
  const ParentSelectorSheet({
    super.key,
    required this.excludeTaskId,
    required this.initialParentId,
  });

  final int excludeTaskId;
  final int? initialParentId;

  @override
  ConsumerState<ParentSelectorSheet> createState() => _ParentSelectorSheetState();
}

class _ParentSelectorSheetState extends ConsumerState<ParentSelectorSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Task> _results = const <Task>[];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.inboxParentPickerTitle),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: l10n.inboxParentSearchPlaceholder,
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            _debounce?.cancel();
                            _loadInitial();
                          },
                        ),
                ),
                onChanged: (value) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 250), () {
                    _search(value);
                  });
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.push_pin_outlined),
              title: Text(l10n.inboxParentNone),
              onTap: () => Navigator.of(context).pop(null),
            ),
            if (_isLoading) const LinearProgressIndicator(minHeight: 2),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final task = _results[index];
                  return ListTile(
                    title: Text(task.title),
                    subtitle: Text('ID: ${task.taskId}'),
                    onTap: () => Navigator.of(context).pop(task.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
    });
    final taskRepository = ref.read(taskRepositoryProvider);
    final tasks = await taskRepository.listRoots();
    _updateResults(tasks);
  }

  Future<void> _search(String query) async {
    setState(() {
      _isLoading = true;
    });
    final taskService = ref.read(taskServiceProvider);
    final results = await taskService.searchTasksByTitle(
      query,
      status: TaskStatus.pending,
      limit: 20,
    );
    _updateResults(results);
  }

  void _updateResults(List<Task> tasks) {
    if (!mounted) {
      return;
    }
    setState(() {
      _results = tasks
          .where((task) => task.id != widget.excludeTaskId && task.parentId == null)
          .toList(growable: false);
      _isLoading = false;
    });
  }
}

class InboxEmptyStateCard extends StatelessWidget {
  const InboxEmptyStateCard({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message),
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground({
    required this.alignment,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final Alignment alignment;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foregroundColor),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: foregroundColor)),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
  }
}
