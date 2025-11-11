import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/core/providers/repository_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/utils/task_section_utils.dart';
import '../fixtures/task_test_data.dart';

/// 任务区域测试辅助工具类
///
/// 用于：
/// - 为每个 section 创建测试任务
/// - 验证任务在指定 section 中
/// - 查找 section panel
/// - 获取 section 内的任务列表
class TaskSectionTestHelper {
  final WidgetTester tester;
  final ProviderContainer container;

  TaskSectionTestHelper(this.tester, this.container);

  /// 为指定 section 创建测试任务
  Future<List<Task>> createTasksForSection(
    TaskSection section,
    int count, {
    DateTime? now,
  }) async {
    final nowTime = now ?? DateTime.now();
    final taskService = await container.read(taskServiceProvider.future);
    final taskRepository = await container.read(taskRepositoryProvider.future);
    final tasks = <Task>[];

    // 生成测试任务数据
    final testTasks = TaskTestData.generateTasksForSection(
      section: section,
      count: count,
      now: nowTime,
    );

    // 创建任务并移动到指定 section
    for (final testTask in testTasks) {
      // 先创建到 Inbox
      final task = await taskService.captureInboxTask(
        title: testTask.title,
      );

      // 如果 section 需要 dueAt，则移动到指定 section
      if (testTask.dueAt != null) {
        await taskService.planTask(
          taskId: task.id,
          dueDateLocal: testTask.dueAt!,
          section: section,
        );
      }

      // 获取更新后的任务
      final updatedTask = await taskRepository.findById(task.id);
      if (updatedTask != null) {
        tasks.add(updatedTask);
      }
    }

    // 等待任务创建完成
    await Future.delayed(const Duration(milliseconds: 500));

    return tasks;
  }

  /// 验证任务在指定 section 中
  Future<bool> verifyTaskInSection(
    String taskId,
    TaskSection expectedSection,
  ) async {
    final taskRepository = await container.read(taskRepositoryProvider.future);
    final task = await taskRepository.findById(taskId);
    if (task == null) return false;

    final actualSection = TaskSectionUtils.getSectionForDate(task.dueAt);
    return actualSection == expectedSection;
  }

  /// 获取 section 内的任务列表
  Future<List<Task>> getSectionTasks(TaskSection section) async {
    final taskRepository = await container.read(taskRepositoryProvider.future);
    return await taskRepository.listSectionTasks(section);
  }

  /// 查找包含指定文本的 section panel
  Finder findSectionPanelContaining(String text) {
    // 通过任务标题查找任务
    final taskFinder = find.text(text);
    if (taskFinder.evaluate().isEmpty) {
      return find.byWidgetPredicate((widget) => false); // 返回一个空的 Finder
    }

    // 向上查找包含该任务的 Card 或 Container（section panel）
    // 这需要根据实际的 Widget 结构来调整
    return find.ancestor(
      of: taskFinder,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Card ||
            (widget is Container && widget.decoration != null),
      ),
    );
  }

  /// 等待任务在 UI 中显示
  Future<Finder> waitForTaskInUI(
    String taskTitle, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final finder = find.text(taskTitle);
    final startTime = DateTime.now();

    while (finder.evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 100));
      if (DateTime.now().difference(startTime) > timeout) {
        throw TimeoutException(
          'Task "$taskTitle" not found in UI after ${timeout.inSeconds} seconds',
        );
      }
    }

    return finder;
  }

  /// 滚动到指定的 section
  Future<void> scrollToSection(String sectionName) async {
    final sectionFinder = find.textContaining(sectionName);
    if (sectionFinder.evaluate().isNotEmpty) {
      await tester.dragUntilVisible(
        sectionFinder.first,
        find.byType(Scrollable),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
    }
  }

  /// 验证 section 中有任务
  Future<bool> verifySectionHasTasks(
    TaskSection section,
    int minCount,
  ) async {
    final tasks = await getSectionTasks(section);
    return tasks.length >= minCount;
  }
}

/// 超时异常
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => 'TimeoutException: $message';
}

