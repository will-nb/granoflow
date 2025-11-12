import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../core/services/project_models.dart';
import '../../core/services/tag_service.dart';
import '../../core/utils/task_section_utils.dart';
import '../../data/models/tag.dart';
import '../../data/models/task.dart';
import '../../generated/l10n/app_localizations.dart';
import 'inline_editable_tag.dart';
import 'inline_project_milestone_display.dart';
import 'inline_deadline_editor.dart';
import 'project_milestone_picker.dart';
import 'swipe_action_handler.dart';
import 'swipe_action_type.dart';
import 'tag_add_button.dart';
import 'tag_data.dart';
import 'tag_grouped_menu.dart';
import 'task_copy_button.dart';
import 'task_timer_widget.dart';

/// 任务操作底部弹窗
/// 
/// 包含所有任务操作功能：编辑标题、标签管理、项目/里程碑选择、截止日期编辑、复制、计时、转换为项目、完成、归档、删除等
class TaskActionBottomSheet extends ConsumerStatefulWidget {
  const TaskActionBottomSheet({
    super.key,
    required this.task,
    this.showConvertAction = false,
  });

  final Task task;
  final bool showConvertAction;

  @override
  ConsumerState<TaskActionBottomSheet> createState() =>
      _TaskActionBottomSheetState();
}

class _TaskActionBottomSheetState
    extends ConsumerState<TaskActionBottomSheet> {
  late TextEditingController _titleController;
  late FocusNode _titleFocusNode;
  bool _isEditingTitle = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _titleFocusNode = FocusNode();
    _titleFocusNode.addListener(_onFocusChange);
    // 自动进入编辑状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocusNode.requestFocus();
      setState(() {
        _isEditingTitle = true;
      });
    });
  }

  @override
  void dispose() {
    _titleFocusNode.removeListener(_onFocusChange);
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_titleFocusNode.hasFocus && _isEditingTitle) {
      _saveTitle();
    }
  }

  Future<void> _saveTitle() async {
    final newTitle = _titleController.text.trim();
    if (newTitle.isEmpty) {
      _titleController.text = widget.task.title;
      setState(() {
        _isEditingTitle = false;
      });
      return;
    }

    if (newTitle == widget.task.title) {
      setState(() {
        _isEditingTitle = false;
      });
      return;
    }

    try {
      final taskService = await ref.read(taskServiceProvider.future);
      await taskService.updateDetails(
        taskId: widget.task.id,
        payload: TaskUpdate(title: newTitle),
      );
      setState(() {
        _isEditingTitle = false;
      });
    } catch (error) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.taskUpdateError}: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final task = widget.task;
    final isInbox = task.status == TaskStatus.inbox;
    final canShowTimer = !isInbox &&
        (task.status == TaskStatus.pending ||
            task.status == TaskStatus.doing ||
            task.status == TaskStatus.paused);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 拖拽指示器
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 可滚动内容
          Flexible(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 任务标题编辑
                  TextField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: l10n.taskTitleHint,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saveTitle(),
                  ),
                  const SizedBox(height: 24),
                  // 标签管理
                  _buildTagsSection(context, ref, theme),
                  const SizedBox(height: 16),
                  // 项目/里程碑选择
                  _buildProjectMilestoneSection(context, ref, theme),
                  const SizedBox(height: 16),
                  // 截止日期编辑
                  _buildDeadlineSection(context, ref, theme),
                  const SizedBox(height: 16),
                  // 复制按钮和计时控件
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TaskCopyButton(taskTitle: task.title),
                      if (canShowTimer) TaskTimerWidget(task: task),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 转换为项目（如果适用）
                  if (widget.showConvertAction) ...[
                    _buildConvertToProjectButton(context, ref, theme, l10n),
                    const SizedBox(height: 16),
                  ],
                  // 操作按钮区域
                  _buildActionButtons(context, ref, theme, l10n),
                  // 底部安全区域
                  SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    final task = widget.task;
    final tagGroups = _getAvailableTagGroups(context, ref);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // 已选中的标签（可删除）
            ...task.tags.map((slug) {
              final tagData = TagService.getTagData(context, slug);
              if (tagData == null) {
                return const SizedBox.shrink();
              }
              return InlineEditableTag(
                label: tagData.label,
                slug: tagData.slug,
                color: tagData.color,
                icon: tagData.icon,
                prefix: tagData.prefix,
                onRemove: (removedSlug) => _handleRemoveTag(ref, removedSlug),
              );
            }),
            // 添加标签按钮
            if (tagGroups.isNotEmpty)
              TagAddButton(
                tagGroups: tagGroups,
                onTagSelected: (slug) => _handleAddTag(ref, slug),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildProjectMilestoneSection(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    final hierarchyAsync = ref.watch(
      taskProjectHierarchyProvider(widget.task.id),
    );

    return hierarchyAsync.when(
      data: (hierarchy) {
        if (hierarchy == null) {
          return ProjectMilestonePicker(
            onSelected: (selection) =>
                _handleProjectMilestoneChanged(ref, selection),
            currentProjectId: null,
            currentMilestoneId: null,
          );
        } else {
          return InlineProjectMilestoneDisplay(
            project: hierarchy.project,
            milestone: hierarchy.milestone,
            onSelected: (selection) =>
                _handleProjectMilestoneChanged(ref, selection),
          );
        }
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => ProjectMilestonePicker(
        onSelected: (selection) =>
            _handleProjectMilestoneChanged(ref, selection),
        currentProjectId: null,
        currentMilestoneId: null,
      ),
    );
  }

  Widget _buildDeadlineSection(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    return InlineDeadlineEditor(
      deadline: widget.task.dueAt,
      onDeadlineChanged: (newDeadline) =>
          _handleDeadlineChanged(ref, newDeadline),
      showIcon: true,
    );
  }

  Widget _buildConvertToProjectButton(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return OutlinedButton.icon(
      onPressed: () => _handleConvertToProject(context, ref),
      icon: const Icon(Icons.autorenew),
      label: Text(l10n.projectConvertTooltip),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final task = widget.task;
    final isCompleted = task.status == TaskStatus.completedActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 完成任务按钮（仅未完成状态显示）
        if (!isCompleted)
          FilledButton.icon(
            onPressed: () => _handleComplete(context, ref),
            icon: const Icon(Icons.check),
            label: Text(l10n.actionMarkCompleted),
          ),
        if (!isCompleted) const SizedBox(height: 8),
        // 归档按钮
        OutlinedButton.icon(
          onPressed: () => _handleArchive(context, ref),
          icon: const Icon(Icons.archive_outlined),
          label: Text(l10n.actionArchive),
        ),
        const SizedBox(height: 8),
        // 删除按钮
        OutlinedButton.icon(
          onPressed: () => _handleDelete(context, ref),
          icon: const Icon(Icons.delete_outline),
          label: Text(l10n.actionDelete),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
          ),
        ),
      ],
    );
  }

  List<TagGroup> _getAvailableTagGroups(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tagGroups = <TagGroup>[];

    // 紧急程度组
    final urgencyTagsAsync = ref.watch(urgencyTagOptionsProvider);
    final hasUrgencyTag = widget.task.tags.any(
      (t) => TagService.getKind(t) == TagKind.urgency,
    );
    if (!hasUrgencyTag) {
      urgencyTagsAsync.whenData((tags) {
        if (tags.isNotEmpty) {
          tagGroups.add(
            TagGroup(
              title: l10n.tagGroupUrgency,
              tags: tags
                  .map((tag) => TagData.fromTagWithLocalization(tag, context))
                  .toList(),
            ),
          );
        }
      });
    }

    // 重要程度组
    final importanceTagsAsync = ref.watch(importanceTagOptionsProvider);
    final hasImportanceTag = widget.task.tags.any(
      (t) => TagService.getKind(t) == TagKind.importance,
    );
    if (!hasImportanceTag) {
      importanceTagsAsync.whenData((tags) {
        if (tags.isNotEmpty) {
          tagGroups.add(
            TagGroup(
              title: l10n.tagGroupImportance,
              tags: tags
                  .map((tag) => TagData.fromTagWithLocalization(tag, context))
                  .toList(),
            ),
          );
        }
      });
    }

    // 执行方式组
    final executionTagsAsync = ref.watch(executionTagOptionsProvider);
    final hasExecutionTag = widget.task.tags.any(
      (t) => TagService.getKind(t) == TagKind.execution,
    );
    if (!hasExecutionTag) {
      executionTagsAsync.whenData((tags) {
        if (tags.isNotEmpty) {
          tagGroups.add(
            TagGroup(
              title: l10n.tagGroupExecution,
              tags: tags
                  .map((tag) => TagData.fromTagWithLocalization(tag, context))
                  .toList(),
            ),
          );
        }
      });
    }

    // 上下文组
    final contextTagsAsync = ref.watch(contextTagOptionsProvider);
    final hasContextTag = widget.task.tags.any(
      (t) => TagService.getKind(t) == TagKind.context,
    );
    if (!hasContextTag) {
      contextTagsAsync.whenData((tags) {
        if (tags.isNotEmpty) {
          tagGroups.add(
            TagGroup(
              title: l10n.tagGroupContext,
              tags: tags
                  .map((tag) => TagData.fromTagWithLocalization(tag, context))
                  .toList(),
            ),
          );
        }
      });
    }

    return tagGroups;
  }

  Future<void> _handleAddTag(WidgetRef ref, String slug) async {
    try {
      final taskService = await ref.read(taskServiceProvider.future);
      String? tagToRemove;
      for (final existingTag in widget.task.tags) {
        if (TagService.areInSameGroup(slug, existingTag)) {
          tagToRemove = existingTag;
          break;
        }
      }

      List<String> updatedTags = List.from(widget.task.tags);
      if (tagToRemove != null && tagToRemove.isNotEmpty) {
        updatedTags = updatedTags.where((t) => t != tagToRemove).toList();
      }

      final normalizedSlug = TagService.normalizeSlug(slug);
      updatedTags.add(normalizedSlug);

      await taskService.updateDetails(
        taskId: widget.task.id,
        payload: TaskUpdate(tags: updatedTags),
      );
    } catch (e) {
      debugPrint('Failed to add tag: $e');
    }
  }

  Future<void> _handleRemoveTag(WidgetRef ref, String slug) async {
    try {
      final taskService = await ref.read(taskServiceProvider.future);
      final normalizedSlug = TagService.normalizeSlug(slug);
      final updatedTags = widget.task.tags
          .where((t) => TagService.normalizeSlug(t) != normalizedSlug)
          .toList();
      await taskService.updateDetails(
        taskId: widget.task.id,
        payload: TaskUpdate(tags: updatedTags),
      );
    } catch (e) {
      debugPrint('Failed to remove tag: $e');
    }
  }

  Future<void> _handleProjectMilestoneChanged(
    WidgetRef ref,
    ProjectMilestoneSelection? selection,
  ) async {
    try {
      final taskService = await ref.read(taskServiceProvider.future);
      await taskService.updateDetails(
        taskId: widget.task.id,
        payload: TaskUpdate(
          projectId: selection?.project?.id,
          milestoneId: selection?.milestone?.id,
          clearProject: selection == null,
          clearMilestone: selection == null || !selection.hasMilestone,
        ),
      );

      if (mounted) {
        if (widget.task.status == TaskStatus.inbox) {
          ref.invalidate(inboxTasksProvider);
        }
        if (widget.task.status == TaskStatus.pending &&
            widget.task.dueAt != null) {
          final section = TaskSectionUtils.getSectionForDate(widget.task.dueAt);
          ref.invalidate(taskSectionsProvider(section));
          ref.invalidate(tasksSectionTaskLevelMapProvider(section));
          ref.invalidate(tasksSectionTaskChildrenMapProvider(section));
        }
      }
    } catch (e) {
      debugPrint('Failed to update project/milestone: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.taskUpdateError}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleDeadlineChanged(
    WidgetRef ref,
    DateTime? newDeadline,
  ) async {
    try {
      final taskService = await ref.read(taskServiceProvider.future);
      await taskService.updateDetails(
        taskId: widget.task.id,
        payload: TaskUpdate(dueAt: newDeadline),
      );
    } catch (e) {
      debugPrint('Failed to update deadline: $e');
    }
  }

  Future<void> _handleConvertToProject(
    BuildContext context,
    WidgetRef ref,
  ) async {
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
    if (result != true || !mounted) {
      return;
    }

    try {
      final projectService = await ref.read(projectServiceProvider.future);
      await projectService.convertTaskToProject(widget.task.id);
      if (!mounted) return;
      Navigator.of(context).pop(); // 关闭弹窗
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.projectConvertSuccess)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.projectConvertError}: $error')),
      );
    }
  }

  Future<void> _handleComplete(BuildContext context, WidgetRef ref) async {
    await SwipeActionHandler.handleAction(
      context,
      ref,
      SwipeActionType.complete,
      widget.task,
    );
    if (mounted) {
      Navigator.of(context).pop(); // 关闭弹窗
    }
  }

  Future<void> _handleArchive(BuildContext context, WidgetRef ref) async {
    await SwipeActionHandler.handleAction(
      context,
      ref,
      SwipeActionType.archive,
      widget.task,
    );
    if (mounted) {
      Navigator.of(context).pop(); // 关闭弹窗
    }
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    await SwipeActionHandler.handleAction(
      context,
      ref,
      SwipeActionType.delete,
      widget.task,
    );
    if (mounted) {
      Navigator.of(context).pop(); // 关闭弹窗
    }
  }
}

