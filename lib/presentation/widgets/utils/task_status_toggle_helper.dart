import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/models/task.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../core/utils/task_section_utils.dart';

/// 任务状态切换工具类
/// 
/// 统一处理任务状态切换逻辑
class TaskStatusToggleHelper {
  /// 重新分配 section 内所有任务的 sortIndex
  /// 
  /// 将所有 completedActive 的任务分配靠前的 sortIndex（从 -1000 开始）
  /// 将所有其他 status 的任务分配靠后的 sortIndex（从 1000 开始）
  /// 在每个组内，保持原有的相对顺序
  static Future<void> _reassignSortIndexesForSection(
    TaskRepository taskRepository,
    TaskSection section,
  ) async {
    // 获取 section 内所有任务
    List<Task> sectionTasks;
    if (section == TaskSection.today) {
      // 对于 today section，需要查询所有状态的任务（包括 completedActive）
      // 先查询未完成任务
      final uncompleted = await taskRepository.listSectionTasks(section);
      // 再查询已完成任务（使用 completed section 的查询逻辑，但按 dueAt 筛选）
      final completed = await taskRepository.listSectionTasks(TaskSection.completed);
      // 筛选出今日的已完成任务
      final now = DateTime.now();
      final todayStart = TaskSectionUtils.getSectionStartTime(TaskSection.today, now: now);
      final todayEnd = TaskSectionUtils.getSectionEndTimeForQuery(TaskSection.today, now: now);
      final todayCompleted = completed.where((t) {
        if (t.dueAt == null) return false;
        final dueDate = DateTime(t.dueAt!.year, t.dueAt!.month, t.dueAt!.day);
        final startDate = DateTime(todayStart.year, todayStart.month, todayStart.day);
        final endDate = DateTime(todayEnd.year, todayEnd.month, todayEnd.day);
        return (dueDate.isAtSameMomentAs(startDate) || dueDate.isAfter(startDate)) &&
            dueDate.isBefore(endDate);
      }).toList();
      // 合并任务，避免重复（使用 Set 来去重）
      final taskIds = <String>{};
      sectionTasks = <Task>[];
      for (final task in uncompleted) {
        if (taskIds.add(task.id)) {
          sectionTasks.add(task);
        }
      }
      for (final task in todayCompleted) {
        if (taskIds.add(task.id)) {
          sectionTasks.add(task);
        }
      }
    } else {
      sectionTasks = await taskRepository.listSectionTasks(section);
    }

    if (sectionTasks.isEmpty) return;

    // 按 status 分组
    final completedTasks = sectionTasks
        .where((t) => t.status == TaskStatus.completedActive)
        .toList();
    final otherTasks = sectionTasks
        .where((t) => t.status != TaskStatus.completedActive)
        .toList();

    // 调试日志
    debugPrint(
      '[TaskStatusToggleHelper] Reassigning sortIndexes for section: $section, '
      'total tasks: ${sectionTasks.length}, '
      'completed: ${completedTasks.length}, '
      'other: ${otherTasks.length}',
    );

    // 在每个组内按当前 sortIndex 排序（保持原有顺序）
    completedTasks.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    otherTasks.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

    // 重新分配 sortIndex
    // 确保已完成任务的 sortIndex 都小于未完成任务的 sortIndex
    // 使用负数范围给已完成任务，正数范围给未完成任务
    const double step = 1000.0;
    // 从 -100000 开始，给已完成任务足够的空间
    const double completedStart = -100000.0;
    // 从 0 开始，给未完成任务
    const double otherStart = 0.0;

    final updates = <String, TaskUpdate>{};

    // completedActive 组：从 -100000 开始
    for (var i = 0; i < completedTasks.length; i++) {
      final newSortIndex = completedStart + i * step;
      updates[completedTasks[i].id] = TaskUpdate(
        sortIndex: newSortIndex,
      );
      debugPrint(
        '[TaskStatusToggleHelper] Completed task ${completedTasks[i].id}: '
        'old sortIndex=${completedTasks[i].sortIndex}, new sortIndex=$newSortIndex',
      );
    }

    // 其他组：从 0 开始
    for (var i = 0; i < otherTasks.length; i++) {
      final newSortIndex = otherStart + i * step;
      updates[otherTasks[i].id] = TaskUpdate(
        sortIndex: newSortIndex,
      );
      debugPrint(
        '[TaskStatusToggleHelper] Other task ${otherTasks[i].id}: '
        'old sortIndex=${otherTasks[i].sortIndex}, new sortIndex=$newSortIndex',
      );
    }

    // 批量更新
    if (updates.isNotEmpty) {
      debugPrint(
        '[TaskStatusToggleHelper] Batch updating ${updates.length} tasks with new sortIndexes',
      );
      await taskRepository.batchUpdate(updates);
      debugPrint('[TaskStatusToggleHelper] Batch update completed');
    } else {
      debugPrint('[TaskStatusToggleHelper] No updates needed');
    }
  }
  /// 切换任务的完成/未完成状态
  /// 
  /// [context] BuildContext
  /// [ref] WidgetRef
  /// [task] 要切换状态的任务
  /// [section] 任务所属区域（可选，如果为 null 则根据 task.dueAt 计算）
  /// 
  /// 返回 true 表示切换成功，false 表示失败
  static Future<bool> toggleTaskStatus(
    BuildContext context,
    WidgetRef ref,
    Task task, {
    TaskSection? section,
  }) {
    return _toggleTaskStatusInternal(
      context,
      // ignore: unnecessary_cast
      ref as Ref<Object?>,
      task,
      section: section,
    );
  }

  /// 提供给非 Widget 场景（如系统托盘）的入口
  static Future<bool> toggleTaskStatusWithRef(
    BuildContext context,
    Ref ref,
    Task task, {
    TaskSection? section,
  }) {
    return _toggleTaskStatusInternal(
      context,
      // ignore: unnecessary_cast
      ref as Ref<Object?>,
      task,
      section: section,
    );
  }

  static Future<bool> _toggleTaskStatusInternal(
    BuildContext context,
    Ref<Object?> ref,
    Task task, {
    TaskSection? section,
  }) async {
    try {
      final taskService = await ref.read(taskServiceProvider.future);
      final taskRepository = await ref.read(taskRepositoryProvider.future);
      final l10n = AppLocalizations.of(context);
      final messenger = ScaffoldMessenger.of(context);

      // 获取任务的 section（从参数或计算得出）
      final taskSection = section ?? TaskSectionUtils.getSectionForDate(task.dueAt);

      // 如果任务已完成，恢复为 pending 状态
      if (task.status == TaskStatus.completedActive) {
        // 先更新状态
        await taskService.updateDetails(
          taskId: task.id,
          payload: TaskUpdate(status: TaskStatus.pending),
        );

        // 重新分配整个 section 的 sortIndex
        await _reassignSortIndexesForSection(taskRepository, taskSection);

        if (context.mounted) {
          // 手动刷新相关 provider，确保 UI 立即更新
          ref.invalidate(taskSectionsProvider(taskSection));
          
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.taskListTaskUncompletedToast),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return true;
      }
      // 如果任务未完成，标记为已完成
      else if (task.status == TaskStatus.inbox ||
          task.status == TaskStatus.pending ||
          task.status == TaskStatus.doing ||
          task.status == TaskStatus.paused) {
        // 先更新状态
        await taskService.markCompleted(taskId: task.id);

        // 重新分配整个 section 的 sortIndex
        await _reassignSortIndexesForSection(taskRepository, taskSection);
        
        if (context.mounted) {
          // 手动刷新相关 provider，确保 UI 立即更新
          ref.invalidate(taskSectionsProvider(taskSection));
          
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.taskListTaskCompletedToast),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return true;
      }
      // 其他状态（archived、trashed）不支持切换
      return false;
    } catch (error, stackTrace) {
      debugPrint('Failed to toggle task status: $error\n$stackTrace');
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text('${l10n.taskListTaskCompletedError}: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return false;
    }
  }

  /// 切换任务的三态状态（pending → completedActive → trashed → pending）
  /// 
  /// [context] BuildContext
  /// [ref] WidgetRef
  /// [task] 要切换状态的任务
  /// [section] 任务所属区域（可选，如果为 null 则根据 task.dueAt 计算）
  /// 
  /// 返回 true 表示切换成功，false 表示失败
  /// 
  /// 状态切换顺序：
  /// - pending/doing/paused/inbox → completedActive（调用 taskService.markCompleted()）
  /// - completedActive → trashed（调用 taskService.softDelete()）
  /// - trashed → pending（调用 taskService.updateDetails(status: TaskStatus.pending)）
  static Future<bool> toggleTaskStatusThreeState(
    BuildContext context,
    WidgetRef ref,
    Task task, {
    TaskSection? section,
  }) {
    return _toggleTaskStatusThreeStateInternal(
      context,
      // ignore: unnecessary_cast
      ref as Ref<Object?>,
      task,
      section: section,
    );
  }

  /// 提供给非 Widget 场景的入口
  static Future<bool> toggleTaskStatusThreeStateWithRef(
    BuildContext context,
    Ref ref,
    Task task, {
    TaskSection? section,
  }) {
    return _toggleTaskStatusThreeStateInternal(
      context,
      // ignore: unnecessary_cast
      ref as Ref<Object?>,
      task,
      section: section,
    );
  }

  static Future<bool> _toggleTaskStatusThreeStateInternal(
    BuildContext context,
    Ref<Object?> ref,
    Task task, {
    TaskSection? section,
  }) async {
    try {
      final taskService = await ref.read(taskServiceProvider.future);
      final taskRepository = await ref.read(taskRepositoryProvider.future);

      // 获取任务的 section（从参数或计算得出）
      final taskSection = section ?? TaskSectionUtils.getSectionForDate(task.dueAt);

      // 根据当前状态切换到下一个状态
      if (task.status == TaskStatus.inbox ||
          task.status == TaskStatus.pending ||
          task.status == TaskStatus.doing ||
          task.status == TaskStatus.paused) {
        // 活跃状态 → 已完成
        await taskService.markCompleted(taskId: task.id);

        // 重新分配整个 section 的 sortIndex
        await _reassignSortIndexesForSection(taskRepository, taskSection);

        if (context.mounted) {
          // 手动刷新相关 provider，确保 UI 立即更新
          ref.invalidate(taskSectionsProvider(taskSection));
        }
        return true;
      } else if (task.status == TaskStatus.completedActive) {
        // 已完成 → 已删除（移到回收站）
        await taskService.softDelete(task.id);

        if (context.mounted) {
          // 手动刷新相关 provider，确保 UI 立即更新
          ref.invalidate(taskSectionsProvider(taskSection));
        }
        return true;
      } else if (task.status == TaskStatus.trashed) {
        // 已删除 → 待办（恢复到 pending）
        await taskService.updateDetails(
          taskId: task.id,
          payload: const TaskUpdate(status: TaskStatus.pending),
        );

        // 重新分配整个 section 的 sortIndex
        await _reassignSortIndexesForSection(taskRepository, taskSection);

        if (context.mounted) {
          // 手动刷新相关 provider，确保 UI 立即更新
          ref.invalidate(taskSectionsProvider(taskSection));
        }
        return true;
      }
      // 其他状态（archived、pseudoDeleted）不支持切换
      return false;
    } catch (error, stackTrace) {
      debugPrint('Failed to toggle task status three state: $error\n$stackTrace');
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text('${l10n.taskListTaskCompletedError}: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return false;
    }
  }
}

