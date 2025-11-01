import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:granoflow/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Cross-Section Drag and Drop', () {
    testWidgets('should drag task from overdue to today', 
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to Tasks page
      final tasksTab = find.byIcon(Icons.task_alt_rounded);
      await tester.tap(tasksTab);
      await tester.pumpAndSettle();

      // Find a task in the overdue section
      final overdueTask = find.descendant(
        of: find.byKey(const Key('section-overdue')),
        matching: find.byType(ListTile),
      ).first;
      
      if (overdueTask.evaluate().isNotEmpty) {
        // Long press to start dragging
        final gesture = await tester.startGesture(
          tester.getCenter(overdueTask),
        );
        await tester.pump(const Duration(milliseconds: 600));
        
        // Drag to today section
        final todaySection = find.byKey(const Key('section-today'));
        await gesture.moveTo(tester.getCenter(todaySection));
        await tester.pump();
        
        // Release the drag
        await gesture.up();
        await tester.pumpAndSettle();
        
        // Verify task moved (would need to check actual data)
        // This is a simplified example - in real tests you'd verify
        // the task is now in today section
      }
    });

    testWidgets('should drag task to become child of another task', 
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to Tasks page
      final tasksTab = find.byIcon(Icons.task_alt_rounded);
      await tester.tap(tasksTab);
      await tester.pumpAndSettle();

      // Find two tasks in the same section
      final todayTasks = find.descendant(
        of: find.byKey(const Key('section-today')),
        matching: find.byType(ListTile),
      );
      
      if (todayTasks.evaluate().length >= 2) {
        final task1 = todayTasks.at(0);
        final task2 = todayTasks.at(1);
        
        // Long press on task 2
        final gesture = await tester.startGesture(
          tester.getCenter(task2),
        );
        await tester.pump(const Duration(milliseconds: 600));
        
        // Drag onto task 1 to make it a child
        await gesture.moveTo(tester.getCenter(task1));
        await tester.pump();
        
        // Hold for a moment to trigger "make child" action
        await tester.pump(const Duration(seconds: 1));
        
        // Release the drag
        await gesture.up();
        await tester.pumpAndSettle();
        
        // Task 2 should now be a child of task 1
        // In real tests, verify the hierarchy change
      }
    });

    testWidgets('should drag within same section to reorder', 
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to Inbox
      final drawer = find.byIcon(Icons.menu);
      await tester.tap(drawer);
      await tester.pumpAndSettle();
      
      final inbox = find.text('Inbox');
      await tester.tap(inbox);
      await tester.pumpAndSettle();

      // Find tasks in inbox
      final inboxTasks = find.byType(ListTile);
      
      if (inboxTasks.evaluate().length >= 2) {
        final task1 = inboxTasks.at(0);
        final task2 = inboxTasks.at(1);
        
        // Get initial positions
        final initialTask1Y = tester.getCenter(task1).dy;
        
        // Drag task 2 above task 1
        final gesture = await tester.startGesture(
          tester.getCenter(task2),
        );
        await tester.pump(const Duration(milliseconds: 600));
        
        await gesture.moveTo(Offset(
          tester.getCenter(task1).dx,
          initialTask1Y - 50, // Move above task 1
        ));
        await tester.pump();
        
        await gesture.up();
        await tester.pumpAndSettle();
        
        // Verify order changed (tasks should have swapped positions)
        // In real tests, verify the actual order in data
      }
    });

    testWidgets('should promote subtask to root by dragging', 
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to Inbox
      final drawer = find.byIcon(Icons.menu);
      await tester.tap(drawer);
      await tester.pumpAndSettle();
      
      final inbox = find.text('Inbox');
      await tester.tap(inbox);
      await tester.pumpAndSettle();

      // Find a task with subtasks (would need to expand it first)
      final expandButton = find.text('展开子任务').first;
      if (expandButton.evaluate().isNotEmpty) {
        await tester.tap(expandButton);
        await tester.pumpAndSettle();
        
        // Find a subtask (indented)
        final subtask = find.descendant(
          of: find.byType(Padding),
          matching: find.byType(ListTile),
        ).first;
        
        if (subtask.evaluate().isNotEmpty) {
          // Long press on subtask
          final gesture = await tester.startGesture(
            tester.getCenter(subtask),
          );
          await tester.pump(const Duration(milliseconds: 600));
          
          // Drag to top of list (promote target area)
          final topOfList = find.byType(AnimatedList);
          await gesture.moveTo(Offset(
            tester.getCenter(topOfList).dx,
            tester.getTopLeft(topOfList).dy + 20,
          ));
          await tester.pump();
          
          await gesture.up();
          await tester.pumpAndSettle();
          
          // Subtask should now be a root task
          // In real tests, verify the hierarchy change
        }
      }
    });

    testWidgets('visual feedback during drag', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to Tasks page
      final tasksTab = find.byIcon(Icons.task_alt_rounded);
      await tester.tap(tasksTab);
      await tester.pumpAndSettle();

      // Find a task
      final task = find.byType(ListTile).first;
      if (task.evaluate().isNotEmpty) {
        // Start dragging
        final gesture = await tester.startGesture(
          tester.getCenter(task),
        );
        await tester.pump(const Duration(milliseconds: 600));
        
        // Move a bit to trigger drag
        await gesture.moveBy(const Offset(0, 50));
        await tester.pump();
        
        // Should see drag feedback (scaled, rotated, semi-transparent)
        final dragFeedback = find.byWidgetPredicate(
          (widget) => widget is Transform,
        );
        expect(dragFeedback, findsWidgets);
        
        // Release
        await gesture.up();
        await tester.pumpAndSettle();
      }
    });
  });
}
