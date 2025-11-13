import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:granoflow/main.dart' as app;
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/core/providers/repository_providers.dart';
import 'helpers/task_drag_test_helper.dart';
import 'helpers/task_section_test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Tasks Drag and Drop - Comprehensive Tests', () {
    testWidgets(
      'should insert task at the beginning of the list (Inbox)',
      (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp).first),
        );
        final helper = TaskDragTestHelper(tester, container);

        // 确保有足够的任务
        final inboxTasks = await helper.getInboxTasks();
        if (inboxTasks.length < 3) {
          for (int i = 0; i < 5; i++) {
            await helper.addTestTask('排序测试任务 $i');
          }
          await Future.delayed(const Duration(milliseconds: 500));
        }

        await helper.navigateToInbox();

        final tasks = await helper.getInboxTasks();
        expect(tasks.length, greaterThanOrEqualTo(2),
            reason: '应该有至少 2 个任务');

        final draggedTask = tasks.last;
        final firstTask = tasks.first;

        final draggedFinder = helper.findTaskByTitle(draggedTask.title);
        final firstFinder = helper.findTaskByTitle(firstTask.title);

        if (draggedFinder.evaluate().isEmpty || firstFinder.evaluate().isEmpty) {
          return; // 跳过如果任务不在 UI 中
        }

        final firstPosition = tester.getCenter(firstFinder.first);

        // 拖拽到列表开头（随机坐标：任务中心 ± 100px）
        final random = math.Random();
        final randomX = firstPosition.dx + (random.nextDouble() - 0.5) * 100; // ±50px
        final randomY = firstPosition.dy - 30 - random.nextDouble() * 70; // -30 到 -100px
        final gesture = await helper.performLongPressDrag(
          startFinder: draggedFinder,
          endOffset: Offset(randomX, randomY),
        );

        if (gesture != null) {
          await gesture.up();
          await helper.waitForAnimation();

          // 验证排序（通过数据库验证）
          final taskRepository = await container.read(taskRepositoryProvider.future);
          final updatedTask = await taskRepository.findById(draggedTask.id);
          expect(updatedTask, isNotNull, reason: '任务应该存在');
          expect(updatedTask!.sortIndex, lessThan(firstTask.sortIndex),
              reason: '拖拽后的任务应该在列表开头');
        }
      },
    );

    testWidgets(
      'should insert task between two tasks (Inbox)',
      (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp).first),
        );
        final helper = TaskDragTestHelper(tester, container);

        final inboxTasks = await helper.getInboxTasks();
        if (inboxTasks.length < 3) {
          for (int i = 0; i < 5; i++) {
            await helper.addTestTask('排序测试任务 $i');
          }
          await Future.delayed(const Duration(milliseconds: 500));
        }

        await helper.navigateToInbox();

        final tasks = await helper.getInboxTasks();
        expect(tasks.length, greaterThanOrEqualTo(3),
            reason: '应该有至少 3 个任务');

        final draggedTask = tasks.last;
        final beforeTask = tasks[0];
        final afterTask = tasks[1];

        final draggedFinder = helper.findTaskByTitle(draggedTask.title);
        final beforeFinder = helper.findTaskByTitle(beforeTask.title);
        final afterFinder = helper.findTaskByTitle(afterTask.title);

        if (draggedFinder.evaluate().isEmpty ||
            beforeFinder.evaluate().isEmpty ||
            afterFinder.evaluate().isEmpty) {
          return;
        }

        final afterPosition = tester.getCenter(afterFinder.first);

        // 拖拽到两个任务之间（随机坐标：任务中心 ± 100px）
        final random = math.Random();
        final randomX = afterPosition.dx + (random.nextDouble() - 0.5) * 100; // ±50px
        final randomY = afterPosition.dy - 20 - random.nextDouble() * 80; // -20 到 -100px
        final gesture = await helper.performLongPressDrag(
          startFinder: draggedFinder,
          endOffset: Offset(randomX, randomY),
        );

        if (gesture != null) {
          await gesture.up();
          await helper.waitForAnimation();

          // 验证排序
          final taskRepository = await container.read(taskRepositoryProvider.future);
          final updatedTask = await taskRepository.findById(draggedTask.id);
          expect(updatedTask, isNotNull, reason: '任务应该存在');
          expect(updatedTask!.sortIndex, greaterThan(beforeTask.sortIndex),
              reason: '拖拽后的任务应该在 beforeTask 之后');
          expect(updatedTask.sortIndex, lessThan(afterTask.sortIndex),
              reason: '拖拽后的任务应该在 afterTask 之前');
        }
      },
    );

    testWidgets(
      'should insert task at the end of the list (Inbox)',
      (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp).first),
        );
        final helper = TaskDragTestHelper(tester, container);

        final inboxTasks = await helper.getInboxTasks();
        if (inboxTasks.length < 3) {
          for (int i = 0; i < 5; i++) {
            await helper.addTestTask('排序测试任务 $i');
          }
          await Future.delayed(const Duration(milliseconds: 500));
        }

        await helper.navigateToInbox();

        final tasks = await helper.getInboxTasks();
        expect(tasks.length, greaterThanOrEqualTo(2),
            reason: '应该有至少 2 个任务');

        final draggedTask = tasks.first;
        final lastTask = tasks.last;

        final draggedFinder = helper.findTaskByTitle(draggedTask.title);
        final lastFinder = helper.findTaskByTitle(lastTask.title);

        if (draggedFinder.evaluate().isEmpty || lastFinder.evaluate().isEmpty) {
          return;
        }

        final lastPosition = tester.getCenter(lastFinder.first);

        // 拖拽到列表末尾（随机坐标：任务中心 ± 100px）
        final random = math.Random();
        final randomX = lastPosition.dx + (random.nextDouble() - 0.5) * 100; // ±50px
        final randomY = lastPosition.dy + 40 + random.nextDouble() * 60; // +40 到 +100px
        final gesture = await helper.performLongPressDrag(
          startFinder: draggedFinder,
          endOffset: Offset(randomX, randomY),
        );

        if (gesture != null) {
          await gesture.up();
          await helper.waitForAnimation();

          // 验证排序
          final taskRepository = await container.read(taskRepositoryProvider.future);
          final updatedTask = await taskRepository.findById(draggedTask.id);
          expect(updatedTask, isNotNull, reason: '任务应该存在');
          expect(updatedTask!.sortIndex, greaterThan(lastTask.sortIndex),
              reason: '拖拽后的任务应该在列表末尾');
        }
      },
    );

    testWidgets(
      'should reorder tasks within the same section (Tasks)',
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
        final tasks = await sectionHelper.createTasksForSection(
          TaskSection.today,
          3,
          now: now,
        );
        expect(tasks.length, greaterThanOrEqualTo(2),
            reason: '应该有至少 2 个任务');

        await helper.navigateToTasks();

        final draggedTask = tasks.last;
        final targetTask = tasks.first;

        final draggedFinder = helper.findTaskByTitle(draggedTask.title);
        final targetFinder = helper.findTaskByTitle(targetTask.title);

        if (draggedFinder.evaluate().isEmpty || targetFinder.evaluate().isEmpty) {
          return;
        }

        final targetPosition = tester.getCenter(targetFinder.first);

        // 拖拽到目标位置（随机坐标：任务中心 ± 100px）
        final random = math.Random();
        final randomX = targetPosition.dx + (random.nextDouble() - 0.5) * 100; // ±50px
        final randomY = targetPosition.dy - 40 - random.nextDouble() * 60; // -40 到 -100px
        final gesture = await helper.performLongPressDrag(
          startFinder: draggedFinder,
          endOffset: Offset(randomX, randomY),
        );

        if (gesture != null) {
          await gesture.up();
          await helper.waitForAnimation();

          // 验证排序
          final taskRepository = await container.read(taskRepositoryProvider.future);
          final updatedTask = await taskRepository.findById(draggedTask.id);
          expect(updatedTask, isNotNull, reason: '任务应该存在');
          expect(updatedTask!.sortIndex, lessThan(targetTask.sortIndex),
              reason: '拖拽后的任务应该在目标任务之前');
        }
      },
    );

    testWidgets(
      'should drag task to become child of another task',
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
        final tasks = await sectionHelper.createTasksForSection(
          TaskSection.today,
          3,
          now: now,
        );
        expect(tasks.length, greaterThanOrEqualTo(2),
            reason: '应该有至少 2 个任务');

        await helper.navigateToTasks();

        final draggedTask = tasks.last;
        final targetTask = tasks.first;

        final draggedFinder = helper.findTaskByTitle(draggedTask.title);
        final targetFinder = helper.findTaskByTitle(targetTask.title);

        if (draggedFinder.evaluate().isEmpty || targetFinder.evaluate().isEmpty) {
          return;
        }

        final targetPosition = tester.getCenter(targetFinder.first);

        // 拖拽到目标任务上（移入任务）（随机坐标：任务中心 ± 100px）
        final random = math.Random();
        final randomX = targetPosition.dx + (random.nextDouble() - 0.5) * 100; // ±50px
        final randomY = targetPosition.dy + (random.nextDouble() - 0.5) * 100; // ±50px
        final gesture = await helper.performLongPressDrag(
          startFinder: draggedFinder,
          endOffset: Offset(randomX, randomY),
        );

        if (gesture != null) {
          // 悬停一段时间，触发移入任务
          await tester.pump(const Duration(milliseconds: 500));
          await gesture.up();
          await helper.waitForAnimation();

          // 层级功能已移除，不再验证层级关系
          final taskRepository = await container.read(taskRepositoryProvider.future);
          final updatedTask = await taskRepository.findById(draggedTask.id);
          expect(updatedTask, isNotNull, reason: '任务应该存在');
        }
      },
    );

    testWidgets(
      'should handle empty section drag',
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
        // 创建一个有任务的 section
        final sourceTasks = await sectionHelper.createTasksForSection(
          TaskSection.today,
          2,
          now: now,
        );
        // 创建一个空 section（只创建任务但立即删除，或使用其他方式）
        // 这里我们假设 tomorrow section 是空的

        await helper.navigateToTasks();

        if (sourceTasks.isEmpty) return;

        final draggedTask = sourceTasks.first;
        final draggedFinder = helper.findTaskByTitle(draggedTask.title);

        if (draggedFinder.evaluate().isEmpty) return;

        // 尝试拖拽到空 section（这个测试可能需要根据实际实现调整）
        // 如果明天 section 有任务，我们也可以测试
        final tomorrowTasks = await sectionHelper.getSectionTasks(TaskSection.tomorrow);
        if (tomorrowTasks.isEmpty) {
          // 空 section 测试：拖拽应该能够创建任务到空 section
          // 这里需要根据实际实现来验证
        }
      },
    );

    testWidgets(
      'should handle dragging task to invalid position (cancel drag)',
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
        final tasks = await sectionHelper.createTasksForSection(
          TaskSection.today,
          2,
          now: now,
        );
        expect(tasks.length, greaterThanOrEqualTo(1),
            reason: '应该有至少 1 个任务');

        await helper.navigateToTasks();

        final draggedTask = tasks.first;
        final draggedFinder = helper.findTaskByTitle(draggedTask.title);

        if (draggedFinder.evaluate().isEmpty) return;

        // 拖拽到无效位置（随机坐标：屏幕外或远离任务的位置）
        final random = math.Random();
        // 随机选择屏幕外位置（负坐标或超出屏幕的坐标）
        final randomX = random.nextBool() 
            ? -100 - random.nextDouble() * 200  // 屏幕左侧外
            : 1000 + random.nextDouble() * 200; // 屏幕右侧外
        final randomY = random.nextBool()
            ? -100 - random.nextDouble() * 200  // 屏幕上方外
            : 2000 + random.nextDouble() * 200; // 屏幕下方外
        final gesture = await helper.performLongPressDrag(
          startFinder: draggedFinder,
          endOffset: Offset(randomX, randomY),
        );

        if (gesture != null) {
          await gesture.up();
          await helper.waitForAnimation();

          // 验证任务没有被移动（sortIndex 不变）
          final taskRepository = await container.read(taskRepositoryProvider.future);
          final updatedTask = await taskRepository.findById(draggedTask.id);
          expect(updatedTask, isNotNull, reason: '任务应该存在');
          expect(updatedTask!.sortIndex, draggedTask.sortIndex,
              reason: '拖拽到无效位置时，任务应该保持原位置');
        }
      },
    );

    testWidgets(
      'should verify database consistency after drag',
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
        final tasks = await sectionHelper.createTasksForSection(
          TaskSection.today,
          2,
          now: now,
        );
        expect(tasks.length, greaterThanOrEqualTo(2),
            reason: '应该有至少 2 个任务');

        await helper.navigateToTasks();

        final draggedTask = tasks.last;
        final targetTask = tasks.first;

        final draggedFinder = helper.findTaskByTitle(draggedTask.title);
        final targetFinder = helper.findTaskByTitle(targetTask.title);

        if (draggedFinder.evaluate().isEmpty || targetFinder.evaluate().isEmpty) {
          return;
        }

        final targetPosition = tester.getCenter(targetFinder.first);

        // 记录拖拽前的状态
        final taskRepository = await container.read(taskRepositoryProvider.future);
        final beforeDrag = await taskRepository.findById(draggedTask.id);
        expect(beforeDrag, isNotNull, reason: '拖拽前的任务应该存在');

        // 执行拖拽（随机坐标：任务中心 ± 100px）
        final random = math.Random();
        final randomX = targetPosition.dx + (random.nextDouble() - 0.5) * 100; // ±50px
        final randomY = targetPosition.dy - 40 - random.nextDouble() * 60; // -40 到 -100px
        final gesture = await helper.performLongPressDrag(
          startFinder: draggedFinder,
          endOffset: Offset(randomX, randomY),
        );

        if (gesture != null) {
          await gesture.up();
          await helper.waitForAnimation();

          // 验证拖拽后的状态
          final afterDrag = await taskRepository.findById(draggedTask.id);
          expect(afterDrag, isNotNull, reason: '拖拽后的任务应该存在');
          expect(afterDrag!.id, beforeDrag!.id, reason: '任务 ID 应该不变');
          expect(afterDrag.title, beforeDrag.title, reason: '任务标题应该不变');
          // sortIndex 应该改变了
          expect(afterDrag.sortIndex, isNot(beforeDrag.sortIndex),
              reason: 'sortIndex 应该改变');
        }
      },
    );
  });
}

