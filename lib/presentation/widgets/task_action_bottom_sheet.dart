import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/pinned_task_provider.dart';
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
  // 添加本地状态来跟踪标签列表，用于立即更新布局
  List<String>? _localTags;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _titleFocusNode = FocusNode();
    _titleFocusNode.addListener(_onFocusChange);
    // 初始化本地标签列表
    _localTags = List.from(widget.task.tags);
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
    
    // 使用 taskByIdProvider 获取最新的任务数据
    final taskAsync = ref.watch(taskByIdProvider(widget.task.id));
    
    // 处理异步状态，获取当前任务
    return taskAsync.when(
      data: (task) {
        // 使用最新的任务数据，如果不存在则使用初始任务数据
        final currentTask = task ?? widget.task;
        return _buildContent(context, ref, theme, l10n, currentTask);
      },
      loading: () {
        // 加载中时使用初始任务数据
        return _buildContent(context, ref, theme, l10n, widget.task);
      },
      error: (_, __) {
        // 错误时使用初始任务数据
        return _buildContent(context, ref, theme, l10n, widget.task);
      },
    );
  }

  // 将原来的 build 方法内容提取到这个方法中
  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    Task task, // 使用传入的任务数据，而不是 widget.task
  ) {
    final isInbox = task.status == TaskStatus.inbox;
    final pinnedTaskId = ref.watch(pinnedTaskIdProvider);
    final canShowTimer = !isInbox &&
        (task.status == TaskStatus.pending ||
            task.status == TaskStatus.doing ||
            task.status == TaskStatus.paused) &&
        (pinnedTaskId == null || pinnedTaskId != task.id);

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
          SingleChildScrollView(
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
                  // 标签管理 - 传递最新的任务数据
                  _buildTagsSection(context, ref, theme, task),
                  const SizedBox(height: 16),
                  // 项目/里程碑选择 - 传递最新的任务数据
                  _buildProjectMilestoneSection(context, ref, theme, task),
                  const SizedBox(height: 16),
                  // 复制按钮和计时控件 - 使用最新的任务数据，在同一排显示
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
                    _buildConvertToProjectButton(context, ref, theme, l10n, task),
                    const SizedBox(height: 16),
                  ],
                  // 操作按钮区域 - 传递最新的任务数据
                  _buildActionButtons(context, ref, theme, l10n, task),
                  // 底部安全区域
                  SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
                ],
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
    Task task, // 接收最新的任务数据
  ) {
    // 如果数据库中的标签列表更新了，同步到本地状态
    if (_localTags != null && !_listEquals(_localTags!, task.tags)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _localTags = List.from(task.tags);
          });
        }
      });
    }
    // 使用本地标签列表来构建 UI，这样删除时可以立即更新
    final tagsToDisplay = _localTags ?? task.tags;
    // 传递 task 给 _buildTagsSectionContent，这样 _getAvailableTagGroups 可以使用最新的任务数据
    return _buildTagsSectionContent(context, ref, theme, task, tagsToDisplay);
  }

  /// 构建标签部分的内容
  Widget _buildTagsSectionContent(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Task task, // 这个 task 应该是最新的任务数据（从 taskByIdProvider 获取）
    List<String> tagsToDisplay,
  ) {
    // 传递 task 给 _getAvailableTagGroups，使用最新的任务数据
    final tagGroups = _getAvailableTagGroups(context, ref, task);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // 已选中的标签（可删除）
            ...tagsToDisplay.map((slug) {
              final tagData = TagService.getTagData(context, slug);
              if (tagData == null) {
                return const SizedBox.shrink();
              }
              return InlineEditableTag(
                key: ValueKey('tag-${task.id}-$slug'),
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

  // 添加辅助方法比较列表
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // 刷新任务列表相关的 providers
  void _refreshTaskListProviders(WidgetRef ref) {
    if (!mounted) return;
    
    final taskAsync = ref.read(taskByIdProvider(widget.task.id));
    final currentTask = taskAsync.value ?? widget.task;
    
    if (currentTask.status == TaskStatus.inbox) {
      ref.invalidate(inboxTasksProvider);
    }
    if (currentTask.status == TaskStatus.pending && currentTask.dueAt != null) {
      final section = TaskSectionUtils.getSectionForDate(currentTask.dueAt);
      ref.invalidate(taskSectionsProvider(section));
      ref.invalidate(tasksSectionTaskLevelMapProvider(section));
      ref.invalidate(tasksSectionTaskChildrenMapProvider(section));
    }
  }

  Widget _buildProjectMilestoneSection(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Task task, // 接收最新的任务数据
  ) {
    final hierarchyAsync = ref.watch(
      taskProjectHierarchyProvider(task.id),
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
      error: (error, stackTrace) {
        return ProjectMilestonePicker(
          onSelected: (selection) =>
              _handleProjectMilestoneChanged(ref, selection),
          currentProjectId: null,
          currentMilestoneId: null,
        );
      },
    );
  }

  Widget _buildDeadlineSection(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Task task, // 接收最新的任务数据
  ) {
    return InlineDeadlineEditor(
      deadline: task.dueAt,
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
    Task task, // 接收最新的任务数据
  ) {
    return OutlinedButton.icon(
      onPressed: () => _handleConvertToProject(context, ref, task),
      icon: const Icon(Icons.autorenew),
      label: Text(l10n.projectConvertTooltip),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    Task task, // 接收最新的任务数据
  ) {
    final isCompleted = task.status == TaskStatus.completedActive;
    final isInbox = task.status == TaskStatus.inbox;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 主要操作按钮（大按钮）
        if (!isCompleted)
          FilledButton.icon(
            onPressed: () {
              if (isInbox) {
                _handleQuickPlan(context, ref, task);
              } else {
                _handleComplete(context, ref, task);
              }
            },
            icon: Icon(isInbox ? Icons.today : Icons.check),
            label: Text(isInbox ? l10n.inboxQuickPlanAction : l10n.actionMarkCompleted),
          ),
        if (!isCompleted) const SizedBox(height: 8),
        // 日期按钮、归档和删除按钮（小按钮，同一行）
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildDeadlineSection(context, ref, theme, task),
            _buildArchiveButton(context, ref, theme, l10n, task),
            _buildDeleteButton(context, ref, theme, l10n, task),
          ],
        ),
      ],
    );
  }

  /// 构建归档小按钮
  Widget _buildArchiveButton(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    Task task,
  ) {
    final color = theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: () => _handleArchive(context, ref, task),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.archive_outlined,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              l10n.actionArchive,
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

  /// 构建删除小按钮
  Widget _buildDeleteButton(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    Task task,
  ) {
    final color = theme.colorScheme.error;

    return InkWell(
      onTap: () => _handleDelete(context, ref, task),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_outline,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              l10n.actionDelete,
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

  // 修改 _getAvailableTagGroups，接收 task 参数
  List<TagGroup> _getAvailableTagGroups(
    BuildContext context,
    WidgetRef ref,
    Task task, // 使用传入的任务数据，而不是 widget.task
  ) {
    final l10n = AppLocalizations.of(context);
    final tagGroups = <TagGroup>[];

    // 紧急程度组
    final urgencyTagsAsync = ref.watch(urgencyTagOptionsProvider);
    final hasUrgencyTag = task.tags.any(
      (t) => TagService.getKind(t) == TagKind.urgency,
    );
    if (!hasUrgencyTag && urgencyTagsAsync.hasValue) {
      final tags = urgencyTagsAsync.value!;
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
    }

    // 重要程度组
    final importanceTagsAsync = ref.watch(importanceTagOptionsProvider);
    final hasImportanceTag = task.tags.any(
      (t) => TagService.getKind(t) == TagKind.importance,
    );
    if (!hasImportanceTag && importanceTagsAsync.hasValue) {
      final tags = importanceTagsAsync.value!;
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
    }

    // 上下文组
    final contextTagsAsync = ref.watch(contextTagOptionsProvider);
    final hasContextTag = task.tags.any(
      (t) => TagService.getKind(t) == TagKind.context,
    );
    if (!hasContextTag && contextTagsAsync.hasValue) {
      final tags = contextTagsAsync.value!;
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
    }

    return tagGroups;
  }

  Future<void> _handleAddTag(WidgetRef ref, String slug) async {
    final normalizedSlug = TagService.normalizeSlug(slug);
    
    // 立即添加到本地状态，这样布局会立即更新
    // 注意：菜单已经过滤了同组标签，所以这里不需要检查同组冲突
    if (_localTags != null) {
      setState(() {
        if (!_localTags!.any((t) => TagService.normalizeSlug(t) == normalizedSlug)) {
          _localTags!.add(normalizedSlug);
        }
      });
    }
    
    try {
      final taskService = await ref.read(taskServiceProvider.future);
      
      // 使用本地标签列表（如果存在）或最新任务数据的标签作为基础
      final taskAsync = ref.read(taskByIdProvider(widget.task.id));
      final currentTask = taskAsync.value ?? widget.task;
      final baseTags = _localTags ?? currentTask.tags;
      
      // 构建新的标签列表（菜单已过滤同组标签，所以直接添加即可）
      final updatedTags = List<String>.from(baseTags);
      if (!updatedTags.any((t) => TagService.normalizeSlug(t) == normalizedSlug)) {
        updatedTags.add(normalizedSlug);
      }

      await taskService.updateDetails(
        taskId: widget.task.id,
        payload: TaskUpdate(tags: updatedTags),
      );
      
      // 刷新相关的列表 providers
      _refreshTaskListProviders(ref);
    } catch (e) {
      // 如果添加失败，恢复本地状态
      if (mounted && _localTags != null) {
        final taskAsync = ref.read(taskByIdProvider(widget.task.id));
        final currentTask = taskAsync.value ?? widget.task;
        setState(() {
          _localTags = List.from(currentTask.tags);
        });
      }
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

  Future<void> _handleRemoveTag(WidgetRef ref, String slug) async {
    // 立即从本地状态中移除标签，这样布局会立即更新
    if (_localTags != null) {
      setState(() {
        final normalizedSlug = TagService.normalizeSlug(slug);
        _localTags = _localTags!.where((t) => TagService.normalizeSlug(t) != normalizedSlug).toList();
      });
    }
    
    try {
      final taskService = await ref.read(taskServiceProvider.future);
      
      // 使用 taskByIdProvider 获取最新任务数据作为基础
      final taskAsync = ref.read(taskByIdProvider(widget.task.id));
      final currentTask = taskAsync.value ?? widget.task;
      
      final normalizedSlug = TagService.normalizeSlug(slug);
      final updatedTags = currentTask.tags
          .where((t) => TagService.normalizeSlug(t) != normalizedSlug)
          .toList();
      await taskService.updateDetails(
        taskId: widget.task.id,
        payload: TaskUpdate(tags: updatedTags),
      );
      
      // 刷新相关的列表 providers
      _refreshTaskListProviders(ref);
    } catch (e) {
      // 如果删除失败，恢复本地状态
      if (mounted && _localTags != null) {
        // 获取最新任务数据来恢复
        final taskAsync = ref.read(taskByIdProvider(widget.task.id));
        final currentTask = taskAsync.value ?? widget.task;
        setState(() {
          _localTags = List.from(currentTask.tags);
        });
      }
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

  Future<void> _handleProjectMilestoneChanged(
    WidgetRef ref,
    ProjectMilestoneSelection? selection,
  ) async {
    try {
      final taskService = await ref.read(taskServiceProvider.future);
      final updatePayload = TaskUpdate(
        projectId: selection?.project?.id,
        milestoneId: selection?.milestone?.id,
        clearProject: selection == null,
        clearMilestone: selection == null || !selection.hasMilestone,
      );
      await taskService.updateDetails(
        taskId: widget.task.id,
        payload: updatePayload,
      );

      if (mounted) {
        // 刷新相关 providers，确保 UI 更新
        ref.invalidate(taskProjectHierarchyProvider(widget.task.id));
        _refreshTaskListProviders(ref);
      }
    } catch (e) {
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
      
      // 获取当前任务状态
      final taskAsync = ref.read(taskByIdProvider(widget.task.id));
      final currentTask = taskAsync.value ?? widget.task;
      
      // 如果任务状态是 inbox 且设置了截止日期，使用 planTask 来设置截止日期和 section
      // planTask 和 updateDetails 都会在底层自动将 inbox 状态改为 pending
      if (currentTask.status == TaskStatus.inbox && newDeadline != null) {
        final section = TaskSectionUtils.getSectionForDate(newDeadline);
        await taskService.planTask(
          taskId: widget.task.id,
          dueDateLocal: newDeadline,
          section: section,
        );
      } else {
        // 其他情况使用 updateDetails，底层会自动处理状态转换
        await taskService.updateDetails(
          taskId: widget.task.id,
          payload: TaskUpdate(dueAt: newDeadline),
        );
      }
      
      // 刷新相关的列表 providers
      _refreshTaskListProviders(ref);
    } catch (e) {
      // 静默失败，截止日期更新失败不影响用户体验
    }
  }

  Future<void> _handleConvertToProject(
    BuildContext context,
    WidgetRef ref,
    Task task, // 接收最新的任务数据
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
      await projectService.convertTaskToProject(task.id);
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

  Future<void> _handleQuickPlan(BuildContext context, WidgetRef ref, Task task) async {
    await SwipeActionHandler.handleAction(
      context,
      ref,
      SwipeActionType.quickPlan,
      task,
    );
    if (mounted) {
      Navigator.of(context).pop(); // 关闭弹窗
    }
  }

  Future<void> _handleComplete(BuildContext context, WidgetRef ref, Task task) async {
    await SwipeActionHandler.handleAction(
      context,
      ref,
      SwipeActionType.complete,
      task,
    );
    if (mounted) {
      Navigator.of(context).pop(); // 关闭弹窗
    }
  }

  Future<void> _handleArchive(BuildContext context, WidgetRef ref, Task task) async {
    await SwipeActionHandler.handleAction(
      context,
      ref,
      SwipeActionType.archive,
      task,
    );
    if (mounted) {
      Navigator.of(context).pop(); // 关闭弹窗
    }
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, Task task) async {
    await SwipeActionHandler.handleAction(
      context,
      ref,
      SwipeActionType.delete,
      task,
    );
    if (mounted) {
      Navigator.of(context).pop(); // 关闭弹窗
    }
  }
}

