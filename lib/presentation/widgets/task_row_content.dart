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
import 'tag_data.dart';
import 'modern_tag.dart';
import '../../data/models/tag.dart';

/// 通用的任务行内容组件，支持内联编辑标签和截止日期
/// 可在Tasks、Inbox、Projects子任务、轻量任务等多个场景复用
class TaskRowContent extends ConsumerWidget {
  const TaskRowContent({
    super.key,
    required this.task,
    this.leading,
    this.showConvertAction = false,
    this.onConvertToProject,
    this.compact = false,
    this.showTaskId = false,
  });

  final Task task;
  final Widget? leading;
  final bool showConvertAction;
  final VoidCallback? onConvertToProject;
  final bool compact; // 紧凑模式，用于子任务显示
  final bool showTaskId; // 是否显示任务ID（用于调试）

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 第一行：执行图标 + 标题 + 转换按钮
        _buildTitleRow(context, theme),
        
        // 第二行：标签（可内联编辑）
        _buildTagsRow(context, ref, theme),
        
        // 第三行：截止日期（可内联编辑）
        if (task.dueAt != null || !compact)
          _buildDeadlineRow(context, ref, theme),
      ],
    );
  }

  Widget _buildTitleRow(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final isCompleted = task.status == TaskStatus.completedActive;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null)
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 4),
            child: leading!,
          ),
        Expanded(
          child: Text(
            task.title,
            style: theme.textTheme.titleMedium?.copyWith(
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        if (showConvertAction)
          IconButton(
            onPressed: onConvertToProject,
            tooltip: l10n.projectConvertTooltip,
            icon: Icon(Icons.autorenew, color: theme.colorScheme.primary),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  Widget _buildTagsRow(BuildContext context, WidgetRef ref, ThemeData theme) {
    if (task.tags.isEmpty && compact) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          // 已选中的标签（可删除）
          ...task.tags.map((slug) {
            final tagData = _slugToTagData(context, slug);
            if (tagData == null) return const SizedBox.shrink();
            return InlineEditableTag(
              label: tagData.label,
              slug: slug,
              color: tagData.color,
              icon: tagData.icon,
              prefix: tagData.prefix,
              size: compact ? TagSize.small : TagSize.medium,
              variant: TagVariant.pill,
              onRemove: (removedSlug) => _handleRemoveTag(ref, removedSlug),
            );
          }),
          // 添加标签按钮
          _buildAddTagButton(context, ref),
        ],
      ),
    );
  }

  Widget _buildDeadlineRow(BuildContext context, WidgetRef ref, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          // TaskId（如果需要显示）
          if (showTaskId)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'ID: ${task.taskId}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          // 截止日期编辑器
          InlineDeadlineEditor(
            deadline: task.dueAt,
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
    final hasUrgencyTag = task.tags.any((t) => t == '#urgent' || t == '#not_urgent');
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
    final hasImportanceTag = task.tags.any((t) => t == '#important' || t == '#not_important');
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
    final hasExecutionTag = task.tags.any((t) => 
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
    final hasContextTag = task.tags.any((t) => t.startsWith('@'));
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
        tagToRemove = task.tags.firstWhere(
          (t) => t == '#urgent' || t == '#not_urgent',
          orElse: () => '',
        );
      } else if (slug == '#important' || slug == '#not_important') {
        tagToRemove = task.tags.firstWhere(
          (t) => t == '#important' || t == '#not_important',
          orElse: () => '',
        );
      } else if (slug == '#timed' || slug == '#fragmented' || slug == '#waiting') {
        tagToRemove = task.tags.firstWhere(
          (t) => t == '#timed' || t == '#fragmented' || t == '#waiting',
          orElse: () => '',
        );
      } else if (slug.startsWith('@')) {
        tagToRemove = task.tags.firstWhere(
          (t) => t.startsWith('@'),
          orElse: () => '',
        );
      }

      // 构建新的标签列表
      List<String> updatedTags = List.from(task.tags);
      
      // 先删除同组标签
      if (tagToRemove != null && tagToRemove.isNotEmpty) {
        updatedTags = updatedTags.where((t) => t != tagToRemove).toList();
      }

      // 添加新标签
      updatedTags.add(slug);
      
      await taskService.updateDetails(
        taskId: task.id,
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
      final updatedTags = task.tags.where((t) => t != slug).toList();
      await taskService.updateDetails(
        taskId: task.id,
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
        taskId: task.id,
        payload: TaskUpdate(dueAt: newDeadline),
      );
    } catch (e) {
      debugPrint('Failed to update deadline: $e');
    }
  }
}

/// 辅助函数：将标签slug转换为TagData（使用国际化）
TagData? _slugToTagData(BuildContext context, String slug) {
  final l10n = AppLocalizations.of(context);
  
  // 获取本地化标签文本
  final label = _getLocalizedLabel(l10n, slug);
  
  // 确定标签类型
  TagKind kind;
  if (slug.startsWith('@')) {
    kind = TagKind.context;
  } else if (slug == '#urgent' || slug == '#not_urgent') {
    kind = TagKind.urgency;
  } else if (slug == '#important' || slug == '#not_important') {
    kind = TagKind.importance;
  } else if (slug == '#timed' || slug == '#fragmented' || slug == '#waiting') {
    kind = TagKind.execution;
  } else {
    kind = TagKind.special;
  }
  
  // 获取样式
  final (color, icon, prefix) = _getTagStyle(slug, kind);
  
  return TagData(
    slug: slug,
    label: label,
    color: color,
    icon: icon,
    prefix: prefix,
    kind: kind,
  );
}

/// 获取本地化标签文本
String _getLocalizedLabel(AppLocalizations l10n, String slug) {
  switch (slug) {
    // 紧急程度
    case '#urgent':
      return l10n.tag_urgent;
    case '#not_urgent':
      return l10n.tag_not_urgent;
    // 重要程度
    case '#important':
      return l10n.tag_important;
    case '#not_important':
      return l10n.tag_not_important;
    // 执行方式
    case '#timed':
      return l10n.tag_timed;
    case '#fragmented':
      return l10n.tag_fragmented;
    case '#waiting':
      return l10n.tag_waiting;
    // 上下文
    case '@anywhere':
      return l10n.tag_anywhere;
    case '@home':
      return l10n.tag_home;
    case '@workplace':
      return l10n.tag_workplace;
    case '@local':
      return l10n.tag_local;
    case '@travel':
      return l10n.tag_travel;
    default:
      // 移除前缀作为回退
      return slug.replaceAll('@', '').replaceAll('#', '');
  }
}

/// 获取标签样式（颜色、图标、前缀）
/// 注意：prefix 返回 null，因为 l10n 翻译中已包含前缀（如 "@屋企"、"#緊急"）
(Color, IconData?, String?) _getTagStyle(String slug, TagKind kind) {
  // 上下文标签
  if (slug.startsWith('@')) {
    switch (slug) {
      case '@anywhere':
        return (const Color(0xFF7F8CFF), Icons.public, null);
      case '@home':
        return (const Color(0xFF5AC9B0), Icons.home, null);
      case '@workplace':
        return (const Color(0xFFFFB86C), Icons.business, null);
      case '@local':
        return (const Color(0xFFFF85A2), Icons.location_on, null);
      case '@travel':
        return (const Color(0xFF8BE9FD), Icons.flight, null);
      default:
        return (const Color(0xFF7F8CFF), Icons.label, null);
    }
  }
  
  // 四象限和执行方式标签
  switch (slug) {
    case '#urgent':
      return (const Color(0xFFFF5555), Icons.priority_high, null);
    case '#not_urgent':
      return (const Color(0xFF50FA7B), Icons.schedule, null);
    case '#important':
      return (const Color(0xFFFFB86C), Icons.star, null);
    case '#not_important':
      return (const Color(0xFFBDBDBD), Icons.star_border, null);
    case '#timed':
      return (const Color(0xFF8BE9FD), Icons.timer, null);
    case '#fragmented':
      return (const Color(0xFFF1FA8C), Icons.grain, null);
    case '#waiting':
      return (const Color(0xFFFFB86C), Icons.hourglass_empty, null);
    default:
      return (const Color(0xFF64B5F6), Icons.tag, null);
  }
}
