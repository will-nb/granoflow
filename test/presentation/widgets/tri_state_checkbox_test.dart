import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/presentation/widgets/tri_state_checkbox.dart';

void main() {
  group('TriStateCheckbox', () {
    testWidgets('应该正确显示 pending 状态', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TriStateCheckbox(
              value: TriState.pending,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final checkbox = find.byType(TriStateCheckbox);
      expect(checkbox, findsOneWidget);
    });

    testWidgets('应该正确显示 finished 状态', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TriStateCheckbox(
              value: TriState.finished,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final checkbox = find.byType(TriStateCheckbox);
      expect(checkbox, findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('应该正确显示 deleted 状态', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TriStateCheckbox(
              value: TriState.deleted,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final checkbox = find.byType(TriStateCheckbox);
      expect(checkbox, findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('点击应该循环切换状态', (WidgetTester tester) async {
      TriState currentState = TriState.pending;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TriStateCheckbox(
              value: currentState,
              onChanged: (newState) {
                currentState = newState;
              },
            ),
          ),
        ),
      );

      // 点击：pending -> finished
      await tester.tap(find.byType(TriStateCheckbox));
      await tester.pump();
      expect(currentState, TriState.finished);

      // 点击：finished -> deleted
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TriStateCheckbox(
              value: currentState,
              onChanged: (newState) {
                currentState = newState;
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byType(TriStateCheckbox));
      await tester.pump();
      expect(currentState, TriState.deleted);

      // 点击：deleted -> pending
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TriStateCheckbox(
              value: currentState,
              onChanged: (newState) {
                currentState = newState;
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byType(TriStateCheckbox));
      await tester.pump();
      expect(currentState, TriState.pending);
    });

    testWidgets('禁用时不应该切换状态', (WidgetTester tester) async {
      TriState currentState = TriState.pending;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TriStateCheckbox(
              value: currentState,
              onChanged: null, // 禁用
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TriStateCheckbox));
      await tester.pump();
      // 状态不应该改变（因为没有 onChanged 回调）
      expect(currentState, TriState.pending);
    });
  });
}

