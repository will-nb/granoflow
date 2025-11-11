import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/services/calendar_review_service.dart';
import 'package:granoflow/data/models/calendar_review_data.dart';
import 'package:granoflow/data/models/focus_session.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/data/repositories/focus_session_repository.dart';
import 'package:granoflow/data/repositories/task_repository.dart';

import '../../presentation/test_support/fakes.dart';

void main() {
  group('CalendarReviewService', () {
    late StubTaskRepository taskRepository;
    late StubFocusSessionRepository focusSessionRepository;
    late CalendarReviewService service;
    final fixedNow = DateTime(2024, 2, 10, 9, 0, 0);

    setUp(() {
      taskRepository = StubTaskRepository();
      focusSessionRepository = StubFocusSessionRepository();
      service = CalendarReviewService(
        taskRepository: taskRepository,
        focusSessionRepository: focusSessionRepository,
      );
    });

    group('loadDailyData', () {
      test('应该正确聚合每日数据', () async {
        // TODO: 实现测试
      });

      test('应该应用项目筛选', () async {
        // TODO: 实现测试
      });

      test('应该应用标签筛选', () async {
        // TODO: 实现测试
      });

      test('应该只统计根任务', () async {
        // TODO: 实现测试
      });

      test('应该排除指定状态的任务', () async {
        // TODO: 实现测试
      });
    });

    group('loadDayDetail', () {
      test('应该返回指定日期的详细数据', () async {
        // TODO: 实现测试
      });

      test('应该应用筛选条件', () async {
        // TODO: 实现测试
      });
    });
  });
}

// 扩展 StubFocusSessionRepository 以支持新方法
extension on StubFocusSessionRepository {
  Future<Map<DateTime, int>> getFocusMinutesByDateRange({
    required DateTime start,
    required DateTime end,
    List<String>? taskIds,
  }) async {
    // TODO: 实现 stub
    return {};
  }

  Future<List<FocusSession>> listSessionsByDateRange({
    required DateTime start,
    required DateTime end,
    List<String>? taskIds,
  }) async {
    // TODO: 实现 stub
    return [];
  }
}

// 扩展 StubTaskRepository 以支持新方法
extension on StubTaskRepository {
  Future<Map<DateTime, List<Task>>> getCompletedRootTasksByDateRange({
    required DateTime start,
    required DateTime end,
    String? projectId,
    List<String>? tags,
  }) async {
    // TODO: 实现 stub
    return {};
  }
}
