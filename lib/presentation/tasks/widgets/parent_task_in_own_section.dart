import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../widgets/dismissible_task_tile.dart';
import '../../widgets/swipe_action_handler.dart';
import '../../widgets/swipe_action_type.dart';
import '../../widgets/swipe_configs.dart';
import '../../widgets/task_tile_content.dart';
import 'all_children_list.dart';
import 'parent_task_header.dart';

/// 父任务在自己分区的完整展示
/// - 顶部展示完整任务卡片（与普通任务一致，可滑动）
/// - 提供“显示全部子任务”按钮，展开只读的一层子任务列表
class ParentTaskInOwnSection extends ConsumerStatefulWidget {
  const ParentTaskInOwnSection({
    super.key,
    required this.parentTask,
    required this.currentSection,
  });

  final Task parentTask;
  final TaskSection currentSection;

  @override
  ConsumerState<ParentTaskInOwnSection> createState() => _ParentTaskInOwnSectionState();
}

class _ParentTaskInOwnSectionState extends ConsumerState<ParentTaskInOwnSection> {
  bool _showChildren = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // 是否有子任务
    final childrenCountAsync = ref.watch(parentTaskChildrenCountProvider(widget.parentTask.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 完整任务卡片
          DismissibleTaskTile(
            task: widget.parentTask,
            config: SwipeConfigs.tasksConfig,
            direction: DismissDirection.horizontal,
            onLeftAction: (task) => SwipeActionHandler.handleAction(
              context,
              ref,
              SwipeActionType.complete,
              task,
            ),
            onRightAction: (task) => SwipeActionHandler.handleAction(
              context,
              ref,
              SwipeActionType.archive,
              task,
            ),
            child: TaskTileContent(task: widget.parentTask),
          ),
          // 底部操作行：显示全部子任务
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 8, bottom: 8, top: 4),
            child: Row(
              children: [
                const SizedBox(width: 8),
                childrenCountAsync.when(
                  data: (count) => count > 0
                      ? TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showChildren = !_showChildren;
                            });
                          },
                          icon: Icon(_showChildren ? Icons.expand_less : Icons.expand_more),
                          label: Text(l10n.showAllSubtasks),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          if (_showChildren)
            AllChildrenList(
              parentTaskId: widget.parentTask.id,
              currentSection: widget.currentSection,
            ),
        ],
      ),
    );
  }
}


