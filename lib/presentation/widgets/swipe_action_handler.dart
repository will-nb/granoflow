import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../core/utils/task_section_utils.dart';
import '../../generated/l10n/app_localizations.dart';
import 'swipe_action_handler/swipe_action_handler_date_utils.dart';
import 'swipe_action_type.dart';

/// 滑动动作处理器
/// 
/// 统一处理所有滑动动作的逻辑，包括快速规划、智能推迟、归档和删除
class SwipeActionHandler {
  /// 处理滑动动作
  /// 
  /// [context] - BuildContext
  /// [ref] - WidgetRef
  /// [actionType] - 滑动动作类型
  /// [task] - 要处理的任务
  /// [taskLevel] - 任务的层级（可选），用于提升为独立任务时避免重新计算
  static Future<void> handleAction(
    BuildContext context,
    WidgetRef ref,
    SwipeActionType actionType,
    Task task, {
    int? taskLevel,
  }) async {
    switch (actionType) {
      case SwipeActionType.quickPlan:
        await _handleQuickPlan(context, ref, task);
        break;
      case SwipeActionType.postpone:
        await _handlePostpone(context, ref, task);
        break;
      case SwipeActionType.complete:
        await _handleComplete(context, ref, task);
        break;
      case SwipeActionType.archive:
        await _handleArchive(context, ref, task);
        break;
      case SwipeActionType.delete:
        await _handleDelete(context, ref, task);
        break;
      case SwipeActionType.promoteToIndependent:
        await _handlePromoteToIndependent(context, ref, task, taskLevel: taskLevel);
        break;
      case SwipeActionType.restore:
        await _handleRestore(context, ref, task);
        break;
      case SwipeActionType.permanentDelete:
        await _handlePermanentDelete(context, ref, task);
        break;
    }
  }

  /// 处理快速规划动作
  static Future<void> _handleQuickPlan(BuildContext context, WidgetRef ref, Task task) async {
    final taskService = await ref.read(taskServiceProvider.future);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    
    // 保存原始状态，用于判断是否需要刷新特定页面
    final originalStatus = task.status;
    
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await taskService.planTask(taskId: task.id, dueDateLocal: today, section: TaskSection.today);
      if (!context.mounted) return;
      
      // 如果任务原本是已归档或已完成的，刷新相应的分页页面
      if (originalStatus == TaskStatus.archived) {
        ref.read(archivedTasksPaginationProvider.notifier).loadInitial();
      } else if (originalStatus == TaskStatus.completedActive) {
        ref.read(completedTasksPaginationProvider.notifier).loadInitial();
      }
      
      // 显示详细的成功反馈
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.inboxQuickPlanSuccessDetailed),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: l10n.commonView,
            onPressed: () {
              // TODO: 导航到任务页面
              debugPrint('Navigate to Tasks page');
            },
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to quick plan task: $error\n$stackTrace');
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('${l10n.inboxPlanError}: $error')));
    }
  }

  /// 处理智能推迟动作
  static Future<void> _handlePostpone(BuildContext context, WidgetRef ref, Task task) async {
    final taskService = await ref.read(taskServiceProvider.future);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      final nextDate = SwipeActionHandlerDateUtils.getNextScheduledDate(task.dueAt);
      final section = TaskSectionUtils.getSectionForDate(nextDate);
      await taskService.planTask(taskId: task.id, dueDateLocal: nextDate, section: section);
      if (!context.mounted) return;
      
      // 格式化日期显示
      final dateStr = SwipeActionHandlerDateUtils.formatDateForDisplay(nextDate);
      final message = l10n.taskPostponeSuccessDetailed(dateStr);
      
      // 显示详细的成功反馈
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: l10n.commonView,
            onPressed: () {
              // TODO: 导航到任务页面
              debugPrint('Navigate to Tasks page');
            },
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to postpone task: $error\n$stackTrace');
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('${l10n.taskPostponeError}: $error')));
    }
  }

  /// 处理完成任务动作
  static Future<void> _handleComplete(BuildContext context, WidgetRef ref, Task task) async {
    final taskService = await ref.read(taskServiceProvider.future);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      await taskService.markCompleted(taskId: task.id);
      if (!context.mounted) return;
      
      // 显示成功提示
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.taskListTaskCompletedToast),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to complete task: $error\n$stackTrace');
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('${l10n.taskListTaskCompletedError}: $error')));
    }
  }

  /// 处理归档动作
  static Future<void> _handleArchive(BuildContext context, WidgetRef ref, Task task) async {
    final taskService = await ref.read(taskServiceProvider.future);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      await taskService.archive(task.id);
      if (!context.mounted) return;
      
      // 显示详细的成功反馈
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.taskArchivedSuccessDetailed),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: l10n.commonView,
            onPressed: () {
              // TODO: 导航到归档页面
              debugPrint('Navigate to Archived page');
            },
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to archive task: $error\n$stackTrace');
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('${l10n.taskArchiveError}: $error')));
    }
  }

  /// 处理删除动作
  static Future<void> _handleDelete(BuildContext context, WidgetRef ref, Task task) async {
    final taskService = await ref.read(taskServiceProvider.future);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    
    // 保存原始状态，用于判断是否需要刷新特定页面
    final originalStatus = task.status;
    
    try {
      await taskService.softDelete(task.id);
      if (!context.mounted) return;
      
      // 如果任务原本是已归档或已完成的，刷新相应的分页页面
      if (originalStatus == TaskStatus.archived) {
        ref.read(archivedTasksPaginationProvider.notifier).loadInitial();
      } else if (originalStatus == TaskStatus.completedActive) {
        ref.read(completedTasksPaginationProvider.notifier).loadInitial();
      }
      
      // 显示详细的成功反馈
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.inboxDeletedToastDetailed),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: l10n.commonView,
            onPressed: () {
              // TODO: 导航到回收站页面
              debugPrint('Navigate to Trash page');
            },
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to delete task: $error\n$stackTrace');
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('${l10n.inboxDeleteError}: $error')));
    }
  }

  // 日期工具方法已移至 swipe_action_handler_date_utils.dart

  /// 处理提升为独立任务动作（滑动触发）
  /// 
  /// 使用专门的方法 promoteSubtaskToRoot，直接设置 parentId = null
  /// 与拖拽的 handlePromoteToIndependent 不同，不依赖偏移量检查
  static Future<void> _handlePromoteToIndependent(
    BuildContext context,
    WidgetRef ref,
    Task task, {
    int? taskLevel,
  }) async {
    final taskService = await ref.read(taskServiceProvider.future);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      // 调用滑动专用的提升方法，直接设置 parentId = null
      final success = await taskService.promoteSubtaskToRoot(
        task.id,
        taskLevel: taskLevel, // 传递 taskLevel，避免重复计算
      );
      
      if (!success) {
        // 如果提升失败（可能是任务不是子任务或其他原因）
        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.promoteToIndependentError)),
        );
        return;
      }
      
      if (!context.mounted) return;
      
      // 显示详细的成功反馈
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.promoteToIndependentSuccess),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to promote task to independent: $error\n$stackTrace');
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('${l10n.promoteToIndependentError}: $error')),
      );
    }
  }

  /// 处理恢复动作（从回收站恢复到待办状态）
  static Future<void> _handleRestore(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final taskService = await ref.read(taskServiceProvider.future);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      // 将任务状态从 trashed 改为 pending
      await taskService.updateDetails(
        taskId: task.id,
        payload: const TaskUpdate(status: TaskStatus.pending),
      );
      if (!context.mounted) return;
      
      // 刷新回收站分页数据
      ref.read(trashedTasksPaginationProvider.notifier).loadInitial();
      
      // 显示成功反馈
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.trashRestoreSuccess),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to restore task: $error\n$stackTrace');
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('${l10n.trashRestoreError}: $error')),
      );
    }
  }

  /// 处理永久删除动作（从回收站彻底删除）
  static Future<void> _handlePermanentDelete(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final taskService = await ref.read(taskServiceProvider.future);
    final taskRepository = await ref.read(taskRepositoryProvider.future);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      // 先将任务状态改为 pseudoDeleted
      await taskService.updateDetails(
        taskId: task.id,
        payload: const TaskUpdate(status: TaskStatus.pseudoDeleted),
      );
      
      // 然后物理删除（清理过期的伪删除记录）
      await taskRepository.purgeObsolete(DateTime.now());
      
      if (!context.mounted) return;
      
      // 刷新回收站分页数据
      ref.read(trashedTasksPaginationProvider.notifier).loadInitial();
      
      // 显示成功反馈
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.trashDeleteSuccess),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to permanently delete task: $error\n$stackTrace');
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('${l10n.trashDeleteError}: $error')),
      );
    }
  }
}
