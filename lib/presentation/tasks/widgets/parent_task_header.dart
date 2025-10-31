import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import 'all_children_list.dart';

/// 父任务头部组件
/// 
/// 显示父任务的简化信息：
/// - 浅色背景
/// - 层级图标
/// - 任务标题（截断，hover 显示完整）
/// - 跳转到父任务所在区域的按钮
/// - 显示全部子任务按钮（如果有其他子任务）
class ParentTaskHeader extends ConsumerStatefulWidget {
  const ParentTaskHeader({
    super.key,
    required this.parentTask,
    required this.currentSection,
    this.depth = 0,
  });

  final Task parentTask;
  final TaskSection currentSection;
  final int depth;

  @override
  ConsumerState<ParentTaskHeader> createState() => _ParentTaskHeaderState();
}

class _ParentTaskHeaderState extends ConsumerState<ParentTaskHeader> {
  bool _showAllChildren = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // 检查是否有其他子任务（除了当前正在显示的子任务）
    final childrenCountAsync = ref.watch(
      parentTaskChildrenCountProvider(widget.parentTask.id),
    );

    return childrenCountAsync.when(
      data: (count) => _buildContent(context, theme, l10n, count > 0),
      loading: () => _buildContent(context, theme, l10n, false),
      error: (_, __) => _buildContent(context, theme, l10n, false),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    bool hasOtherChildren,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 4),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // 层级图标（使用 Material Icons）
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.subdirectory_arrow_right,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                // 任务标题（截断）
                Expanded(
                  child: Tooltip(
                    message: widget.parentTask.title,
                    child: Text(
                      widget.parentTask.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // 跳转到父任务所在区域的按钮
                IconButton(
                  icon: const Icon(Icons.north_east, size: 18),
                  tooltip: '跳转到父任务',
                  onPressed: () => _jumpToParentTask(context, ref),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                // 显示全部子任务按钮（如果有其他子任务）
                if (hasOtherChildren)
                  IconButton(
                    icon: Icon(
                      _showAllChildren ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                    ),
                    tooltip: '显示全部子任务',
                    onPressed: () {
                      setState(() {
                        _showAllChildren = !_showAllChildren;
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
            // 显示全部子任务列表
          if (_showAllChildren && hasOtherChildren)
            AllChildrenList(
              parentTaskId: widget.parentTask.id,
              currentSection: widget.currentSection,
            ),
        ],
      ),
    );
  }

  Future<void> _jumpToParentTask(BuildContext context, WidgetRef ref) async {
    // 查找父任务所在的区域
    final taskRepository = ref.read(taskRepositoryProvider);
    final parentTask = await taskRepository.findById(widget.parentTask.id);
    if (parentTask == null) {
      return;
    }

    // TODO: 实现跳转到父任务所在区域的功能
    // 这需要找到父任务所在的 section，然后滚动到那个区域
    // 暂时显示一个提示
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '跳转到父任务: ${parentTask.title}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Provider: 获取父任务的子任务数量（排除 trashed）
final parentTaskChildrenCountProvider = FutureProvider.family<int, int>((ref, parentId) async {
  final taskRepository = ref.read(taskRepositoryProvider);
  final children = await taskRepository.listChildren(parentId);
  return children.length;
});

