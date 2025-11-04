import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/core/utils/task_section_utils.dart';

/// 测试数据生成器
///
/// 用于生成测试任务数据，包括不同 title、dueAt、parentId 的任务
class TaskTestData {
  TaskTestData._();

  /// 生成一个测试任务
  static Task generateTask({
    required int id,
    required String title,
    DateTime? dueAt,
    int? parentId,
    double sortIndex = 1000.0,
    TaskStatus status = TaskStatus.pending,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return Task(
      id: id,
      taskId: 'task-$id',
      title: title,
      dueAt: dueAt,
      parentId: parentId,
      sortIndex: sortIndex,
      status: status,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      tags: const [],
    );
  }

  /// 生成指定 section 的测试任务列表
  static List<Task> generateTasksForSection({
    required TaskSection section,
    required int count,
    required DateTime now,
    int startId = 1,
  }) {
    final tasks = <Task>[];
    DateTime? dueAt;

    // 根据 section 计算对应的 dueAt 日期
    switch (section) {
      case TaskSection.overdue:
        // 已逾期：昨天
        dueAt = DateTime(now.year, now.month, now.day - 1, 12, 0, 0);
        break;
      case TaskSection.today:
        // 今日：今天
        dueAt = DateTime(now.year, now.month, now.day, 12, 0, 0);
        break;
      case TaskSection.tomorrow:
        // 明日：明天
        dueAt = DateTime(now.year, now.month, now.day + 1, 12, 0, 0);
        break;
      case TaskSection.thisWeek:
        // 本周：本周某一天（比如明天+2天）
        final tomorrow = DateTime(now.year, now.month, now.day + 1);
        final weekStart = TaskSectionUtils.getSectionEndTime(
          TaskSection.thisWeek,
          now: now,
        );
        final nextWeekStart = DateTime(weekStart.year, weekStart.month, weekStart.day + 1);
        final daysUntilNextWeek = nextWeekStart.difference(tomorrow).inDays;
        final targetDay = tomorrow.add(Duration(days: daysUntilNextWeek ~/ 2));
        dueAt = DateTime(targetDay.year, targetDay.month, targetDay.day, 12, 0, 0);
        break;
      case TaskSection.thisMonth:
        // 本月：本月某一天（比如15号）
        final monthEnd = TaskSectionUtils.getSectionEndTime(
          TaskSection.thisMonth,
          now: now,
        );
        dueAt = DateTime(monthEnd.year, monthEnd.month, 15, 12, 0, 0);
        break;
      case TaskSection.nextMonth:
        // 次月：下个月某一天（比如15号）
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        dueAt = DateTime(nextMonth.year, nextMonth.month, 15, 12, 0, 0);
        break;
      case TaskSection.later:
        // 以后：下下个月第一天
        final nextNextMonth = DateTime(now.year, now.month + 2, 1);
        dueAt = DateTime(nextNextMonth.year, nextNextMonth.month, 15, 12, 0, 0);
        break;
      case TaskSection.completed:
      case TaskSection.archived:
      case TaskSection.trash:
        // 这些 section 不应该出现在拖拽测试中
        dueAt = null;
        break;
    }

    // 生成任务列表
    for (int i = 0; i < count; i++) {
      tasks.add(
        generateTask(
          id: startId + i,
          title: '${section.name} 测试任务 $i',
          dueAt: dueAt,
          sortIndex: 1000.0 + (i * 1000.0),
          status: TaskStatus.pending,
        ),
      );
    }

    return tasks;
  }

  /// 生成任务层级结构（根任务 + 子任务）
  static List<Task> generateTaskHierarchy({
    required int rootTaskId,
    required int childCount,
    required TaskSection section,
    required DateTime now,
  }) {
    final tasks = <Task>[];
    DateTime? dueAt;

    // 根据 section 计算对应的 dueAt 日期
    switch (section) {
      case TaskSection.overdue:
        dueAt = DateTime(now.year, now.month, now.day - 1, 12, 0, 0);
        break;
      case TaskSection.today:
        dueAt = DateTime(now.year, now.month, now.day, 12, 0, 0);
        break;
      case TaskSection.tomorrow:
        dueAt = DateTime(now.year, now.month, now.day + 1, 12, 0, 0);
        break;
      case TaskSection.thisWeek:
        final tomorrow = DateTime(now.year, now.month, now.day + 1);
        final weekStart = TaskSectionUtils.getSectionEndTime(
          TaskSection.thisWeek,
          now: now,
        );
        final nextWeekStart = DateTime(weekStart.year, weekStart.month, weekStart.day + 1);
        final daysUntilNextWeek = nextWeekStart.difference(tomorrow).inDays;
        final targetDay = tomorrow.add(Duration(days: daysUntilNextWeek ~/ 2));
        dueAt = DateTime(targetDay.year, targetDay.month, targetDay.day, 12, 0, 0);
        break;
      case TaskSection.thisMonth:
        final monthEnd = TaskSectionUtils.getSectionEndTime(
          TaskSection.thisMonth,
          now: now,
        );
        dueAt = DateTime(monthEnd.year, monthEnd.month, 15, 12, 0, 0);
        break;
      case TaskSection.nextMonth:
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        dueAt = DateTime(nextMonth.year, nextMonth.month, 15, 12, 0, 0);
        break;
      case TaskSection.later:
        final nextNextMonth = DateTime(now.year, now.month + 2, 1);
        dueAt = DateTime(nextNextMonth.year, nextNextMonth.month, 15, 12, 0, 0);
        break;
      case TaskSection.completed:
      case TaskSection.archived:
      case TaskSection.trash:
        dueAt = null;
        break;
    }

    // 生成根任务
    final rootTask = generateTask(
      id: rootTaskId,
      title: '根任务 $rootTaskId',
      dueAt: dueAt,
      parentId: null,
      sortIndex: 1000.0,
      status: TaskStatus.pending,
    );
    tasks.add(rootTask);

    // 生成子任务
    for (int i = 0; i < childCount; i++) {
      tasks.add(
        generateTask(
          id: rootTaskId + 100 + i,
          title: '子任务 $i',
          dueAt: dueAt,
          parentId: rootTaskId,
          sortIndex: 1000.0 + (i * 1000.0),
          status: TaskStatus.pending,
        ),
      );
    }

    return tasks;
  }

  /// 生成 Inbox 任务（无 dueAt）
  static List<Task> generateInboxTasks({
    required int count,
    int startId = 1,
  }) {
    final tasks = <Task>[];
    for (int i = 0; i < count; i++) {
      tasks.add(
        generateTask(
          id: startId + i,
          title: 'Inbox 测试任务 $i',
          dueAt: null,
          parentId: null,
          sortIndex: 1000.0 + (i * 1000.0),
          status: TaskStatus.inbox,
        ),
      );
    }
    return tasks;
  }
}

