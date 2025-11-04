import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:granoflow/main.dart' as app;
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/core/providers/repository_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/presentation/common/drag/standard_draggable.dart';
import 'helpers/task_drag_test_helper.dart';
import 'helpers/task_section_test_helper.dart';
import 'fixtures/task_test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Tasks Drag and Drop - Basic Functionality', () {
    testWidgets(
      'should load app and verify drag components exist',
      (WidgetTester tester) async {
        // 启动应用
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // 验证应用已加载
        expect(find.byType(MaterialApp), findsOneWidget);

        // 获取应用的 ProviderContainer
        final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp).first),
        );
        final helper = TaskDragTestHelper(tester, container);

        // 导航到 Tasks 页面
        await helper.navigateToTasks();

        // 验证 StandardDraggable 组件存在
        expect(helper.verifyDraggableExists(), isTrue,
            reason: 'StandardDraggable 组件应该存在');

        // 验证 TaskDragIntentTarget 组件存在（通过查找插入目标）
        expect(helper.verifyDragTargetExists(), isTrue,
            reason: 'TaskDragIntentTarget 组件应该存在');

        // 验证任务列表存在（通过查找任务标题）
        final tasks = find.textContaining('测试任务');
        expect(tasks, findsWidgets, reason: '应该存在任务列表');
      },
    );

    testWidgets(
      'should verify task cards can be displayed and dragged',
      (WidgetTester tester) async {
        // 启动应用
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // 获取应用的 ProviderContainer
        final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp).first),
        );
        final helper = TaskDragTestHelper(tester, container);
        final sectionHelper = TaskSectionTestHelper(tester, container);

        // 创建测试任务
        final now = DateTime.now();
        final tasks = await sectionHelper.createTasksForSection(
          TaskSection.today,
          3,
          now: now,
        );
        expect(tasks.length, greaterThan(0), reason: '应该创建了测试任务');

        // 导航到 Tasks 页面
        await helper.navigateToTasks();

        // 等待任务显示
        final taskTitle = tasks.first.title;
        final taskFinder = await sectionHelper.waitForTaskInUI(taskTitle);

        // 验证任务卡片存在
        expect(taskFinder, findsOneWidget, reason: '任务卡片应该存在');

        // 验证任务可以拖拽（通过查找 StandardDraggable）
        final draggableFinder = find.ancestor(
          of: taskFinder,
          matching: find.byType(StandardDraggable),
        );
        expect(draggableFinder, findsWidgets,
            reason: '任务应该可以拖拽');
      },
    );

    testWidgets(
      'should show insertion line when hovering over insertion target',
      (WidgetTester tester) async {
        // 启动应用
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // 获取应用的 ProviderContainer
        final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp).first),
        );
        final helper = TaskDragTestHelper(tester, container);
        final sectionHelper = TaskSectionTestHelper(tester, container);

        // 创建测试任务
        final now = DateTime.now();
        final tasks = await sectionHelper.createTasksForSection(
          TaskSection.today,
          3,
          now: now,
        );
        expect(tasks.length, greaterThanOrEqualTo(2),
            reason: '应该至少创建了 2 个测试任务');

        // 导航到 Tasks 页面
        await helper.navigateToTasks();

        // 等待任务显示
        final draggedTaskTitle = tasks.first.title;
        final draggedTaskFinder = helper.findTaskByTitle(draggedTaskTitle);
        await tester.ensureVisible(draggedTaskFinder.first);
        await tester.pumpAndSettle();

        // 获取第二个任务的位置（作为目标位置）
        final targetTaskTitle = tasks[1].title;
        final targetTaskFinder = helper.findTaskByTitle(targetTaskTitle);
        await tester.ensureVisible(targetTaskFinder.first);
        await tester.pumpAndSettle();

        final targetPosition = tester.getCenter(targetTaskFinder.first);

        // 开始拖拽（长按并移动到两个任务之间）
        final gesture = await helper.performLongPressDrag(
          startFinder: draggedTaskFinder,
          endOffset: Offset(
            targetPosition.dx,
            targetPosition.dy - 30, // 移动到两个任务之间
          ),
        );

        expect(gesture, isNotNull, reason: '应该能开始拖拽');

        // 等待一段时间，让插入间隔线显示
        await tester.pump(const Duration(milliseconds: 300));

        // 验证插入间隔线显示（使用 helper 方法）
        expect(helper.verifyInsertionLineVisible(), isTrue,
            reason: '拖拽悬停时应该显示插入间隔线');

        // 验证任务卡片半透明
        expect(helper.verifyTaskOpacity(draggedTaskFinder), isTrue,
            reason: '拖拽时任务应该变为半透明');

        // 释放拖拽
        await gesture!.up();
        await helper.waitForAnimation();
      },
    );

    testWidgets(
      'should show drag feedback (task card becomes semi-transparent)',
      (WidgetTester tester) async {
        // 启动应用
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // 获取应用的 ProviderContainer
        final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp).first),
        );
        final helper = TaskDragTestHelper(tester, container);
        final sectionHelper = TaskSectionTestHelper(tester, container);

        // 创建测试任务
        final now = DateTime.now();
        final tasks = await sectionHelper.createTasksForSection(
          TaskSection.today,
          2,
          now: now,
        );
        expect(tasks.length, greaterThan(0), reason: '应该创建了测试任务');

        // 导航到 Tasks 页面
        await helper.navigateToTasks();

        // 等待任务显示
        final taskTitle = tasks.first.title;
        final taskFinder = helper.findTaskByTitle(taskTitle);
        await tester.ensureVisible(taskFinder.first);
        await tester.pumpAndSettle();

        // 开始拖拽
        final taskPosition = tester.getCenter(taskFinder.first);
        final gesture = await helper.performLongPressDrag(
          startFinder: taskFinder,
          endOffset: Offset(taskPosition.dx, taskPosition.dy + 50),
        );

        expect(gesture, isNotNull, reason: '应该能开始拖拽');

        // 等待拖拽反馈显示
        await tester.pump(const Duration(milliseconds: 300));

        // 验证任务卡片半透明（使用 helper 方法）
        expect(helper.verifyTaskOpacity(taskFinder), isTrue,
            reason: '拖拽时任务应该变为半透明');

        // 释放拖拽
        await gesture!.up();
        await helper.waitForAnimation();
      },
    );

    testWidgets(
      'should verify StandardDraggable uses LongPressDraggable',
      (WidgetTester tester) async {
        // 启动应用
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // 获取应用的 ProviderContainer
        final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp).first),
        );
        final sectionHelper = TaskSectionTestHelper(tester, container);

        // 创建测试任务
        final now = DateTime.now();
        final tasks = await sectionHelper.createTasksForSection(
          TaskSection.today,
          1,
          now: now,
        );

        // 导航到 Tasks 页面
        final helper = TaskDragTestHelper(tester, container);
        await helper.navigateToTasks();

        // 等待任务显示
        final taskTitle = tasks.first.title;
        final taskFinder = await sectionHelper.waitForTaskInUI(taskTitle);

        // 验证 StandardDraggable 存在
        final draggableFinder = find.ancestor(
          of: taskFinder,
          matching: find.byType(StandardDraggable),
        );
        expect(draggableFinder, findsWidgets,
            reason: 'StandardDraggable 应该存在');

        // 验证 LongPressDraggable 存在（StandardDraggable 内部使用）
        final longPressFinder = find.ancestor(
          of: draggableFinder,
          matching: find.byWidgetPredicate(
            (widget) => widget.runtimeType.toString().contains('LongPressDraggable'),
          ),
        );
        expect(longPressFinder, findsWidgets,
            reason: 'LongPressDraggable 应该存在（StandardDraggable 内部使用）');
      },
    );
  });
}

