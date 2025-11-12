import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/services/calendar_review_service.dart';

import '../../presentation/test_support/fakes.dart';

void main() {
  group('CalendarReviewService', () {
    late StubTaskRepository taskRepository;
    late StubFocusSessionRepository focusSessionRepository;

    setUp(() {
      taskRepository = StubTaskRepository();
      focusSessionRepository = StubFocusSessionRepository();
      // service 将在测试实现时使用
      // ignore: unused_local_variable
      final service = CalendarReviewService(
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
