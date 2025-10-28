import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:granoflow/presentation/tasks/tasks_drag_target.dart';
import 'package:granoflow/presentation/tasks/tasks_drag_target_type.dart';

void main() {
  group('TasksPageDragTarget Tests', () {
    testWidgets('idle should not show custom child for between target', (tester) async {
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

      // 空闲状态下不显示插入占位/自定义内容
      expect(find.text('Custom Child'), findsNothing);
    });

    testWidgets('idle should not show indicator for between target', (tester) async {
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

      // 空闲状态下不应渲染默认指示线
      expect(find.byWidgetPredicate((widget) => 
        widget is Container && 
        widget.constraints?.maxHeight == 2.0 &&
        widget.margin == const EdgeInsets.symmetric(vertical: 12)
      ), findsNothing);
    });

    testWidgets('idle should not show indicator for section first target', (tester) async {
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

      // 空闲状态下不应渲染默认指示线
      expect(find.byWidgetPredicate((widget) => 
        widget is Container && 
        widget.constraints?.maxHeight == 2.0 &&
        widget.margin == const EdgeInsets.only(bottom: 12)
      ), findsNothing);
    });

    testWidgets('idle should not show indicator for section last target', (tester) async {
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

      // 空闲状态下不应渲染默认指示线
      expect(find.byWidgetPredicate((widget) => 
        widget is Container && 
        widget.constraints?.maxHeight == 2.0 &&
        widget.margin == const EdgeInsets.only(top: 12)
      ), findsNothing);
    });
  });
}
