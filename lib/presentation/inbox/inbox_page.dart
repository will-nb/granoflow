import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../core/providers/inbox_drag_provider.dart';
import '../../core/theme/app_color_tokens.dart';
import '../../data/models/tag.dart';
import '../../data/models/task.dart';
import '../../data/models/task_template.dart';
import '../../generated/l10n/app_localizations.dart';
import '../navigation/navigation_destinations.dart';
import '../widgets/modern_tag.dart';
import '../widgets/page_app_bar.dart';
import '../widgets/main_drawer.dart';
import '../widgets/gradient_page_scaffold.dart';
import '../widgets/tag_data.dart';
import '../widgets/tag_panel.dart';
import '../widgets/task_row_content.dart';
import 'inbox_draggable.dart';
import 'inbox_drag_target.dart';

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
    final urgencyTagsAsync = ref.watch(urgencyTagOptionsProvider);
    final importanceTagsAsync = ref.watch(importanceTagOptionsProvider);

    return GradientPageScaffold(
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
                    loading: () => const SizedBox.shrink(), // 隐藏 loading 状态
                    error: (error, stackTrace) => _ErrorBanner(message: '$error'),
                  ),
                  const SizedBox(height: 16),
                  
                  // 上下文标签组 - 保持水平滚动
                  contextTagsAsync.when(
                    data: (tags) {
                      final tagDataList = tags.map((tag) => TagData.fromTagWithLocalization(tag, context)).toList();
                      
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: tagDataList.map((tagData) {
                            final isSelected = filter.contextTag == tagData.slug;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ModernTag(
                                label: tagData.label,
                                color: tagData.color,
                                icon: tagData.icon,
                                prefix: tagData.prefix,
                                selected: isSelected,
                                variant: TagVariant.dot,
                                size: TagSize.medium,
                                showCheckmark: false,
                                onTap: () {
                                  ref.read(inboxFilterProvider.notifier).setContextTag(
                                    isSelected ? null : tagData.slug,
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (error, stackTrace) => _ErrorBanner(message: '$error'),
                  ),
                  const SizedBox(height: 8),

                  // 紧急程度和重要程度标签组 - 动态生成，合并为同一行
                  urgencyTagsAsync.when(
                    data: (urgencyTags) {
                      return importanceTagsAsync.when(
                        data: (importanceTags) {
                        final urgencyTagData = urgencyTags.map((tag) => TagData.fromTagWithLocalization(tag, context)).toList();
                        final importanceTagData = importanceTags.map((tag) => TagData.fromTagWithLocalization(tag, context)).toList();
                        
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // 紧急程度标签
                              ...urgencyTagData.map((tagData) {
                                final isSelected = filter.urgencyTag == tagData.slug;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ModernTag(
                                    label: tagData.label,
                                    color: tagData.color,
                                    icon: tagData.icon,
                                    prefix: tagData.prefix,
                                    selected: isSelected,
                                    variant: TagVariant.dot,
                                    size: TagSize.medium,
                                    showCheckmark: false,
                                    onTap: () {
                                      ref.read(inboxFilterProvider.notifier).setUrgencyTag(
                                        isSelected ? null : tagData.slug,
                                      );
                                    },
                                  ),
                                );
                              }),
                              // 重要程度标签
                              ...importanceTagData.map((tagData) {
                                final isSelected = filter.importanceTag == tagData.slug;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ModernTag(
                                    label: tagData.label,
                                    color: tagData.color,
                                    icon: tagData.icon,
                                    prefix: tagData.prefix,
                                    selected: isSelected,
                                    variant: TagVariant.dot,
                                    size: TagSize.medium,
                                    showCheckmark: false,
                                    onTap: () {
                                      ref.read(inboxFilterProvider.notifier).setImportanceTag(
                                        isSelected ? null : tagData.slug,
                                      );
                                    },
                                  ),
                                );
                              }),
                            // 清除筛选按钮
                            if (filter.hasFilters) ...[
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ActionChip(
                                  label: Text(l10n.inboxFilterReset),
                                  avatar: Icon(
                                    Icons.clear_all,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                                  onPressed: () {
                                    ref.read(inboxFilterProvider.notifier).reset();
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (error, stackTrace) => _ErrorBanner(message: '$error'),
                      );
                    },
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
              return SliverToBoxAdapter(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      children: [
                        InboxDragTarget(targetType: InboxDragTargetType.first),
                        for (int i = 0; i < tasks.length; i++) ...[
                          if (i > 0)
                            InboxDragTarget(
                              targetType: InboxDragTargetType.between,
                              beforeTask: tasks[i - 1],
                              afterTask: tasks[i],
                            ),
                          InboxTaskTile(task: tasks[i], localeName: l10n.localeName),
                        ],
                        InboxDragTarget(targetType: InboxDragTargetType.last),
                      ],
                    ),
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading inbox tasks...'),
                    ],
                  ),
                ),
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

class InboxTaskTile extends ConsumerStatefulWidget {
  const InboxTaskTile({super.key, required this.task, required this.localeName});

  final Task task;
  final String localeName;

  @override
  ConsumerState<InboxTaskTile> createState() => _InboxTaskTileState();
}

class _InboxTaskTileState extends ConsumerState<InboxTaskTile> {
  @override
  Widget build(BuildContext context) {
    final isDragging = ref.watch(inboxDragProvider.select((s) => s.isDragging));
    final l10n = AppLocalizations.of(context);

    final messenger = ScaffoldMessenger.of(context);
    final taskService = ref.read(taskServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.colorTokens;

    return InboxDraggable(
      task: widget.task,
      enabled: true, // 始终可拖拽
      child: Dismissible(
        key: ValueKey('inbox-${widget.task.id}-${widget.task.updatedAt.millisecondsSinceEpoch}'),
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
        confirmDismiss: isDragging ? (_) async => false : (direction) async {
          if (direction == DismissDirection.startToEnd) {
            await _quickPlan(context, ref, widget.task);
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
            await taskService.softDelete(widget.task.id);
            if (!context.mounted) {
              return false;
            }
            messenger.showSnackBar(SnackBar(content: Text(l10n.inboxDeletedToast)));
          }
          return false;
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 拖拽指示器
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 4),
                child: Icon(
                  Icons.drag_indicator,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ),
              // 任务内容（使用TaskRowContent）
              Expanded(
                child: TaskRowContent(
                  task: widget.task,
                  compact: false,
                  showTaskId: true,
                ),
              ),
            ],
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
    final urgencyTags = ref.watch(urgencyTagOptionsProvider);
    final importanceTags = ref.watch(importanceTagOptionsProvider);
    contextTags.whenData((tags) => debugPrint('UI: context tags loaded ${tags.length}'));
    urgencyTags.whenData((tags) => debugPrint('UI: urgency tags loaded ${tags.length}'));
    importanceTags.whenData((tags) => debugPrint('UI: importance tags loaded ${tags.length}'));
    
    // 调试Provider状态
    urgencyTags.when(
      data: (tags) => debugPrint('UI: urgencyTags data state: ${tags.length} tags'),
      loading: () => debugPrint('UI: urgencyTags loading state'),
      error: (error, stack) => debugPrint('UI: urgencyTags error state: $error'),
    );
    importanceTags.when(
      data: (tags) => debugPrint('UI: importanceTags data state: ${tags.length} tags'),
      loading: () => debugPrint('UI: importanceTags loading state'),
      error: (error, stack) => debugPrint('UI: importanceTags error state: $error'),
    );
    final task = widget.task;
    final contextTag = task.tags.firstWhere((tag) => tag.startsWith('@'), orElse: () => '');
    final priorityTag = task.tags.firstWhere((tag) => tag.startsWith('#'), orElse: () => '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        contextTags.when(
          data: (tags) {
            // 合并urgency和importance标签
            final allPriorityTags = <Tag>[];
            urgencyTags.whenData((urgencyTags) => allPriorityTags.addAll(urgencyTags));
            importanceTags.whenData((importanceTags) => allPriorityTags.addAll(importanceTags));
            
            return TagPanel(
              contextTags: tags,
              priorityTags: allPriorityTags,
              localeName: widget.localeName,
              selectedContext: contextTag.isEmpty ? null : contextTag,
              selectedPriority: priorityTag.isEmpty ? null : priorityTag,
              onContextChanged: (tag) => _updateTags(context, task.id, tag, priorityTag),
              onPriorityChanged: (tag) => _updateTags(context, task.id, contextTag, tag),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => _ErrorBanner(message: '$error'),
        ),
        const SizedBox(height: 12),
        Text(l10n.inboxSwipeHint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                DateFormat.yMMMd().add_jm().format(task.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            OutlinedButton.icon(
              onPressed: _isPlanning ? null : () => _planTask(context, task),
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(l10n.inboxPlanButtonLabel),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
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


  Future<void> _planTask(BuildContext context, Task task) async {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    
    // 计算特殊日期
    final today = now;
    final tomorrow = now.add(const Duration(days: 1));
    final thisWeek = _getThisWeekSaturday(now);
    final thisMonth = _getEndOfMonth(now);
    
    // 显示快速选择对话框
    final quickChoice = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (context) => _QuickDatePicker(
        today: today,
        tomorrow: tomorrow,
        thisWeek: thisWeek,
        thisMonth: thisMonth,
      ),
    );
    
    DateTime? selectedDate = quickChoice;
    
    // 如果没有选择快速选项，显示标准日期选择器
    if (selectedDate == null) {
      selectedDate = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now, // 今天以前不可选择
        lastDate: now.add(const Duration(days: 365)),
      );
    }
    
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

  /// 计算本周六的日期
  /// 如果今天是周六，则返回下周六
  DateTime _getThisWeekSaturday(DateTime now) {
    final daysUntilSaturday = (DateTime.saturday - now.weekday) % 7;
    return now.add(Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday));
  }

  /// 计算本月最后一天的日期
  DateTime _getEndOfMonth(DateTime now) {
    return DateTime(now.year, now.month + 1, 0);
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

/// 快速日期选择对话框
class _QuickDatePicker extends StatelessWidget {
  const _QuickDatePicker({
    required this.today,
    required this.tomorrow,
    required this.thisWeek,
    required this.thisMonth,
  });

  final DateTime today;
  final DateTime tomorrow;
  final DateTime thisWeek;
  final DateTime thisMonth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              l10n.datePickerTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(l10n.datePickerToday),
            onTap: () => Navigator.of(context).pop(today),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(l10n.datePickerTomorrow),
            onTap: () => Navigator.of(context).pop(tomorrow),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(l10n.datePickerThisWeek),
            onTap: () => Navigator.of(context).pop(thisWeek),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(l10n.datePickerThisMonth),
            onTap: () => Navigator.of(context).pop(thisMonth),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: Text(l10n.datePickerCustom),
            onTap: () => Navigator.of(context).pop(null),
          ),
        ],
      ),
    );
  }
}
