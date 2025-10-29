import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../data/models/task.dart';
import '../../generated/l10n/app_localizations.dart';
import 'inline_editable_tag.dart';
import 'inline_deadline_editor.dart';
import 'tag_add_button.dart';
import 'tag_grouped_menu.dart';
import 'modern_tag.dart';
import 'tag_data.dart';
import '../../data/models/tag.dart';

/// 通用的任务行内容组件，支持内联编辑标签和截止日期
/// 可在Tasks、Inbox、Projects子任务、轻量任务等多个场景复用
class TaskRowContent extends ConsumerStatefulWidget {
  const TaskRowContent({
    super.key,
    required this.task,
    this.leading,
    this.showConvertAction = false,
    this.onConvertToProject,
    this.compact = false,
    this.useBodyText = false, // 是否使用普通文字大小（用于零散任务和子任务）
  });

  final Task task;
  final Widget? leading;
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
    // 如果紧凑模式且没有标签和截止日期，则不显示
    if (widget.compact && widget.task.tags.isEmpty && widget.task.dueAt == null) {
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
            final tagData = TagData.fromTagWithLocalization(
              Tag(
                id: 0,
                slug: slug,
                kind: _getTagKindFromSlug(slug),
                localizedLabels: const {},
              ),
              context,
            );
            return InlineEditableTag(
              label: tagData.label,
              slug: slug,
              color: tagData.color,
              icon: tagData.icon,
              prefix: tagData.prefix,
              size: widget.compact ? TagSize.small : TagSize.medium,
              variant: TagVariant.pill,
              onRemove: (removedSlug) => _handleRemoveTag(ref, removedSlug),
            );
          }),
          // 添加标签按钮
          _buildAddTagButton(context, ref),
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
    final hasUrgencyTag = widget.task.tags.any((t) => t == '#urgent' || t == '#not_urgent');
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
    final hasImportanceTag = widget.task.tags.any((t) => t == '#important' || t == '#not_important');
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
      t == '#timed' || t == '#fragmented' || t == '#waiting'
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
    final hasContextTag = widget.task.tags.any((t) => t.startsWith('@'));
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
      String? tagToRemove;
      if (slug == '#urgent' || slug == '#not_urgent') {
        tagToRemove = widget.task.tags.firstWhere(
          (t) => t == '#urgent' || t == '#not_urgent',
          orElse: () => '',
        );
      } else if (slug == '#important' || slug == '#not_important') {
        tagToRemove = widget.task.tags.firstWhere(
          (t) => t == '#important' || t == '#not_important',
          orElse: () => '',
        );
      } else if (slug == '#timed' || slug == '#fragmented' || slug == '#waiting') {
        tagToRemove = widget.task.tags.firstWhere(
          (t) => t == '#timed' || t == '#fragmented' || t == '#waiting',
          orElse: () => '',
        );
      } else if (slug.startsWith('@')) {
        tagToRemove = widget.task.tags.firstWhere(
          (t) => t.startsWith('@'),
          orElse: () => '',
        );
      }

      // 构建新的标签列表
      List<String> updatedTags = List.from(widget.task.tags);
      
      // 先删除同组标签
      if (tagToRemove != null && tagToRemove.isNotEmpty) {
        updatedTags = updatedTags.where((t) => t != tagToRemove).toList();
      }

      // 添加新标签
      updatedTags.add(slug);
      
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
      // 从任务的标签列表中移除
      final updatedTags = widget.task.tags.where((t) => t != slug).toList();
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
}

/// 从 slug 推测 TagKind
TagKind _getTagKindFromSlug(String slug) {
  if (slug.startsWith('@')) {
    return TagKind.context;
  } else if (slug == '#urgent' || slug == '#not_urgent') {
    return TagKind.urgency;
  } else if (slug == '#important' || slug == '#not_important') {
    return TagKind.importance;
  } else if (slug == '#timed' || slug == '#fragmented' || slug == '#waiting') {
    return TagKind.execution;
  } else {
    return TagKind.special;
  }
}

