import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/presentation/tasks/tasks_drag_handler.dart';

void main() {
  group('TasksPageDragHandler Tests', () {
    testWidgets('should show normal child when enabled is false', (
      tester,
    ) async {
      final task = Task(
        id: '1',

        title: 'Test Task',
        status: TaskStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TasksPageDragHandler(
                task: task,
                enabled: false,
                child: const Text('Test Child'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);

      // 当enabled为false时，应该直接返回child，不包装LongPressDraggable
      expect(find.byType(LongPressDraggable<Task>), findsNothing);
    });

    testWidgets('should show draggable when enabled is true', (tester) async {
      final task = Task(
        id: '1',

        title: 'Test Task',
        status: TaskStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TasksPageDragHandler(
                task: task,
                enabled: true,
                child: const Text('Test Child'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);
      expect(find.byType(LongPressDraggable<Task>), findsOneWidget);
    });

    testWidgets('should show feedback when dragging', (tester) async {
      final task = Task(
        id: '1',

        title: 'Test Task',
        status: TaskStatus.pending,
        dueAt: DateTime(2025, 1, 27, 14, 30),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TasksPageDragHandler(
                task: task,
                enabled: true,
                child: const Text('Test Child'),
              ),
            ),
          ),
        ),
      );

      // 开始拖拽
      await tester.startGesture(tester.getCenter(find.text('Test Child')));
      await tester.pump(const Duration(milliseconds: 800));

      // 应该显示拖拽反馈（现在只显示 child 内容）
      // 由于拖拽时原位置和反馈都显示相同内容，我们检查是否有拖拽反馈
      expect(find.text('Test Child'), findsNWidgets(2)); // 原位置 + 反馈
    });
  });
}
