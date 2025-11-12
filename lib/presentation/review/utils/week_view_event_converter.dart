import 'package:flutter/material.dart';
import 'package:flutter_week_view/flutter_week_view.dart';
import '../../../core/utils/calendar_review_utils.dart';
import '../../../data/models/focus_session.dart';
import '../../../data/models/task.dart';

/// 将 Task 和 FocusSession 转换为 FlutterWeekViewEvent 的工具类
class WeekViewEventConverter {
  WeekViewEventConverter._();

  /// 将任务转换为 FlutterWeekViewEvent
  /// 
  /// [task] 任务对象
  /// [context] BuildContext，用于获取主题颜色
  /// 返回 FlutterWeekViewEvent
  static FlutterWeekViewEvent taskToEvent(
    Task task,
    BuildContext context,
  ) {
    // 任务必须有完成时间才能显示
    if (task.endedAt == null) {
      // 如果任务未完成，使用更新时间作为回退
      final start = task.updatedAt;
      final end = start.add(const Duration(hours: 1));
      
      return FlutterWeekViewEvent(
        title: task.title,
        description: task.description ?? '',
        start: start,
        end: end,
      );
    }

    DateTime start;
    DateTime end;

    // 如果任务有 startedAt 且早于 endedAt，跨时间段显示
    if (task.startedAt != null && task.startedAt!.isBefore(task.endedAt!)) {
      start = task.startedAt!;
      end = task.endedAt!;
    } else {
      // 没有 startedAt 或 startedAt 无效，只显示在完成时间的半小时段
      start = task.endedAt!;
      end = start.add(const Duration(hours: 1));
    }

    return FlutterWeekViewEvent(
      title: task.title,
      description: task.description ?? '',
      start: start,
      end: end,
    );
  }

  /// 将焦点会话转换为 FlutterWeekViewEvent
  /// 
  /// [session] 焦点会话对象
  /// [context] BuildContext，用于获取主题颜色
  /// [taskTitle] 可选的任务标题，如果会话关联了任务
  /// 返回 FlutterWeekViewEvent
  static FlutterWeekViewEvent sessionToEvent(
    FocusSession session,
    BuildContext context, {
    String? taskTitle,
  }) {
    // 会话必须有开始和结束时间
    if (session.endedAt == null) {
      // 如果会话未结束，使用当前时间作为结束时间
      final now = DateTime.now();
      final end = now.isAfter(session.startedAt) ? now : session.startedAt.add(const Duration(hours: 1));
      
      return FlutterWeekViewEvent(
        title: taskTitle ?? '专注会话',
        description: '进行中 - ${CalendarReviewUtils.formatFocusMinutes(session.actualMinutes)}',
        start: session.startedAt,
        end: end,
      );
    }

    // 构建描述：显示时长
    final description = CalendarReviewUtils.formatFocusMinutes(session.actualMinutes);
    final title = taskTitle ?? '专注会话';

    return FlutterWeekViewEvent(
      title: title,
      description: description,
      start: session.startedAt,
      end: session.endedAt!,
    );
  }

  /// 将任务列表转换为 FlutterWeekViewEvent 列表
  /// 
  /// [tasks] 任务列表
  /// [context] BuildContext
  /// 返回 FlutterWeekViewEvent 列表
  static List<FlutterWeekViewEvent> tasksToEvents(
    List<Task> tasks,
    BuildContext context,
  ) {
    return tasks
        .where((task) => task.endedAt != null) // 只转换已完成的任务
        .map((task) => taskToEvent(task, context))
        .toList();
  }

  /// 将焦点会话列表转换为 FlutterWeekViewEvent 列表
  /// 
  /// [sessions] 焦点会话列表
  /// [context] BuildContext
  /// [taskTitleResolver] 可选的任务标题解析器，用于根据 taskId 获取任务标题
  /// 返回 FlutterWeekViewEvent 列表
  static List<FlutterWeekViewEvent> sessionsToEvents(
    List<FocusSession> sessions,
    BuildContext context, {
    String? Function(String taskId)? taskTitleResolver,
  }) {
    return sessions
        .map((session) {
          final taskTitle = taskTitleResolver != null && session.taskId.isNotEmpty
              ? taskTitleResolver(session.taskId)
              : null;
          return sessionToEvent(session, context, taskTitle: taskTitle);
        })
        .toList();
  }

  /// 将任务和会话列表合并转换为 FlutterWeekViewEvent 列表
  /// 
  /// [tasks] 任务列表
  /// [sessions] 焦点会话列表
  /// [context] BuildContext
  /// [taskTitleResolver] 可选的任务标题解析器
  /// 返回合并后的 FlutterWeekViewEvent 列表
  static List<FlutterWeekViewEvent> combineToEvents(
    List<Task> tasks,
    List<FocusSession> sessions,
    BuildContext context, {
    String? Function(String taskId)? taskTitleResolver,
  }) {
    final taskEvents = tasksToEvents(tasks, context);
    final sessionEvents = sessionsToEvents(sessions, context, taskTitleResolver: taskTitleResolver);
    
    return [...taskEvents, ...sessionEvents];
  }
}

