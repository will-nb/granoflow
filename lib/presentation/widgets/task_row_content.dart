import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../core/services/tag_service.dart';
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
  });

  final Task task;
  final Widget? leading;
  final Widget? trailing; // 尾部内容（如展开/收缩按钮）
  final bool showConvertAction;
  final VoidCallback? onConvertToProject;
  final bool compact; // 紧凑模式，用于子任务显示
  final bool useBodyText; // 是否使用普通文字大小（零散任务和子任务用）

  @override
  ConsumerState<TaskRowContent> createState() => _TaskRowContentState();
}

class _TaskRowContentState extends ConsumerState<TaskRowContent> {
  late TextEditingController _titleController;
  late FocusNode _titleFocusNode;
  bool _isEditingTitle = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _titleFocusNode = FocusNode();
    _titleFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _titleFocusNode.removeListener(_onFocusChange);
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TaskRowContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果任务标题从外部更新，同步到控制器
    if (widget.task.title != oldWidget.task.title && !_isEditingTitle) {
      _titleController.text = widget.task.title;
    }
  }

  void _onFocusChange() {
    if (!_titleFocusNode.hasFocus && _isEditingTitle) {
      _saveTitle();
    }
  }

  Future<void> _saveTitle() async {
    final newTitle = _titleController.text.trim();
    if (newTitle.isEmpty) {
      // 如果为空，恢复原标题
      _titleController.text = widget.task.title;
      setState(() {
        _isEditingTitle = false;
      });
      return;
    }

    if (newTitle != widget.task.title) {
      try {
        final taskService = ref.read(taskServiceProvider);
        await taskService.updateDetails(
          taskId: widget.task.id,
          payload: TaskUpdate(title: newTitle),
        );
      } catch (error) {
        // 如果保存失败，恢复原标题
        _titleController.text = widget.task.title;
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

    if (mounted) {
      setState(() {
        _isEditingTitle = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 第一行：执行图标 + 标题 + 转换按钮
        _buildTitleRow(context, theme),
        
        // 第二行：标签 + 截止日期（可内联编辑）
        _buildTagsAndDeadlineRow(context, ref, theme),
      ],
    );
  }

  Widget _buildTitleRow(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final isCompleted = widget.task.status == TaskStatus.completedActive;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.leading != null)
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 4),
            child: widget.leading!,
          ),
        Expanded(
          child: _isEditingTitle
              ? TextField(
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  style: (widget.useBodyText ? theme.textTheme.bodyLarge : theme.textTheme.titleMedium),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    isDense: true,
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saveTitle(),
                )
              : GestureDetector(
                  onTap: () {
                    setState(() {
                      _isEditingTitle = true;
                    });
                    // 延迟聚焦，确保TextField已经构建
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _titleFocusNode.requestFocus();
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      widget.task.title,
                      style: (widget.useBodyText ? theme.textTheme.bodyLarge : theme.textTheme.titleMedium)?.copyWith(
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ),
        ),
        if (widget.trailing != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: widget.trailing!,
          ),
        if (widget.showConvertAction)
          IconButton(
            onPressed: widget.onConvertToProject,
            tooltip: l10n.projectConvertTooltip,
            icon: Icon(Icons.autorenew, color: theme.colorScheme.primary),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  Widget _buildTagsAndDeadlineRow(BuildContext context, WidgetRef ref, ThemeData theme) {
    // 如果紧凑模式且没有标签、截止日期和项目/里程碑，则不显示
    final hierarchyAsync = ref.watch(taskProjectHierarchyProvider(widget.task.id));
    final hasProject = hierarchyAsync.hasValue && hierarchyAsync.value != null;
    
    if (widget.compact && 
        widget.task.tags.isEmpty && 
        widget.task.dueAt == null && 
        !hasProject) {
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
          if (widget.task.dueAt != null || !widget.compact)
            InlineDeadlineEditor(
              deadline: widget.task.dueAt,
              onDeadlineChanged: (newDeadline) => _handleDeadlineChanged(ref, newDeadline),
              showIcon: true,
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
    final tagGroups = <TagGroup>[];

    // 紧急程度组
    final urgencyTagsAsync = ref.watch(urgencyTagOptionsProvider);
    final hasUrgencyTag = widget.task.tags.any((t) => 
      TagService.getKind(t) == TagKind.urgency
    );
    if (!hasUrgencyTag) {
      urgencyTagsAsync.whenData((tags) {
        if (tags.isNotEmpty) {
          tagGroups.add(TagGroup(
            title: '紧急程度', // l10n.tag_group_urgency
            tags: tags.map((tag) => TagData.fromTagWithLocalization(tag, context)).toList(),
          ));
        }
      });
    }

    // 重要程度组
    final importanceTagsAsync = ref.watch(importanceTagOptionsProvider);
    final hasImportanceTag = widget.task.tags.any((t) => 
      TagService.getKind(t) == TagKind.importance
    );
    if (!hasImportanceTag) {
      importanceTagsAsync.whenData((tags) {
        if (tags.isNotEmpty) {
          tagGroups.add(TagGroup(
            title: '重要程度', // l10n.tag_group_importance
            tags: tags.map((tag) => TagData.fromTagWithLocalization(tag, context)).toList(),
          ));
        }
      });
    }

    // 执行方式组
    final executionTagsAsync = ref.watch(executionTagOptionsProvider);
    final hasExecutionTag = widget.task.tags.any((t) => 
      TagService.getKind(t) == TagKind.execution
    );
    if (!hasExecutionTag) {
      executionTagsAsync.whenData((tags) {
        if (tags.isNotEmpty) {
          tagGroups.add(TagGroup(
            title: '执行方式', // l10n.tag_group_execution
            tags: tags.map((tag) => TagData.fromTagWithLocalization(tag, context)).toList(),
          ));
        }
      });
    }

    // 上下文组
    final contextTagsAsync = ref.watch(contextTagOptionsProvider);
    final hasContextTag = widget.task.tags.any((t) => 
      TagService.getKind(t) == TagKind.context
    );
    if (!hasContextTag) {
      contextTagsAsync.whenData((tags) {
        if (tags.isNotEmpty) {
          tagGroups.add(TagGroup(
            title: '上下文', // l10n.tag_group_context
            tags: tags.map((tag) => TagData.fromTagWithLocalization(tag, context)).toList(),
          ));
        }
      });
    }

    return tagGroups;
  }

  /// 处理添加标签
  Future<void> _handleAddTag(WidgetRef ref, String slug) async {
    try {
      final taskService = ref.read(taskServiceProvider);
      
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
      final taskService = ref.read(taskServiceProvider);
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
  Future<void> _handleDeadlineChanged(WidgetRef ref, DateTime? newDeadline) async {
    try {
      final taskService = ref.read(taskServiceProvider);
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
    final hierarchyAsync = ref.watch(taskProjectHierarchyProvider(widget.task.id));

    return hierarchyAsync.when(
      data: (hierarchy) {
        if (hierarchy == null) {
          // 未关联项目/里程碑，显示"加入项目"按钮
          return ProjectMilestonePicker(
            onSelected: (taskId) => _handleProjectMilestoneChanged(ref, taskId),
            currentParentId: widget.task.parentId,
          );
        } else {
          // 已关联，显示项目/里程碑信息
          return InlineProjectMilestoneDisplay(
            project: hierarchy.project,
            milestone: hierarchy.milestone,
            onSelected: (taskId) => _handleProjectMilestoneChanged(ref, taskId),
            currentParentId: widget.task.parentId,
          );
        }
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) {
        debugPrint('Failed to load project hierarchy: $error');
        // 出错时显示"加入项目"按钮
        return ProjectMilestonePicker(
          onSelected: (taskId) => _handleProjectMilestoneChanged(ref, taskId),
          currentParentId: widget.task.parentId,
        );
      },
    );
  }

  /// 处理项目/里程碑变更
  Future<void> _handleProjectMilestoneChanged(WidgetRef ref, int? taskId) async {
    try {
      final taskService = ref.read(taskServiceProvider);
      await taskService.updateDetails(
        taskId: widget.task.id,
        payload: TaskUpdate(parentId: taskId),
      );
      // 刷新项目层级 provider，以便 UI 立即更新
      ref.invalidate(taskProjectHierarchyProvider(widget.task.id));
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


