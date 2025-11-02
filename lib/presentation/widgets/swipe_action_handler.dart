import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task.dart';
import '../../core/providers/service_providers.dart';
import '../../generated/l10n/app_localizations.dart';
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
      case SwipeActionType.archive:
        await _handleArchive(context, ref, task);
        break;
      case SwipeActionType.delete:
        await _handleDelete(context, ref, task);
        break;
      case SwipeActionType.promoteToIndependent:
        await _handlePromoteToIndependent(context, ref, task, taskLevel: taskLevel);
        break;
    }
  }

  /// 处理快速规划动作
  static Future<void> _handleQuickPlan(BuildContext context, WidgetRef ref, Task task) async {
    final taskService = ref.read(taskServiceProvider);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      await taskService.planTask(taskId: task.id, dueDateLocal: today, section: TaskSection.today);
      if (!context.mounted) return;
      
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
    final taskService = ref.read(taskServiceProvider);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      final nextDate = _getNextScheduledDate(task.dueAt);
      final section = _sectionForDate(nextDate);
      await taskService.planTask(taskId: task.id, dueDateLocal: nextDate, section: section);
      if (!context.mounted) return;
      
      // 格式化日期显示
      final dateStr = _formatDateForDisplay(nextDate);
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

  /// 处理归档动作
  static Future<void> _handleArchive(BuildContext context, WidgetRef ref, Task task) async {
    final taskService = ref.read(taskServiceProvider);
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
    final taskService = ref.read(taskServiceProvider);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      await taskService.softDelete(task.id);
      if (!context.mounted) return;
      
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

  /// 根据任务当前状态计算下一个合适的推迟日期
  static DateTime _getNextScheduledDate(DateTime? currentDueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final thisWeekSaturday = _getThisWeekSaturday(today);
    final thisMonthEnd = _getEndOfMonth(today);
    
    // 如果没有当前日期，默认为今天
    final dueDate = currentDueDate ?? today;
    final normalizedDueDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    // 获取下一个可用的日期选项
    final nextDates = [tomorrow, thisWeekSaturday, thisMonthEnd];
    
    // 找到第一个比当前日期晚的日期
    for (final nextDate in nextDates) {
      if (nextDate.isAfter(normalizedDueDate)) {
        return nextDate;
      }
    }
    
    // 如果都更早，则推迟到下个月
    return DateTime(today.year, today.month + 1, 1);
  }

  /// 根据日期确定任务分区
  static TaskSection _sectionForDate(DateTime date) {
    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final difference = normalizedDate.difference(normalizedNow).inDays;
    if (difference <= 0) {
      return TaskSection.today;
    }
    if (difference == 1) {
      return TaskSection.tomorrow;
    }
    return TaskSection.later;
  }

  /// 计算本周六的日期
  /// 如果今天是周六，则返回下周六
  static DateTime _getThisWeekSaturday(DateTime now) {
    final daysUntilSaturday = (DateTime.saturday - now.weekday) % 7;
    return now.add(Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday));
  }

  /// 计算本月最后一天的日期
  static DateTime _getEndOfMonth(DateTime now) {
    return DateTime(now.year, now.month + 1, 0);
  }

  /// 格式化日期用于显示
  static String _formatDateForDisplay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    if (normalizedDate == today) {
      return 'today';
    } else if (normalizedDate == tomorrow) {
      return 'tomorrow';
    } else {
      // 使用简单的日期格式
      return '${date.month}/${date.day}';
    }
  }

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
    final taskService = ref.read(taskServiceProvider);
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
}
