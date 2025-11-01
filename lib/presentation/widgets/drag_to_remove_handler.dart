import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/service_providers.dart';
import '../common/drag/task_drag_intent_target.dart';

/// 拖拽到此区域以移除父任务（parentId = null）
class DragToRemoveHandler extends ConsumerWidget {
  const DragToRemoveHandler({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return TaskDragIntentTarget.surface(
      meta: const TaskDragIntentMeta(page: 'Tasks', targetType: 'removeParent'),
      hoverColor: theme.colorScheme.errorContainer.withValues(alpha: 0.24),
      canAccept: (task, _) {
        if (kDebugMode) {
          debugPrint(
            '[DnD] {event: willAccept, page: Tasks, action: removeParent, src: ${task.id}}',
          );
        }
        return true;
      },
      onPerform: (task, ref, context, l10n) async {
        if (kDebugMode) {
          debugPrint(
            '[DnD] {event: accept:start, page: Tasks, action: removeParent, src: ${task.id}}',
          );
        }
        try {
          final hierarchy = ref.read(taskHierarchyServiceProvider);
          await hierarchy.moveToParent(
            taskId: task.id,
            parentId: null,
            sortIndex: task.sortIndex,
            clearParent: true,
          );
          if (kDebugMode) {
            debugPrint(
              '[DnD] {event: accept:success, page: Tasks, action: removeParent, src: ${task.id}}',
            );
          }
          return const TaskDragIntentResult.success(clearParent: true);
        } catch (error) {
          if (kDebugMode) {
            debugPrint(
              '[DnD] {event: accept:error, page: Tasks, action: removeParent, src: ${task.id}, error: $error}',
            );
          }
          return const TaskDragIntentResult.blocked(
            blockReasonKey: 'taskMoveBlockedUnknown',
            blockLogTag: 'removeParentError',
          );
        }
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.25),
          ),
        ),
        child: Icon(
          Icons.call_missed_outgoing,
          size: 18,
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}
