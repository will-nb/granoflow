import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:granoflow/core/theme/app_theme.dart';
import 'package:granoflow/presentation/widgets/responsive_task_dialog.dart';
import 'package:granoflow/presentation/widgets/create_task_dialog.dart';

void main() {
  group('ResponsiveTaskDialog Widget Tests', () {
    Widget buildTestWidget({double width = 800}) {
      return ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: width,
              height: 600,
              child: const ResponsiveTaskDialog(),
            ),
          ),
        ),
      );
    }

    testWidgets('should render CreateTaskDialog', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(CreateTaskDialog), findsOneWidget);
    });

    testWidgets('should use LayoutBuilder for responsive layout', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(LayoutBuilder), findsOneWidget);
    });

    testWidgets('should center dialog in wide screen mode (> 600px)', (tester) async {
      await tester.pumpWidget(buildTestWidget(width: 800));

      // Should have ConstrainedBox with maxWidth 500
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox));
      final dialogBox = constrainedBoxes.firstWhere(
        (box) => box.constraints.maxWidth == 500 && box.constraints.maxHeight == 600,
      );
      
      expect(dialogBox.constraints.maxWidth, equals(500));
      expect(dialogBox.constraints.maxHeight, equals(600));
    });

    testWidgets('should not constrain dialog in narrow screen mode (<= 600px)', (tester) async {
      await tester.pumpWidget(buildTestWidget(width: 400));

      // In narrow screen mode, should NOT have ConstrainedBox with maxWidth 500
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox));
      final dialogBoxes = constrainedBoxes.where(
        (box) => box.constraints.maxWidth == 500 && box.constraints.maxHeight == 600,
      );
      
      // Should not find the responsive constrained box
      expect(dialogBoxes.isEmpty, isTrue);
      
      // The CreateTaskDialog should still exist
      expect(find.byType(CreateTaskDialog), findsOneWidget);
    });

    testWidgets('should respect 600px breakpoint', (tester) async {
      // Test exactly at breakpoint
      await tester.pumpWidget(buildTestWidget(width: 600));
      
      // At 600px, should NOT have responsive ConstrainedBox (condition is > 600)
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox));
      final dialogBoxes = constrainedBoxes.where(
        (box) => box.constraints.maxWidth == 500 && box.constraints.maxHeight == 600,
      );
      
      expect(dialogBoxes.isEmpty, isTrue);
    });

    testWidgets('should work with different screen sizes', (tester) async {
      // Test mobile size
      await tester.pumpWidget(buildTestWidget(width: 360));
      expect(find.byType(CreateTaskDialog), findsOneWidget);
      await tester.pumpAndSettle();

      // Test tablet size
      await tester.pumpWidget(buildTestWidget(width: 768));
      expect(find.byType(CreateTaskDialog), findsOneWidget);
      
      // Should have responsive ConstrainedBox
      final tabletBoxes = tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox));
      final tabletDialogBox = tabletBoxes.where(
        (box) => box.constraints.maxWidth == 500 && box.constraints.maxHeight == 600,
      );
      expect(tabletDialogBox.isNotEmpty, isTrue);
      await tester.pumpAndSettle();

      // Test desktop size
      await tester.pumpWidget(buildTestWidget(width: 1280));
      expect(find.byType(CreateTaskDialog), findsOneWidget);
      
      // Should have responsive ConstrainedBox
      final desktopBoxes = tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox));
      final desktopDialogBox = desktopBoxes.where(
        (box) => box.constraints.maxWidth == 500 && box.constraints.maxHeight == 600,
      );
      expect(desktopDialogBox.isNotEmpty, isTrue);
      await tester.pumpAndSettle();
    });

    testWidgets('should maintain dialog functionality in both modes', (tester) async {
      // Test in wide screen
      await tester.pumpWidget(buildTestWidget(width: 800));
      
      // Should find dialog title
      expect(find.text('创建新任务'), findsOneWidget);
      
      // Should find input field
      expect(find.byType(TextField), findsOneWidget);
      
      // Should find buttons
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('创建任务'), findsOneWidget);
      
      await tester.pumpAndSettle();

      // Test in narrow screen
      await tester.pumpWidget(buildTestWidget(width: 400));
      
      // Should still find all elements
      expect(find.text('创建新任务'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('创建任务'), findsOneWidget);
    });

    testWidgets('should properly constrain in wide mode', (tester) async {
      await tester.pumpWidget(buildTestWidget(width: 1920));

      final constrainedBoxes = tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox));
      final dialogBox = constrainedBoxes.firstWhere(
        (box) => box.constraints.maxWidth == 500 && box.constraints.maxHeight == 600,
      );

      expect(dialogBox.constraints.maxWidth, equals(500));
      expect(dialogBox.constraints.maxHeight, equals(600));
    });
  });
}

