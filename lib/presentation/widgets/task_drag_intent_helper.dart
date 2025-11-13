import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task.dart';
import '../../generated/l10n/app_localizations.dart';
import '../common/drag/task_drag_intent_target.dart';

/// 任务拖拽意图处理辅助类
///
/// 子任务功能已禁用，此类仅保留方法签名以保持兼容性。
class TaskDragIntentHelper {
  TaskDragIntentHelper._();

  /// 同步检查是否可以将 draggedTask 作为 targetTask 的子任务
  ///
  /// 子任务功能已禁用，总是返回 false。
  static bool canAcceptAsChild(Task draggedTask, Task targetTask) {
    // 子任务功能已禁用
    return false;
  }

  /// 处理拖拽放置到目标任务上的逻辑
  ///
  /// 子任务功能已禁用，总是返回 blocked 结果。
  static Future<TaskDragIntentResult> handleDropOnTask(
    Task draggedTask,
    Task targetTask,
    BuildContext context,
    WidgetRef ref,
    AppLocalizations? l10n,
  ) async {
    // 子任务功能已禁用
    return const TaskDragIntentResult.blocked(
      blockReasonKey: 'taskMoveBlockedSubtaskDisabled',
      blockLogTag: 'subtaskDisabled',
    );
  }
}
