import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../core/services/project_models.dart';
import '../../core/services/tag_service.dart';
import '../../core/utils/task_section_utils.dart';
import '../../data/models/task.dart';
import '../../generated/l10n/app_localizations.dart';
import 'inline_editable_tag.dart';
import 'inline_deadline_editor.dart';
import 'tag_add_button.dart';
import 'tag_grouped_menu.dart';
import 'tag_data.dart';
import '../../data/models/tag.dart';
import 'project_milestone_picker.dart';
import 'inline_project_milestone_display.dart';
import 'task_row_content/task_row_title_editor.dart';
import 'task_copy_button.dart';
import 'task_start_timer_button.dart';

/// 通用的任务行内容组件，支持内联编辑标签和截止日期
/// 可在Tasks、Inbox、Projects子任务、轻量任务等多个场景复用
class TaskRowContent extends ConsumerStatefulWidget {
  const TaskRowContent({
    super.key,
    required this.task,
    this.leading,
    this.trailing,
    this.showConvertAction = false,
    this.onConvertToProject,
    this.compact = false,
    this.useBodyText = false, // 是否使用普通文字大小（用于零散任务和子任务）
    this.taskLevel, // 任务的层级（level），用于判断是否是子任务，level > 1 表示是子任务
    this.isEditingNotifier, // 编辑状态通知器，用于控制拖拽和滑动
  });

  final Task task;
  final Widget? leading;
  final Widget? trailing; // 尾部内容（如展开/收缩按钮）
  final bool showConvertAction;
  final VoidCallback? onConvertToProject;
  final bool compact; // 紧凑模式，用于子任务显示
  final bool useBodyText; // 是否使用普通文字大小（零散任务和子任务用）
  /// 任务的层级（level），用于判断是否是子任务
  /// level > 1 表示是子任务，子任务不显示截止日期
  final int? taskLevel;
  /// 编辑状态通知器，用于控制拖拽和滑动的启用/禁用
  final ValueNotifier<bool>? isEditingNotifier;

  @override
  ConsumerState<TaskRowContent> createState() => _TaskRowContentState();
}

class _TaskRowContentState extends ConsumerState<TaskRowContent> {


  Future<void> _saveTitle(String newTitle) async {
    try {
      final taskService = await ref.read(taskServiceProvider.future);
      await taskService.updateDetails(
        taskId: widget.task.id,
        payload: TaskUpdate(title: newTitle),
      );
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
    final isTrashed = widget.task.status == TaskStatus.trashed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 第一行：执行图标 + 标题 + 转换按钮
        TaskRowTitleEditor(
          task: widget.task,
          leading: widget.leading,
          trailing: widget.trailing,
          showConvertAction: widget.showConvertAction,
          onConvertToProject: widget.onConvertToProject,
          useBodyText: widget.useBodyText,
          onTitleChanged: _saveTitle,
          isEditingNotifier: widget.isEditingNotifier,
        ),

        // 第二行：标签 + 截止日期（可内联编辑）
        // trashed 状态不显示标签和截止日期
        if (!isTrashed)
          _buildTagsAndDeadlineRow(context, ref, theme),
      ],
    );
  }

  Widget _buildTagsAndDeadlineRow(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    // 如果是子任务（level > 1），不显示标签和项目功能
    final isSubtask = widget.taskLevel != null && widget.taskLevel! > 1;

    // 如果紧凑模式且没有标签、截止日期和项目/里程碑，则不显示
    final hierarchyAsync = ref.watch(
      taskProjectHierarchyProvider(widget.task.id),
    );
    final hasProject = hierarchyAsync.hasValue && hierarchyAsync.value != null;

    if (widget.compact &&
        widget.task.tags.isEmpty &&
        widget.task.dueAt == null &&
        !hasProject) {
      return const SizedBox.shrink();
    }

    // 如果是子任务，不显示任何标签和项目功能（包括截止日期）
    if (isSubtask) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          // 已选中的标签（可删除）
          ...widget.task.tags.map((slug) {
            // 使用 TagService 统一处理，自动兼容旧数据（带前缀的 slug）
            final tagData = TagService.getTagData(context, slug);
            if (tagData == null) {
              return const SizedBox.shrink(); // 无效标签不显示
            }
            return InlineEditableTag(
              label: tagData.label,
              slug: tagData.slug, // 使用规范化后的 slug（无前缀）
              color: tagData.color,
              icon: tagData.icon,
              prefix: tagData.prefix,
              onRemove: (removedSlug) => _handleRemoveTag(ref, removedSlug),
            );
          }),
          // 添加标签按钮
          _buildAddTagButton(context, ref),
          // 项目/里程碑按钮或显示
          _buildProjectMilestoneButton(context, ref),
          // 截止日期编辑器（和标签同一行）
          // 如果是子任务（level > 1），不显示截止日期编辑器
          if ((widget.taskLevel == null || widget.taskLevel! <= 1) &&
              (widget.task.dueAt != null || !widget.compact))
            InlineDeadlineEditor(
              deadline: widget.task.dueAt,
              onDeadlineChanged: (newDeadline) =>
                  _handleDeadlineChanged(ref, newDeadline),
              showIcon: true,
              taskLevel: widget.taskLevel,
            ),
          // 复制按钮（放在截止日期后面）
          if (widget.taskLevel == null || widget.taskLevel! <= 1)
            TaskCopyButton(
              taskTitle: widget.task.title,
            ),
          // 开始计时按钮（放在复制按钮后面）
          // 只在任务状态为 pending（任务清单页面）时显示
          if ((widget.taskLevel == null || widget.taskLevel! <= 1) &&
              widget.task.status == TaskStatus.pending)
            TaskStartTimerButton(
              task: widget.task,
            ),
        ],
      ),
    );
  }

  Widget _buildAddTagButton(BuildContext context, WidgetRef ref) {
    final tagGroups = _getAvailableTagGroups(context, ref);
    if (tagGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    return TagAddButton(
      tagGroups: tagGroups,
      onTagSelected: (slug) => _handleAddTag(ref, slug),
    );
  }

  /// 获取可用的标签组（未选择的标签组）
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

  /// 处理添加标签
  Future<void> _handleAddTag(WidgetRef ref, String slug) async {
    try {
      final taskService = await ref.read(taskServiceProvider.future);

      // 检查是否是同组标签，如果是则先删除同组的旧标签
      // 使用 TagService 判断同组关系（兼容旧数据）
      String? tagToRemove;
      for (final existingTag in widget.task.tags) {
        if (TagService.areInSameGroup(slug, existingTag)) {
          tagToRemove = existingTag;
          break;
        }
      }

      // 构建新的标签列表
      List<String> updatedTags = List.from(widget.task.tags);

      // 先删除同组标签
      if (tagToRemove != null && tagToRemove.isNotEmpty) {
        updatedTags = updatedTags.where((t) => t != tagToRemove).toList();
      }

      // 添加新标签（确保使用规范化后的 slug）
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

  /// 处理删除标签
  Future<void> _handleRemoveTag(WidgetRef ref, String slug) async {
    try {
      final taskService = await ref.read(taskServiceProvider.future);
      // 规范化 slug（确保兼容旧数据）
      final normalizedSlug = TagService.normalizeSlug(slug);
      // 从任务的标签列表中移除（规范化后比较）
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

  /// 处理截止日期变更
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

  /// 构建项目/里程碑按钮或显示组件
  Widget _buildProjectMilestoneButton(BuildContext context, WidgetRef ref) {
    final hierarchyAsync = ref.watch(
      taskProjectHierarchyProvider(widget.task.id),
    );

    return hierarchyAsync.when(
      data: (hierarchy) {
        if (hierarchy == null) {
          // 未关联项目/里程碑，显示"加入项目"按钮
          // 注意：不使用 widget.task.projectId，因为 widget 属性不会自动更新
          // 而是从最新的 hierarchy 状态判断（如果为 null，说明没有项目）
          return ProjectMilestonePicker(
            onSelected: (selection) =>
                _handleProjectMilestoneChanged(ref, selection),
            // 使用 null，因为 hierarchy 已经是 null
            currentProjectId: null,
            currentMilestoneId: null,
          );
        } else {
          // 已关联，显示项目/里程碑信息
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
        debugPrint('Failed to load project hierarchy: $error');
        // 出错时显示"加入项目"按钮
        return ProjectMilestonePicker(
          onSelected: (selection) =>
              _handleProjectMilestoneChanged(ref, selection),
          currentProjectId: null,
          currentMilestoneId: null,
        );
      },
    );
  }

  /// 处理项目/里程碑变更
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

      // taskProjectHierarchyProvider 现在是 StreamProvider，会自动响应任务变化
      // 不需要手动刷新，stream 会自动触发更新
      // 但是，为了确保其他相关 provider 也能更新，我们仍然需要刷新它们
      if (mounted) {
        // 如果任务在 inbox 中，刷新 inbox provider
        if (widget.task.status == TaskStatus.inbox) {
          ref.invalidate(inboxTasksProvider);
          // inbox 相关的依赖 provider 也会自动刷新
        }

        // 如果任务是 pending 状态且有 dueAt，刷新对应的 section provider
        // 项目/里程碑变更不会改变任务的 section（除非 dueAt 也改变）
        if (widget.task.status == TaskStatus.pending && widget.task.dueAt != null) {
          final section = TaskSectionUtils.getSectionForDate(widget.task.dueAt);
          ref.invalidate(taskSectionsProvider(section));

          // 刷新该 section 相关的 level map 和 children map provider
          ref.invalidate(
            tasksSectionTaskLevelMapProvider(section),
          );
          ref.invalidate(
            tasksSectionTaskChildrenMapProvider(section),
          );
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
}
