import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:granoflow/main.dart' as app;
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/core/providers/repository_providers.dart';
import 'package:granoflow/core/utils/task_section_utils.dart';
import 'helpers/task_drag_test_helper.dart';
import 'helpers/task_section_test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Tasks Cross-Section Drag and Drop', () {
    testWidgets(
      'should drag task from overdue to today',
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
        final overdueTasks = await sectionHelper.createTasksForSection(
          TaskSection.overdue,
          5,
          now: now,
        );
        final todayTasks = await sectionHelper.createTasksForSection(
          TaskSection.today,
          5,
          now: now,
        );
        expect(overdueTasks.length, greaterThan(0),
            reason: 'Overdue 区域应该有任务');
        expect(todayTasks.length, greaterThan(0),
            reason: 'Today 区域应该有任务');

        // 导航到 Tasks 页面
        await helper.navigateToTasks();

        // 获取要拖拽的任务
        final draggedTaskTitle = overdueTasks.first.title;
        final draggedTaskFinder = helper.findTaskByTitle(draggedTaskTitle);
        await tester.ensureVisible(draggedTaskFinder.first);
        await tester.pumpAndSettle();

        // 查找 today 区域的 panel（通过查找 today 区域的任务）
        final todayTaskTitle = todayTasks.first.title;
        final todayTaskFinder = helper.findTaskByTitle(todayTaskTitle);
        await tester.ensureVisible(todayTaskFinder.first);
        await tester.pumpAndSettle();

        final todayTaskPosition = tester.getCenter(todayTaskFinder.first);

        // 执行拖拽（使用 performLongPressDrag）
        final gesture = await helper.performLongPressDrag(
          startFinder: draggedTaskFinder,
          endOffset: todayTaskPosition,
        );

        expect(gesture, isNotNull, reason: '应该能开始拖拽');

        // 等待插入线显示
        await tester.pump(const Duration(milliseconds: 300));

        // 验证插入线显示（跨区域拖拽时）
        expect(helper.verifyInsertionLineVisible(), isTrue,
            reason: '跨区域拖拽时应该显示插入间隔线');

        // 释放拖拽
        await gesture!.up();
        await helper.waitForAnimation();

        // 等待任务数据更新（已在 waitForAnimation 中等待）

        // 验证任务已移动到 today 区域（数据库）
        final taskRepository = container.read(taskRepositoryProvider);
        final movedTask = await taskRepository.findById(overdueTasks.first.id);
        expect(movedTask, isNotNull, reason: '任务应该存在');

        final actualSection = TaskSectionUtils.getSectionForDate(movedTask!.dueAt);
        expect(actualSection, TaskSection.today,
            reason: '任务应该在 Today 区域');

        // 验证任务在 UI 中显示在 today 区域
        final movedTaskFinder = helper.findTaskByTitle(draggedTaskTitle);
        expect(movedTaskFinder, findsOneWidget,
            reason: '任务应该在 UI 中显示');
      },
    );

    testWidgets(
      'should drag task from today to tomorrow',
      (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp).first),
        );
        final helper = TaskDragTestHelper(tester, container);
        final sectionHelper = TaskSectionTestHelper(tester, container);

        final now = DateTime.now();
        final todayTasks = await sectionHelper.createTasksForSection(
          TaskSection.today,
          5,
          now: now,
        );
        final tomorrowTasks = await sectionHelper.createTasksForSection(
          TaskSection.tomorrow,
          5,
          now: now,
        );
        expect(todayTasks.length, greaterThan(0),
            reason: 'Today 区域应该有任务');

        await helper.navigateToTasks();

        final draggedTaskTitle = todayTasks.first.title;
        final draggedTaskFinder = helper.findTaskByTitle(draggedTaskTitle);
        await tester.ensureVisible(draggedTaskFinder.first);
        await tester.pumpAndSettle();

        final tomorrowTaskTitle = tomorrowTasks.first.title;
        final tomorrowTaskFinder = helper.findTaskByTitle(tomorrowTaskTitle);
        await tester.ensureVisible(tomorrowTaskFinder.first);
        await tester.pumpAndSettle();

        final tomorrowTaskPosition = tester.getCenter(tomorrowTaskFinder.first);

        // 执行拖拽
        final gesture = await helper.performLongPressDrag(
          startFinder: draggedTaskFinder,
          endOffset: tomorrowTaskPosition,
        );

        expect(gesture, isNotNull, reason: '应该能开始拖拽');

        // 等待插入线显示
        await tester.pump(const Duration(milliseconds: 300));

        // 验证插入线显示
        expect(helper.verifyInsertionLineVisible(), isTrue,
            reason: '跨区域拖拽时应该显示插入间隔线');

        // 释放拖拽
        await gesture!.up();
        await helper.waitForAnimation();

        // 验证任务已移动到目标区域（数据库）
        final taskRepository = container.read(taskRepositoryProvider);
        final movedTask = await taskRepository.findById(todayTasks.first.id);
        expect(movedTask, isNotNull, reason: '任务应该存在');

        final actualSection = TaskSectionUtils.getSectionForDate(movedTask!.dueAt);
        expect(actualSection, TaskSection.tomorrow,
            reason: '任务应该在 Tomorrow 区域');
      },
    );

    testWidgets(
      'should drag task from thisWeek to thisMonth',
      (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp).first),
        );
        final helper = TaskDragTestHelper(tester, container);
        final sectionHelper = TaskSectionTestHelper(tester, container);

        final now = DateTime.now();
        final thisWeekTasks = await sectionHelper.createTasksForSection(
          TaskSection.thisWeek,
          5,
          now: now,
        );
        final thisMonthTasks = await sectionHelper.createTasksForSection(
          TaskSection.thisMonth,
          5,
          now: now,
        );
        expect(thisWeekTasks.length, greaterThan(0),
            reason: 'ThisWeek 区域应该有任务');

        await helper.navigateToTasks();

        final draggedTaskTitle = thisWeekTasks.first.title;
        final draggedTaskFinder = helper.findTaskByTitle(draggedTaskTitle);
        await tester.ensureVisible(draggedTaskFinder.first);
        await tester.pumpAndSettle();

        // 滚动到 thisMonth 区域（如果需要）
        final thisMonthTaskTitle = thisMonthTasks.first.title;
        final thisMonthTaskFinder = helper.findTaskByTitle(thisMonthTaskTitle);
        await tester.ensureVisible(thisMonthTaskFinder.first);
        await tester.pumpAndSettle();

        final thisMonthTaskPosition = tester.getCenter(thisMonthTaskFinder.first);

        // 执行拖拽
        final gesture = await helper.performLongPressDrag(
          startFinder: draggedTaskFinder,
          endOffset: thisMonthTaskPosition,
        );

        expect(gesture, isNotNull, reason: '应该能开始拖拽');

        // 等待插入线显示
        await tester.pump(const Duration(milliseconds: 300));

        // 验证插入线显示
        expect(helper.verifyInsertionLineVisible(), isTrue,
            reason: '跨区域拖拽时应该显示插入间隔线');

        // 释放拖拽
        await gesture!.up();
        await helper.waitForAnimation();

        // 验证任务已移动到目标区域（数据库）
        final taskRepository = container.read(taskRepositoryProvider);
        final movedTask = await taskRepository.findById(thisWeekTasks.first.id);
        expect(movedTask, isNotNull, reason: '任务应该存在');

        final actualSection = TaskSectionUtils.getSectionForDate(movedTask!.dueAt);
        expect(actualSection, TaskSection.thisMonth,
            reason: '任务应该在 ThisMonth 区域');
      },
    );

    testWidgets(
      'should drag task from thisMonth to later',
      (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp).first),
        );
        final helper = TaskDragTestHelper(tester, container);
        final sectionHelper = TaskSectionTestHelper(tester, container);

        final now = DateTime.now();
        final thisMonthTasks = await sectionHelper.createTasksForSection(
          TaskSection.thisMonth,
          5,
          now: now,
        );
        final laterTasks = await sectionHelper.createTasksForSection(
          TaskSection.later,
          5,
          now: now,
        );
        expect(thisMonthTasks.length, greaterThan(0),
            reason: 'ThisMonth 区域应该有任务');

        await helper.navigateToTasks();

        final draggedTaskTitle = thisMonthTasks.first.title;
        final draggedTaskFinder = helper.findTaskByTitle(draggedTaskTitle);
        await tester.ensureVisible(draggedTaskFinder.first);
        await tester.pumpAndSettle();

        // 滚动到 later 区域（如果需要）
        final laterTaskTitle = laterTasks.first.title;
        final laterTaskFinder = helper.findTaskByTitle(laterTaskTitle);
        await tester.ensureVisible(laterTaskFinder.first);
        await tester.pumpAndSettle();

        final laterTaskPosition = tester.getCenter(laterTaskFinder.first);

        // 执行拖拽
        final gesture = await helper.performLongPressDrag(
          startFinder: draggedTaskFinder,
          endOffset: laterTaskPosition,
        );

        expect(gesture, isNotNull, reason: '应该能开始拖拽');

        // 等待插入线显示
        await tester.pump(const Duration(milliseconds: 300));

        // 验证插入线显示
        expect(helper.verifyInsertionLineVisible(), isTrue,
            reason: '跨区域拖拽时应该显示插入间隔线');

        // 释放拖拽
        await gesture!.up();
        await helper.waitForAnimation();

        // 验证任务已移动到目标区域（数据库）
        final taskRepository = container.read(taskRepositoryProvider);
        final movedTask = await taskRepository.findById(thisMonthTasks.first.id);
        expect(movedTask, isNotNull, reason: '任务应该存在');

        final actualSection = TaskSectionUtils.getSectionForDate(movedTask!.dueAt);
        expect(actualSection, TaskSection.later,
            reason: '任务应该在 Later 区域');
      },
    );

    testWidgets(
      'should drag task from later to today (long distance cross-section)',
      (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp).first),
        );
        final helper = TaskDragTestHelper(tester, container);
        final sectionHelper = TaskSectionTestHelper(tester, container);

        final now = DateTime.now();
        final laterTasks = await sectionHelper.createTasksForSection(
          TaskSection.later,
          5,
          now: now,
        );
        final todayTasks = await sectionHelper.createTasksForSection(
          TaskSection.today,
          5,
          now: now,
        );
        expect(laterTasks.length, greaterThan(0),
            reason: 'Later 区域应该有任务');

        await helper.navigateToTasks();

        // 先滚动到 later 区域
        final draggedTaskTitle = laterTasks.first.title;
        final draggedTaskFinder = helper.findTaskByTitle(draggedTaskTitle);
        await tester.ensureVisible(draggedTaskFinder.first);
        await tester.pumpAndSettle();

        // 滚动到 today 区域
        final todayTaskTitle = todayTasks.first.title;
        final todayTaskFinder = helper.findTaskByTitle(todayTaskTitle);
        await tester.ensureVisible(todayTaskFinder.first);
        await tester.pumpAndSettle();

        final todayTaskPosition = tester.getCenter(todayTaskFinder.first);

        // 执行拖拽
        final gesture = await helper.performLongPressDrag(
          startFinder: draggedTaskFinder,
          endOffset: todayTaskPosition,
        );

        expect(gesture, isNotNull, reason: '应该能开始拖拽');

        // 等待插入线显示
        await tester.pump(const Duration(milliseconds: 300));

        // 验证插入线显示
        expect(helper.verifyInsertionLineVisible(), isTrue,
            reason: '跨区域拖拽时应该显示插入间隔线');

        // 释放拖拽
        await gesture!.up();
        await helper.waitForAnimation();

        // 验证任务已移动到目标区域（数据库）
        final taskRepository = container.read(taskRepositoryProvider);
        final movedTask = await taskRepository.findById(laterTasks.first.id);
        expect(movedTask, isNotNull, reason: '任务应该存在');

        final actualSection = TaskSectionUtils.getSectionForDate(movedTask!.dueAt);
        expect(actualSection, TaskSection.today,
            reason: '任务应该在 Today 区域');
      },
    );
  });
}

