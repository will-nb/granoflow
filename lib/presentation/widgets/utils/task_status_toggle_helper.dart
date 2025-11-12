import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../core/utils/task_section_utils.dart';
import '../../tasks/utils/sort_index_calculator.dart';

/// 任务状态切换工具类
/// 
/// 统一处理任务状态切换逻辑
class TaskStatusToggleHelper {
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
  }) async {
    try {
      final taskService = await ref.read(taskServiceProvider.future);
      final taskRepository = await ref.read(taskRepositoryProvider.future);
      final sortIndexService = await ref.read(sortIndexServiceProvider.future);
      final l10n = AppLocalizations.of(context);
      final messenger = ScaffoldMessenger.of(context);

      // 获取任务的 section（从参数或计算得出）
      final taskSection = section ?? TaskSectionUtils.getSectionForDate(task.dueAt);

      // 如果任务已完成，恢复为 pending 状态
      if (task.status == TaskStatus.completedActive) {
        // 计算新的 sortIndex：移动到未完成任务区域最后面
        double? newSortIndex;
        try {
          // 查询同一区域的所有任务
          // 注意：listSectionTasks 在 today section 不包含 completedActive，需要手动查询
          List<Task> sectionTasks;
          if (taskSection == TaskSection.today) {
            // 对于 today section，需要查询所有状态的任务（包括 completedActive）
            // 先查询未完成任务
            final uncompleted = await taskRepository.listSectionTasks(taskSection);
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
            sectionTasks = [...uncompleted, ...todayCompleted];
          } else {
            sectionTasks = await taskRepository.listSectionTasks(taskSection);
          }
          
          // 筛选出未完成任务（status != completedActive）
          final uncompletedTasks = sectionTasks
              .where((t) => t.status != TaskStatus.completedActive && t.id != task.id)
              .toList();
          
          if (uncompletedTasks.isNotEmpty) {
            // 找到最大 sortIndex
            final maxUncompletedSortIndex = uncompletedTasks
                .map((t) => t.sortIndex)
                .reduce((a, b) => a > b ? a : b);
            
            // 使用 SortIndexCalculator.insertAtLast 计算新 sortIndex
            newSortIndex = SortIndexCalculator.insertAtLast(maxUncompletedSortIndex);
            
            // 检查间隙是否足够
            if ((newSortIndex - maxUncompletedSortIndex).abs() < 2.0) {
              // 间隙不足，先规范化未完成任务区域
              await sortIndexService.normalizeSection(section: taskSection);
              // 重新查询并计算
              final updatedTasks = await taskRepository.listSectionTasks(taskSection);
              final updatedUncompleted = updatedTasks
                  .where((t) => t.status != TaskStatus.completedActive && t.id != task.id)
                  .toList();
              if (updatedUncompleted.isNotEmpty) {
                final updatedMax = updatedUncompleted
                    .map((t) => t.sortIndex)
                    .reduce((a, b) => a > b ? a : b);
                newSortIndex = SortIndexCalculator.insertAtLast(updatedMax);
              } else {
                newSortIndex = SortIndexCalculator.insertAtLast(null);
              }
            }
          } else {
            // 不存在未完成任务，使用默认值
            newSortIndex = SortIndexCalculator.insertAtLast(null);
          }
        } catch (e) {
          debugPrint('Failed to calculate sortIndex for uncompleted: $e');
          // 如果计算失败，使用默认值
          newSortIndex = 1000.0;
        }

        // 更新状态和 sortIndex
        await taskService.updateDetails(
          taskId: task.id,
          payload: TaskUpdate(
            status: TaskStatus.pending,
            sortIndex: newSortIndex,
          ),
        );
        if (context.mounted) {
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
        // 计算新的 sortIndex：移动到已完成任务区域最前面
        double? newSortIndex;
        try {
          // 查询同一区域的所有任务
          // 注意：listSectionTasks 在 today section 不包含 completedActive，需要手动查询
          List<Task> sectionTasks;
          if (taskSection == TaskSection.today) {
            // 对于 today section，需要查询所有状态的任务（包括 completedActive）
            // 先查询未完成任务
            final uncompleted = await taskRepository.listSectionTasks(taskSection);
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
            sectionTasks = [...uncompleted, ...todayCompleted];
          } else {
            sectionTasks = await taskRepository.listSectionTasks(taskSection);
          }
          
          // 筛选出已完成任务（status == completedActive）
          final completedTasks = sectionTasks
              .where((t) => t.status == TaskStatus.completedActive && t.id != task.id)
              .toList();
          
          if (completedTasks.isNotEmpty) {
            // 找到最小 sortIndex
            final minCompletedSortIndex = completedTasks
                .map((t) => t.sortIndex)
                .reduce((a, b) => a < b ? a : b);
            
            // 使用 SortIndexCalculator.insertAtFirst 计算新 sortIndex
            newSortIndex = SortIndexCalculator.insertAtFirst(minCompletedSortIndex);
            
            // 检查间隙是否足够
            if ((minCompletedSortIndex - newSortIndex).abs() < 2.0) {
              // 间隙不足，先规范化已完成任务区域
              // 注意：这里需要规范化已完成任务，但 normalizeSection 会规范化整个区域
              // 为了只规范化已完成任务，我们需要先筛选已完成任务，然后规范化
              // 但 normalizeSection 不支持按状态筛选，所以这里先规范化整个区域
              await sortIndexService.normalizeSection(section: taskSection);
              // 重新查询并计算
              final updatedTasks = await taskRepository.listSectionTasks(taskSection);
              final updatedCompleted = updatedTasks
                  .where((t) => t.status == TaskStatus.completedActive && t.id != task.id)
                  .toList();
              if (updatedCompleted.isNotEmpty) {
                final updatedMin = updatedCompleted
                    .map((t) => t.sortIndex)
                    .reduce((a, b) => a < b ? a : b);
                newSortIndex = SortIndexCalculator.insertAtFirst(updatedMin);
              } else {
                newSortIndex = SortIndexCalculator.insertAtFirst(null);
              }
            }
          } else {
            // 不存在已完成任务，使用默认值
            newSortIndex = SortIndexCalculator.insertAtFirst(null);
          }
        } catch (e) {
          debugPrint('Failed to calculate sortIndex for completed: $e');
          // 如果计算失败，使用默认值
          newSortIndex = -1000.0;
        }

        // 先调用 markCompleted 更新状态（不支持 sortIndex）
        await taskService.markCompleted(taskId: task.id);
        
        // 立即调用 updateDetails 更新 sortIndex（两步更新）
        await taskService.updateDetails(
          taskId: task.id,
          payload: TaskUpdate(sortIndex: newSortIndex),
        );
        
        if (context.mounted) {
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
}

