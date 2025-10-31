import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../data/models/task.dart';
import '../../generated/l10n/app_localizations.dart';
import '../tasks/utils/hierarchy_utils.dart';
import 'task_row_content.dart';

/// 统一的任务卡片内容布局
/// 
/// 包含：
/// - 左侧拖拽指示器（drag_indicator 图标）
/// - 右侧任务内容（TaskRowContent，支持 inline 编辑）
/// - 拖拽到任务上时，可将被拖拽的 task 变成子任务（DragTarget）
/// 
/// 用于 Inbox 和 Tasks 页面，确保视觉和交互的完全一致性。
/// 
/// 使用方式：
/// ```dart
/// TaskTileContent(task: myTask)
/// ```
class TaskTileContent extends ConsumerStatefulWidget {
  const TaskTileContent({
    super.key,
    required this.task,
    this.compact = false,
    this.leading,
  });

  final Task task;
  final bool compact;
  final Widget? leading;

  @override
  ConsumerState<TaskTileContent> createState() => _TaskTileContentState();
}

class _TaskTileContentState extends ConsumerState<TaskTileContent> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // 包裹 DragTarget，支持拖拽到任务上变成子任务
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        final draggedTask = details.data;
        // 同步检查基本条件
        return _canAcceptAsChildSync(draggedTask, widget.task);
      },
      onAcceptWithDetails: (details) async {
        final draggedTask = details.data;
        await _handleDropOnTask(draggedTask, widget.task, context, l10n);
      },
      onMove: (_) {
        if (!_isHovering) {
          setState(() {
            _isHovering = true;
          });
        }
      },
      onLeave: (_) {
        if (_isHovering) {
          setState(() {
            _isHovering = false;
          });
        }
      },
      builder: (context, candidate, rejected) {
        // 当有拖拽的 task 悬停在当前 task 上时，改变背景色
        final isHovering = candidate.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isHovering
                ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _buildContent(),
        );
      },
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 拖拽指示器
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 4),
            child: widget.leading ?? Icon(
              Icons.drag_indicator,
              color: Colors.grey[400],
              size: 20,
            ),
          ),
          // 任务内容（使用 TaskRowContent 实现 inline 编辑）
          Expanded(
            child: TaskRowContent(
              task: widget.task,
              compact: widget.compact,
            ),
          ),
        ],
      ),
    );
  }

  /// 同步检查是否可以将 draggedTask 作为 targetTask 的子任务
  /// 
  /// 这个方法只做可以同步检查的基本验证，异步的深度检查在 onAccept 中完成
  bool _canAcceptAsChildSync(Task draggedTask, Task targetTask) {
    // 不能拖拽到自己
    if (draggedTask.id == targetTask.id) {
      return false;
    }
    // 不能拖拽到自己的直接父任务上（避免无效操作）
    if (draggedTask.parentId == targetTask.id) {
      return false;
    }
    // 检查 target task 是否被锁定（不能添加子任务）
    if (!canAcceptChildren(targetTask)) {
      return false;
    }
    // 检查 dragged task 是否被锁定（不能移动）
    if (!canMoveTask(draggedTask)) {
      return false;
    }
    return true;
  }

  /// 处理拖拽到任务上，将 draggedTask 变成 targetTask 的子任务
  Future<void> _handleDropOnTask(
    Task draggedTask,
    Task targetTask,
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    try {
      final taskHierarchyService = ref.read(taskHierarchyServiceProvider);
      final taskRepository = ref.read(taskRepositoryProvider);

      // 异步验证循环引用（在 Service 层也会验证，但这里提前验证可以避免不必要的计算）
      if (await hasCircularReference(draggedTask, targetTask.id, taskRepository)) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.taskListSortError)),
        );
        return;
      }

      // 使用 Service 层的计算方法计算 sortIndex
      final newSortIndex = await taskHierarchyService.calculateSortIndexForNewChild(
        targetTask.id,
      );

      await taskHierarchyService.moveToParent(
        taskId: draggedTask.id,
        parentId: targetTask.id,
        sortIndex: newSortIndex,
      );

      if (!context.mounted) return;

      // 可选：显示成功提示（如果需要的话，可以取消注释）
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text(l10n.taskBecameSubtask ?? 'Task became subtask')),
      // );
    } catch (error, stackTrace) {
      debugPrint('Failed to make task a subtask: $error\n$stackTrace');
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.taskListSortError)),
      );
    }
  }
}
