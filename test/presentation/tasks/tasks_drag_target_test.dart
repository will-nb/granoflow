import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:granoflow/presentation/tasks/tasks_drag_target.dart';
import 'package:granoflow/presentation/tasks/tasks_drag_target_type.dart';

void main() {
  group('TasksPageDragTarget Tests', () {
    testWidgets('should show default child for between target', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TasksPageDragTarget(
                targetType: TasksDragTargetType.between,
                child: const Text('Custom Child'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Custom Child'), findsOneWidget);
    });

    testWidgets('should show default indicator for between target', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TasksPageDragTarget(
                targetType: TasksDragTargetType.between,
              ),
            ),
          ),
        ),
      );

      // 应该显示默认的指示线 - 查找有特定高度和margin的Container
      expect(find.byWidgetPredicate((widget) => 
        widget is Container && 
        widget.constraints?.maxHeight == 3.0 &&
        widget.margin == const EdgeInsets.symmetric(vertical: 12)
      ), findsOneWidget);
    });

    testWidgets('should show default indicator for section first target', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TasksPageDragTarget(
                targetType: TasksDragTargetType.sectionFirst,
              ),
            ),
          ),
        ),
      );

      // 应该显示默认的指示线 - 查找有特定高度和margin的Container
      expect(find.byWidgetPredicate((widget) => 
        widget is Container && 
        widget.constraints?.maxHeight == 3.0 &&
        widget.margin == const EdgeInsets.only(bottom: 12)
      ), findsOneWidget);
    });

    testWidgets('should show default indicator for section last target', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TasksPageDragTarget(
                targetType: TasksDragTargetType.sectionLast,
              ),
            ),
          ),
        ),
      );

      // 应该显示默认的指示线 - 查找有特定高度和margin的Container
      expect(find.byWidgetPredicate((widget) => 
        widget is Container && 
        widget.constraints?.maxHeight == 3.0 &&
        widget.margin == const EdgeInsets.only(top: 12)
      ), findsOneWidget);
    });
  });
}
