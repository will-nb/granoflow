import 'package:flutter/foundation.dart';
import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';
import 'sort_index_service_sorting.dart';

/// SortIndexService 批量重排方法
/// 
/// 包含各种批量重排 sortIndex 的方法
class SortIndexServiceReorder {
  SortIndexServiceReorder({
    required TaskRepository taskRepository,
  }) : _tasks = taskRepository;

  final TaskRepository _tasks;

  // 默认参数
  static const double _step = 1024.0;

  /// 直接按域内的有序ID进行重排（标准化）
  ///
  /// [orderedIds] 已排序的任务ID列表
  Future<void> reorderIds({
    required List<String> orderedIds,
    String? domainKey,
    double start = 1024,
    double step = _step,
  }) async {
    if (orderedIds.isEmpty) return;
    final updates = <String, TaskUpdate>{};
    for (var i = 0; i < orderedIds.length; i++) {
      updates[orderedIds[i]] =
          TaskUpdate(sortIndex: (start + i * step).toDouble());
    }
    await _tasks.batchUpdate(updates);
  }

  /// 按任务列表排序并重排（Inbox页面）
  ///
  /// 接收任务列表，使用统一的排序规则排序后，批量更新 sortIndex
  Future<void> reorderTasksForInbox({
    required List<Task> tasks,
    double start = 1024,
    double step = _step,
  }) async {
    if (tasks.isEmpty) return;
    final sorted = List<Task>.from(tasks);
    SortIndexServiceSorting.sortTasksForInbox(sorted);
    final updates = <String, TaskUpdate>{};
    for (var i = 0; i < sorted.length; i++) {
      updates[sorted[i].id] =
          TaskUpdate(sortIndex: (start + i * step).toDouble());
    }
    await _tasks.batchUpdate(updates);
  }

  /// 按任务列表排序并重排（Tasks页面）
  ///
  /// 接收任务列表，使用统一的排序规则排序后，批量更新 sortIndex
  Future<void> reorderTasksForTasksPage({
    required List<Task> tasks,
    double start = 1024,
    double step = _step,
  }) async {
    if (tasks.isEmpty) return;
    final sorted = List<Task>.from(tasks);
    SortIndexServiceSorting.sortTasksForTasksPage(sorted);
    final updates = <String, TaskUpdate>{};
    for (var i = 0; i < sorted.length; i++) {
      updates[sorted[i].id] =
          TaskUpdate(sortIndex: (start + i * step).toDouble());
    }
    await _tasks.batchUpdate(updates);
  }

  /// 批量重排子任务的sortIndex
  ///
  /// 接收子任务列表，使用统一的排序规则排序后，批量更新 sortIndex
  /// 用于父任务内的子任务重排序
  ///
  /// [children] 子任务列表
  /// [start] 起始 sortIndex 值
  /// [step] sortIndex 间隔
  Future<void> reorderChildrenTasks({
    required List<Task> children,
    double start = 1024,
    double step = _step,
  }) async {
    if (children.isEmpty) return;
    final sorted = List<Task>.from(children);
    SortIndexServiceSorting.sortChildrenTasks(sorted);
    final updates = <String, TaskUpdate>{};
    for (var i = 0; i < sorted.length; i++) {
      updates[sorted[i].id] =
          TaskUpdate(sortIndex: (start + i * step).toDouble());
    }
    await _tasks.batchUpdate(updates);
  }

  /// 按日期分组批量重排同一天的任务（Tasks页面）
  ///
  /// 从任务列表中筛选出与目标日期同一天的任务，按统一排序规则排序后批量更新 sortIndex
  /// 用于Tasks页面中，当任务移动后，只重排同一天内的任务
  ///
  /// [allTasks] 所有任务列表（用于筛选）
  /// [targetDate] 目标日期（只比较日期部分，忽略时分秒）
  /// [start] 起始 sortIndex 值
  /// [step] sortIndex 间隔
  Future<void> reorderTasksForSameDate({
    required List<Task> allTasks,
    required DateTime? targetDate,
    double start = 1024,
    double step = _step,
  }) async {
    debugPrint('[SortIndexServiceReorder] reorderTasksForSameDate called: allTasksCount=${allTasks.length}, targetDate=$targetDate');
    
    if (targetDate == null) {
      debugPrint('[SortIndexServiceReorder] reorderTasksForSameDate: targetDate is null, handling tasks without date');
      final tasksWithoutDate =
          allTasks.where((task) => task.dueAt == null).toList();
      debugPrint('[SortIndexServiceReorder] reorderTasksForSameDate: found ${tasksWithoutDate.length} tasks without date');
      if (tasksWithoutDate.isEmpty) {
        debugPrint('[SortIndexServiceReorder] reorderTasksForSameDate: no tasks without date, returning');
        return;
      }

      final sorted = List<Task>.from(tasksWithoutDate);
      SortIndexServiceSorting.sortTasksForTasksPage(sorted);
      final updates = <String, TaskUpdate>{};
      for (var i = 0; i < sorted.length; i++) {
        updates[sorted[i].id] =
            TaskUpdate(sortIndex: (start + i * step).toDouble());
      }
      debugPrint('[SortIndexServiceReorder] reorderTasksForSameDate: batch updating ${updates.length} tasks without date');
      await _tasks.batchUpdate(updates);
      debugPrint('[SortIndexServiceReorder] reorderTasksForSameDate: batch update completed for tasks without date');
      return;
    }

    final targetDayOnly =
        DateTime(targetDate.year, targetDate.month, targetDate.day);
    debugPrint('[SortIndexServiceReorder] reorderTasksForSameDate: targetDayOnly=$targetDayOnly');

    final sameDateTasks = allTasks.where((task) {
      if (task.dueAt == null) return false;
      final taskDayOnly =
          DateTime(task.dueAt!.year, task.dueAt!.month, task.dueAt!.day);
      return taskDayOnly == targetDayOnly;
    }).toList();

    debugPrint('[SortIndexServiceReorder] reorderTasksForSameDate: found ${sameDateTasks.length} tasks with same date');
    if (sameDateTasks.isEmpty) {
      debugPrint('[SortIndexServiceReorder] reorderTasksForSameDate: no tasks with same date, returning');
      return;
    }

    final sorted = List<Task>.from(sameDateTasks);
    SortIndexServiceSorting.sortTasksForTasksPage(sorted);
    debugPrint('[SortIndexServiceReorder] reorderTasksForSameDate: sorted ${sorted.length} tasks');

    final updates = <String, TaskUpdate>{};
    for (var i = 0; i < sorted.length; i++) {
      updates[sorted[i].id] =
          TaskUpdate(sortIndex: (start + i * step).toDouble());
    }
    debugPrint('[SortIndexServiceReorder] reorderTasksForSameDate: batch updating ${updates.length} tasks');
    await _tasks.batchUpdate(updates);
    debugPrint('[SortIndexServiceReorder] reorderTasksForSameDate: batch update completed');
  }

  /// 按里程碑分组批量重排同一里程碑的任务
  ///
  /// 从任务列表中筛选出属于指定里程碑的任务，按统一排序规则排序后批量更新 sortIndex
  /// 用于项目详情页中，当任务移动后，只重排同一里程碑内的任务
  ///
  /// [allTasks] 所有任务列表（用于筛选）
  /// [targetMilestoneId] 目标里程碑ID
  /// [start] 起始 sortIndex 值
  /// [step] sortIndex 间隔
  Future<void> reorderTasksForSameMilestone({
    required List<Task> allTasks,
    required String targetMilestoneId,
    double start = 1024,
    double step = _step,
  }) async {
    debugPrint('[SortIndexServiceReorder] reorderTasksForSameMilestone called: allTasksCount=${allTasks.length}, targetMilestoneId=$targetMilestoneId');

    final sameMilestoneTasks = allTasks.where((task) {
      return task.milestoneId == targetMilestoneId;
    }).toList();

    debugPrint('[SortIndexServiceReorder] reorderTasksForSameMilestone: found ${sameMilestoneTasks.length} tasks with same milestone');
    if (sameMilestoneTasks.isEmpty) {
      debugPrint('[SortIndexServiceReorder] reorderTasksForSameMilestone: no tasks with same milestone, returning');
      return;
    }

    final sorted = List<Task>.from(sameMilestoneTasks);
    SortIndexServiceSorting.sortTasksForTasksPage(sorted);
    debugPrint('[SortIndexServiceReorder] reorderTasksForSameMilestone: sorted ${sorted.length} tasks');

    final updates = <String, TaskUpdate>{};
    for (var i = 0; i < sorted.length; i++) {
      updates[sorted[i].id] =
          TaskUpdate(sortIndex: (start + i * step).toDouble());
    }
    debugPrint('[SortIndexServiceReorder] reorderTasksForSameMilestone: batch updating ${updates.length} tasks');
    await _tasks.batchUpdate(updates);
    debugPrint('[SortIndexServiceReorder] reorderTasksForSameMilestone: batch update completed');
  }
}

