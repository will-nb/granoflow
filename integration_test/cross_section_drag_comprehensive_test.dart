import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:granoflow/main.dart' as app;
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/core/providers/repository_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/utils/task_section_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Cross-Section Drag and Drop Comprehensive Tests', () {
    /// 为指定区域创建5个测试任务
    Future<List<Task>> createTasksForSection(
      ProviderContainer container,
      TaskSection section,
      DateTime now,
    ) async {
      final taskService = container.read(taskServiceProvider);
      final taskRepository = container.read(taskRepositoryProvider);
      final List<Task> tasks = [];

      // 根据区域计算对应的 dueAt 日期
      DateTime? dueAt;
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
          // 本周：本周某一天（比如周三）
          // thisWeek 的结束时间是本周一 23:59:59，所以本周应该在 weekStart 到 weekStart+6 之间
          final weekEndTime = TaskSectionUtils.getSectionEndTime(TaskSection.thisWeek, now: now);
          // 使用本周中间的一天（周三）
          dueAt = DateTime(weekEndTime.year, weekEndTime.month, weekEndTime.day - 4, 12, 0, 0);
          break;
        case TaskSection.thisMonth:
          // 本月：本月某一天（比如15号）
          final monthEnd = TaskSectionUtils.getSectionEndTime(TaskSection.thisMonth, now: now);
          dueAt = DateTime(monthEnd.year, monthEnd.month, 15, 12, 0, 0);
          break;
        case TaskSection.later:
          // 以后：下个月第一天，确保日期在 later section 的范围内
          // later section 的定义是：dueDate >= nextMonthStart
          // nextMonthStart = DateTime(currentTime.year, currentTime.month + 1, 1)
          final nextMonth = DateTime(now.year, now.month + 1, 1);
          dueAt = DateTime(nextMonth.year, nextMonth.month, 15, 12, 0, 0);
          break;
        case TaskSection.completed:
        case TaskSection.archived:
        case TaskSection.trash:
          // 这些 section 不应该出现在拖拽测试中
          dueAt = null;
          break;
      }

      // 创建5个任务
      for (int i = 0; i < 5; i++) {
        // 先创建到 Inbox
        final task = await taskService.captureInboxTask(
          title: '${section.name} 测试任务 $i',
        );
        
        // 移动到指定区域（只有当 dueAt 不为 null 时才调用 planTask）
        if (dueAt != null) {
          await taskService.planTask(
            taskId: task.id,
            dueDateLocal: dueAt,
            section: section,
          );
        }
        
        // 获取更新后的任务
        final updatedTask = await taskRepository.findById(task.id);
        if (updatedTask != null) {
          tasks.add(updatedTask);
        }
      }

      // 等待任务创建完成并验证任务确实在指定的 section
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 验证创建的任务确实在正确的 section
      if (dueAt != null && tasks.isNotEmpty) {
        for (final task in tasks) {
          final actualSection = TaskSectionUtils.getSectionForDate(task.dueAt, now: now);
          if (actualSection != section) {
            print('⚠️ 警告: 任务 ${task.title} 创建到了错误的 section: 期望 $section, 实际 $actualSection, dueAt: ${task.dueAt}');
          }
        }
      }
      
      return tasks;
    }

    /// 通过任务标题查找任务
    Finder findTaskByTitle(String title) {
      return find.text(title);
    }

    /// 查找包含指定文本的任务所在的 Card（section panel）
    Finder findSectionPanelContaining(String text) {
      final taskFinder = find.text(text);
      if (taskFinder.evaluate().isEmpty) {
        return find.byType(Card); // 返回空 finder
      }
      // 查找任务的祖先 Card
      return find.ancestor(
        of: taskFinder,
        matching: find.byType(Card),
      );
    }

    /// 获取任务的位置
    Offset? getTaskPosition(WidgetTester tester, String title) {
      final taskFinder = findTaskByTitle(title);
      if (taskFinder.evaluate().isEmpty) {
        return null;
      }
      try {
        return tester.getCenter(taskFinder);
      } catch (e) {
        return null;
      }
    }

    /// 获取任务的位置（带等待和滚动逻辑）
    Future<Offset?> getTaskPositionWithWait(
      WidgetTester tester,
      String title, {
      TaskSection? section,
    }) async {
      // 等待任务数据通过 StreamProvider 更新到 UI
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();
        final taskFinder = find.text(title);
        if (taskFinder.evaluate().isNotEmpty) {
          break;
        }
        if (i == 29) {
          print('⚠️ 等待30次后任务仍未显示: $title');
        }
      }
      
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      
      // 查找任务的位置 - 如果找不到，尝试滚动到任务位置
      var taskPosition = getTaskPosition(tester, title);
      
      if (taskPosition == null) {
        // 尝试通过任务文本来滚动
        final taskFinder = find.text(title);
        if (taskFinder.evaluate().isNotEmpty) {
          // 任务存在但不在可见区域，尝试滚动
          final scrollable = find.byType(Scrollable);
          if (scrollable.evaluate().isNotEmpty) {
            // 根据 section 决定滚动方向
            // overdue, today, tomorrow, thisWeek 通常在顶部，需要向上滚动（负数）
            // thisMonth, later 通常在底部，需要向下滚动（正数）
            final offset = (section == TaskSection.later || section == TaskSection.thisMonth)
                ? const Offset(0, 500)  // 向下滚动
                : const Offset(0, -500); // 向上滚动
            
            await tester.drag(scrollable.first, offset);
            await tester.pumpAndSettle();
            
            // 再次查找任务
            taskPosition = getTaskPosition(tester, title);
            
            // 如果还是找不到，尝试反方向滚动
            if (taskPosition == null) {
              await tester.drag(scrollable.first, Offset(0, -offset.dy));
              await tester.pumpAndSettle();
              taskPosition = getTaskPosition(tester, title);
            }
          }
        }
      }
      
      // 如果还是找不到任务，尝试直接通过 finder 来获取位置（即使不在可见区域）
      if (taskPosition == null) {
        final taskFinder = find.text(title);
        if (taskFinder.evaluate().isNotEmpty) {
          try {
            taskPosition = tester.getCenter(taskFinder.first);
            print('✅ 任务在widget树中，成功获取位置（可能不在可见区域）');
          } catch (e) {
            print('❌ 无法获取任务位置: $e');
          }
        } else {
          print('❌ 任务不在widget树中: $title');
        }
      }
      
      return taskPosition;
    }

    /// 获取 section panel 的中心位置
    Offset? getSectionPanelCenter(WidgetTester tester, Finder panelFinder) {
      if (panelFinder.evaluate().isEmpty) {
        return null;
      }
      try {
        return tester.getCenter(panelFinder);
      } catch (e) {
        return null;
      }
    }

    testWidgets('Setup: Create test tasks in all sections', (tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 等待 MaterialApp 加载，最多等待 10 秒
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (find.byType(MaterialApp).evaluate().isNotEmpty) {
          break;
        }
      }

      // 确保 MaterialApp 已经加载
      expect(find.byType(MaterialApp), findsWidgets);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp).first),
      );

      final now = DateTime.now();
      final sections = [
        TaskSection.overdue,
        TaskSection.today,
        TaskSection.tomorrow,
        TaskSection.thisWeek,
        TaskSection.thisMonth,
        TaskSection.later,
      ];

      print('开始为所有区域创建测试任务...');
      
      for (final section in sections) {
        final tasks = await createTasksForSection(container, section, now);
        print('为 ${section.name} 区域创建了 ${tasks.length} 个任务');
      }

      print('测试任务创建完成！');
    });

    testWidgets('Drag from overdue to today', (tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 等待 MaterialApp 加载
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (find.byType(MaterialApp).evaluate().isNotEmpty) {
          break;
        }
      }

      // 确保 MaterialApp 已经加载
      expect(find.byType(MaterialApp), findsWidgets);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp).first),
      );

      // 导航到 Tasks 页面 - 查找并点击导航栏中的 Tasks 图标
      // Tasks 页面的图标是 Icons.checklist（未选中）或 Icons.fact_check（选中）
      final tasksIcon = find.byIcon(Icons.checklist);
      if (tasksIcon.evaluate().isEmpty) {
        // 如果未选中图标不存在，尝试查找选中图标
        final selectedTasksIcon = find.byIcon(Icons.fact_check);
        if (selectedTasksIcon.evaluate().isEmpty) {
          // 如果都不存在，尝试通过文本查找（"任务清单"）
          final tasksText = find.textContaining('任务');
          if (tasksText.evaluate().isNotEmpty) {
            await tester.tap(tasksText.first);
          }
        } else {
          // 已经在Tasks页面了
        }
      } else {
        await tester.tap(tasksIcon.first);
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 确保两个区域都有任务
      final now = DateTime.now();
      final overdueTasks = await createTasksForSection(container, TaskSection.overdue, now);
      final todayTasks = await createTasksForSection(container, TaskSection.today, now);
      expect(overdueTasks.length, greaterThan(0), reason: 'Overdue 区域应该有任务');
      expect(todayTasks.length, greaterThan(0), reason: 'Today 区域应该有任务');
      
      // 获取第一个任务的标题
      final draggedTaskTitle = overdueTasks.first.title;
      
      // 查找任务的位置（带等待和滚动逻辑）
      final taskPosition = await getTaskPositionWithWait(
        tester,
        draggedTaskTitle,
        section: TaskSection.overdue,
      );
      expect(taskPosition, isNotNull, reason: '应该能找到任务: $draggedTaskTitle');

      // 长按开始拖拽
      final gesture = await tester.startGesture(taskPosition!);
      await tester.pump(const Duration(milliseconds: 600));

      // 查找 today 区域的 panel
      final todayTaskTitle = todayTasks.first.title;
      final todayPanel = findSectionPanelContaining(todayTaskTitle);
      expect(todayPanel, findsWidgets, reason: 'Today 区域应该存在');

      final todaySectionCenter = getSectionPanelCenter(tester, todayPanel.first);
      expect(todaySectionCenter, isNotNull, reason: '应该能找到 Today 区域位置');

      await gesture.moveTo(todaySectionCenter!);
      await tester.pump();

      // 释放拖拽
      await gesture.up();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 等待任务数据更新
      await Future.delayed(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();

      // 验证任务已移动到 today 区域
      print('🔍 查找已移动的任务: $draggedTaskTitle');
      final movedTaskPanel = findSectionPanelContaining(draggedTaskTitle);
      print('📦 找到的 panel 数量: ${movedTaskPanel.evaluate().length}');
      
      if (movedTaskPanel.evaluate().isEmpty) {
        print('❌ 任务未找到！可能的原因：');
        print('   - 任务没有成功移动到 today 区域');
        print('   - 任务标题不匹配');
        
        // 检查任务是否还在 overdue 区域
        final overduePanel = findSectionPanelContaining(overdueTasks.first.title);
        print('📦 Overdue panel 数量: ${overduePanel.evaluate().length}');
        
        // 尝试查找所有任务标题
        final allTasks = find.byType(ListTile);
        print('📋 屏幕上的所有任务数量: ${allTasks.evaluate().length}');
        
        // 检查数据库中任务的实际位置
        final taskRepository = container.read(taskRepositoryProvider);
        final actualTask = await taskRepository.findById(overdueTasks.first.id);
        if (actualTask != null) {
          final actualSection = TaskSectionUtils.getSectionForDate(actualTask.dueAt);
          print('💾 数据库中任务的实际区域: ${actualSection.name}');
          print('💾 数据库中任务的 dueAt: ${actualTask.dueAt}');
        }
      } else {
        print('✅ 找到了移动后的任务 panel');
      }
      
      expect(movedTaskPanel, findsWidgets, reason: '任务应该已移动到 Today 区域');
      
      // 验证任务在 today panel 中，而不是在 overdue panel 中
      final todayPanelAfter = findSectionPanelContaining(todayTaskTitle);
      print('📦 Today panel 数量: ${todayPanelAfter.evaluate().length}');
      
      final draggedTaskInTodayPanel = movedTaskPanel.evaluate().any((element) {
        final todayPanelElements = todayPanelAfter.evaluate();
        return todayPanelElements.any((todayElement) => 
          todayElement.widget == element.widget
        );
      });
      
      print('✅ 任务在 Today panel 中: $draggedTaskInTodayPanel');
      expect(draggedTaskInTodayPanel, isTrue, reason: '任务应该在 Today 区域中');
    });

    testWidgets('Drag from today to tomorrow', (tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 等待 MaterialApp 加载
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (find.byType(MaterialApp).evaluate().isNotEmpty) {
          break;
        }
      }

      // 确保 MaterialApp 已经加载
      expect(find.byType(MaterialApp), findsWidgets);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp).first),
      );

      // 导航到 Tasks 页面 - 查找并点击导航栏中的 Tasks 图标
      // Tasks 页面的图标是 Icons.checklist（未选中）或 Icons.fact_check（选中）
      final tasksIcon = find.byIcon(Icons.checklist);
      if (tasksIcon.evaluate().isEmpty) {
        // 如果未选中图标不存在，尝试查找选中图标
        final selectedTasksIcon = find.byIcon(Icons.fact_check);
        if (selectedTasksIcon.evaluate().isEmpty) {
          // 如果都不存在，尝试通过文本查找（"任务清单"）
          final tasksText = find.textContaining('任务');
          if (tasksText.evaluate().isNotEmpty) {
            await tester.tap(tasksText.first);
          }
        } else {
          // 已经在Tasks页面了
        }
      } else {
        await tester.tap(tasksIcon.first);
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 确保两个区域都有任务
      final now = DateTime.now();
      final todayTasks = await createTasksForSection(container, TaskSection.today, now);
      final tomorrowTasks = await createTasksForSection(container, TaskSection.tomorrow, now);
      expect(todayTasks.length, greaterThan(0), reason: 'Today 区域应该有任务');
      
      // 获取要拖拽的任务
      final draggedTaskTitle = todayTasks.first.title;
      final taskPosition = await getTaskPositionWithWait(
        tester,
        draggedTaskTitle,
        section: TaskSection.today,
      );
      expect(taskPosition, isNotNull, reason: '应该能找到任务: $draggedTaskTitle');

      // 长按开始拖拽
      final gesture = await tester.startGesture(taskPosition!);
      await tester.pump(const Duration(milliseconds: 600));

      // 查找 tomorrow 区域的 panel
      final tomorrowTaskTitle = tomorrowTasks.first.title;
      final tomorrowPanel = findSectionPanelContaining(tomorrowTaskTitle);
      expect(tomorrowPanel, findsWidgets, reason: 'Tomorrow 区域应该存在');

      final tomorrowSectionCenter = getSectionPanelCenter(tester, tomorrowPanel.first);
      expect(tomorrowSectionCenter, isNotNull, reason: '应该能找到 Tomorrow 区域位置');

      await gesture.moveTo(tomorrowSectionCenter!);
      await tester.pump();

      // 释放拖拽
      await gesture.up();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 验证任务已移动到 tomorrow 区域
      final movedTaskPanel = findSectionPanelContaining(draggedTaskTitle);
      expect(movedTaskPanel, findsWidgets, reason: '任务应该已移动到 Tomorrow 区域');
      
      // 验证任务在 tomorrow panel 中
      final tomorrowPanelAfter = findSectionPanelContaining(tomorrowTaskTitle);
      final draggedTaskInTomorrowPanel = movedTaskPanel.evaluate().any((element) {
        final tomorrowPanelElements = tomorrowPanelAfter.evaluate();
        return tomorrowPanelElements.any((tomorrowElement) => 
          tomorrowElement.widget == element.widget
        );
      });
      
      expect(draggedTaskInTomorrowPanel, isTrue, reason: '任务应该在 Tomorrow 区域中');
    });

    testWidgets('Drag from thisWeek to thisMonth', (tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 等待 MaterialApp 加载
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (find.byType(MaterialApp).evaluate().isNotEmpty) {
          break;
        }
      }

      // 确保 MaterialApp 已经加载
      expect(find.byType(MaterialApp), findsWidgets);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp).first),
      );

      // 确保两个区域都有任务
      final now = DateTime.now();
      await createTasksForSection(container, TaskSection.thisWeek, now);
      await createTasksForSection(container, TaskSection.thisMonth, now);

      // 导航到 Tasks 页面 - 查找并点击导航栏中的 Tasks 图标
      final tasksIcon = find.byIcon(Icons.checklist);
      if (tasksIcon.evaluate().isEmpty) {
        final selectedTasksIcon = find.byIcon(Icons.fact_check);
        if (selectedTasksIcon.evaluate().isEmpty) {
          final tasksText = find.textContaining('任务');
          if (tasksText.evaluate().isNotEmpty) {
            await tester.tap(tasksText.first);
          }
        }
      } else {
        await tester.tap(tasksIcon.first);
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 获取任务数据
      final thisWeekTasks = await createTasksForSection(container, TaskSection.thisWeek, now);
      final thisMonthTasks = await createTasksForSection(container, TaskSection.thisMonth, now);
      expect(thisWeekTasks.length, greaterThan(0), reason: 'ThisWeek 区域应该有任务');
      
      // 获取要拖拽的任务
      final draggedTaskTitle = thisWeekTasks.first.title;
      final taskPosition = await getTaskPositionWithWait(
        tester,
        draggedTaskTitle,
        section: TaskSection.thisWeek,
      );
      expect(taskPosition, isNotNull, reason: '应该能找到任务: $draggedTaskTitle');

      // 长按开始拖拽
      final gesture = await tester.startGesture(taskPosition!);
      await tester.pump(const Duration(milliseconds: 600));

      // 查找 thisMonth 区域的 panel
      final thisMonthTaskTitle = thisMonthTasks.first.title;
      final thisMonthPanel = findSectionPanelContaining(thisMonthTaskTitle);
      expect(thisMonthPanel, findsWidgets, reason: 'ThisMonth 区域应该存在');

      // 滚动到 thisMonth 区域（如果需要）
      if (thisMonthPanel.evaluate().isNotEmpty) {
        await tester.dragUntilVisible(
          thisMonthPanel.first,
          find.byType(Scrollable),
          const Offset(0, -200),
        );
        await tester.pumpAndSettle();
      }

      final thisMonthSectionCenter = getSectionPanelCenter(tester, thisMonthPanel.first);
      expect(thisMonthSectionCenter, isNotNull, reason: '应该能找到 ThisMonth 区域位置');

      await gesture.moveTo(thisMonthSectionCenter!);
      await tester.pump();

      // 释放拖拽
      await gesture.up();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 验证任务已移动到 thisMonth 区域
      final movedTaskPanel = findSectionPanelContaining(draggedTaskTitle);
      expect(movedTaskPanel, findsWidgets, reason: '任务应该已移动到 ThisMonth 区域');
      
      // 验证任务在 thisMonth panel 中
      final thisMonthPanelAfter = findSectionPanelContaining(thisMonthTaskTitle);
      final draggedTaskInThisMonthPanel = movedTaskPanel.evaluate().any((element) {
        final thisMonthPanelElements = thisMonthPanelAfter.evaluate();
        return thisMonthPanelElements.any((thisMonthElement) => 
          thisMonthElement.widget == element.widget
        );
      });
      
      expect(draggedTaskInThisMonthPanel, isTrue, reason: '任务应该在 ThisMonth 区域中');
    });

    testWidgets('Drag from thisMonth to later', (tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 等待 MaterialApp 加载
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (find.byType(MaterialApp).evaluate().isNotEmpty) {
          break;
        }
      }

      // 确保 MaterialApp 已经加载
      expect(find.byType(MaterialApp), findsWidgets);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp).first),
      );

      // 确保两个区域都有任务
      final now = DateTime.now();
      await createTasksForSection(container, TaskSection.thisMonth, now);
      await createTasksForSection(container, TaskSection.later, now);

      // 导航到 Tasks 页面 - 查找并点击导航栏中的 Tasks 图标
      final tasksIcon = find.byIcon(Icons.checklist);
      if (tasksIcon.evaluate().isEmpty) {
        final selectedTasksIcon = find.byIcon(Icons.fact_check);
        if (selectedTasksIcon.evaluate().isEmpty) {
          final tasksText = find.textContaining('任务');
          if (tasksText.evaluate().isNotEmpty) {
            await tester.tap(tasksText.first);
          }
        }
      } else {
        await tester.tap(tasksIcon.first);
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 获取任务数据
      final thisMonthTasks = await createTasksForSection(container, TaskSection.thisMonth, now);
      final laterTasks = await createTasksForSection(container, TaskSection.later, now);
      expect(thisMonthTasks.length, greaterThan(0), reason: 'ThisMonth 区域应该有任务');
      
      // 获取要拖拽的任务
      final draggedTaskTitle = thisMonthTasks.first.title;
      final taskPosition = await getTaskPositionWithWait(
        tester,
        draggedTaskTitle,
        section: TaskSection.thisMonth,
      );
      expect(taskPosition, isNotNull, reason: '应该能找到任务: $draggedTaskTitle');

      // 长按开始拖拽
      final gesture = await tester.startGesture(taskPosition!);
      await tester.pump(const Duration(milliseconds: 600));

      // 查找 later 区域的 panel
      final laterTaskTitle = laterTasks.first.title;
      final laterPanel = findSectionPanelContaining(laterTaskTitle);
      expect(laterPanel, findsWidgets, reason: 'Later 区域应该存在');

      // 滚动到 later 区域（如果需要）
      if (laterPanel.evaluate().isNotEmpty) {
        await tester.dragUntilVisible(
          laterPanel.first,
          find.byType(Scrollable),
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();
      }

      final laterSectionCenter = getSectionPanelCenter(tester, laterPanel.first);
      expect(laterSectionCenter, isNotNull, reason: '应该能找到 Later 区域位置');

      await gesture.moveTo(laterSectionCenter!);
      await tester.pump();

      // 释放拖拽
      await gesture.up();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 验证任务已移动到 later 区域
      final movedTaskPanel = findSectionPanelContaining(draggedTaskTitle);
      expect(movedTaskPanel, findsWidgets, reason: '任务应该已移动到 Later 区域');
      
      // 验证任务在 later panel 中
      final laterPanelAfter = findSectionPanelContaining(laterTaskTitle);
      final draggedTaskInLaterPanel = movedTaskPanel.evaluate().any((element) {
        final laterPanelElements = laterPanelAfter.evaluate();
        return laterPanelElements.any((laterElement) => 
          laterElement.widget == element.widget
        );
      });
      
      expect(draggedTaskInLaterPanel, isTrue, reason: '任务应该在 Later 区域中');
    });

    testWidgets('Drag from later back to today', (tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 等待 MaterialApp 加载
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (find.byType(MaterialApp).evaluate().isNotEmpty) {
          break;
        }
      }

      // 确保 MaterialApp 已经加载
      expect(find.byType(MaterialApp), findsWidgets);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp).first),
      );

      // 导航到 Tasks 页面 - 查找并点击导航栏中的 Tasks 图标
      final tasksIcon = find.byIcon(Icons.checklist);
      if (tasksIcon.evaluate().isEmpty) {
        final selectedTasksIcon = find.byIcon(Icons.fact_check);
        if (selectedTasksIcon.evaluate().isEmpty) {
          final tasksText = find.textContaining('任务');
          if (tasksText.evaluate().isNotEmpty) {
            await tester.tap(tasksText.first);
          }
        }
      } else {
        await tester.tap(tasksIcon.first);
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 确保两个区域都有任务（在导航到Tasks页面后再创建）
      final now = DateTime.now();
      final laterTasks = await createTasksForSection(container, TaskSection.later, now);
      final todayTasks = await createTasksForSection(container, TaskSection.today, now);
      expect(laterTasks.length, greaterThan(0), reason: 'Later 区域应该有任务');
      expect(todayTasks.length, greaterThan(0), reason: 'Today 区域应该有任务');
      
      // 获取要拖拽的任务
      final draggedTaskTitle = laterTasks.first.title;
      final taskPosition = await getTaskPositionWithWait(
        tester,
        draggedTaskTitle,
        section: TaskSection.later,
      );
      expect(taskPosition, isNotNull, reason: '应该能找到任务: $draggedTaskTitle');

      // 长按开始拖拽
      final gesture = await tester.startGesture(taskPosition!);
      await tester.pump(const Duration(milliseconds: 600));

      // 查找 today 区域的 panel
      final todayTaskTitle = todayTasks.first.title;
      final todayPanel = findSectionPanelContaining(todayTaskTitle);
      expect(todayPanel, findsWidgets, reason: 'Today 区域应该存在');

      // 滚动到 today 区域（如果需要）
      if (todayPanel.evaluate().isNotEmpty) {
        await tester.dragUntilVisible(
          todayPanel.first,
          find.byType(Scrollable),
          const Offset(0, 300),
        );
        await tester.pumpAndSettle();
      }

      final todaySectionCenter = getSectionPanelCenter(tester, todayPanel.first);
      expect(todaySectionCenter, isNotNull, reason: '应该能找到 Today 区域位置');

      await gesture.moveTo(todaySectionCenter!);
      await tester.pump();

      // 释放拖拽
      await gesture.up();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 验证任务已移动到 today 区域
      final movedTaskPanel = findSectionPanelContaining(draggedTaskTitle);
      expect(movedTaskPanel, findsWidgets, reason: '任务应该已移动到 Today 区域');
      
      // 验证任务在 today panel 中
      final todayPanelAfter = findSectionPanelContaining(todayTaskTitle);
      final draggedTaskInTodayPanel = movedTaskPanel.evaluate().any((element) {
        final todayPanelElements = todayPanelAfter.evaluate();
        return todayPanelElements.any((todayElement) => 
          todayElement.widget == element.widget
        );
      });
      
      expect(draggedTaskInTodayPanel, isTrue, reason: '任务应该在 Today 区域中');
    });
  });
}

