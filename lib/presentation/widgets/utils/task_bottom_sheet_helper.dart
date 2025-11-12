import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/task.dart';
import '../task_action_bottom_sheet.dart';
import '../../review/widgets/task_detail_bottom_sheet.dart';

/// 底部弹窗显示工具类
/// 
/// 统一处理底部弹窗的显示逻辑（手势关闭、动画、样式等）
class TaskBottomSheetHelper {
  /// 根据任务状态自动选择显示哪个弹窗
  /// 
  /// [context] BuildContext
  /// [ref] WidgetRef
  /// [task] 要显示的任务
  static void showTaskBottomSheet(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) {
    // 根据任务状态决定显示哪个弹窗
    if (task.status == TaskStatus.completedActive ||
        task.status == TaskStatus.archived ||
        task.status == TaskStatus.trashed) {
      // 已完成、已归档、已删除：显示详情弹窗（只读）
      showTaskDetailBottomSheet(context, ref, task);
    } else {
      // inbox、pending、doing、paused：显示操作弹窗（可编辑）
      showTaskActionBottomSheet(context, ref, task);
    }
  }

  /// 显示任务操作弹窗
  /// 
  /// [context] BuildContext
  /// [ref] WidgetRef
  /// [task] 要操作的任务
  static void showTaskActionBottomSheet(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: TaskActionBottomSheet(
        task: task,
        ),
      ),
    );
  }

  /// 显示任务详情弹窗
  /// 
  /// [context] BuildContext
  /// [ref] WidgetRef
  /// [task] 要查看的任务
  static void showTaskDetailBottomSheet(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => TaskDetailBottomSheet(
        task: task,
      ),
    );
  }
}
