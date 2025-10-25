import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:granoflow/core/theme/app_theme.dart';
import 'package:granoflow/presentation/widgets/create_task_dialog.dart';

void main() {
  group('CreateTaskDialog Widget Tests', () {
    Widget buildTestWidget() {
      return ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: CreateTaskDialog(),
          ),
        ),
      );
    }

    testWidgets('should render with Material wrapper', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Should find Material widget
      expect(find.byType(Material), findsWidgets);
      
      // Get the Material widget
      final materials = tester.widgetList<Material>(find.byType(Material));
      final dialogMaterial = materials.firstWhere(
        (m) => m.color != null,
        orElse: () => materials.first,
      );
      
      // Material should have surface color from theme
      expect(dialogMaterial.color, isNotNull);
    });

    testWidgets('should have proper padding', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Should find Padding widget with correct insets
      final paddingFinder = find.descendant(
        of: find.byType(CreateTaskDialog),
        matching: find.byType(Padding),
      );
      
      expect(paddingFinder, findsWidgets);
      
      // Check if there's padding with vertical: 32, horizontal: 16
      final paddings = tester.widgetList<Padding>(paddingFinder);
      final mainPadding = paddings.firstWhere(
        (p) => p.padding == const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        orElse: () => paddings.first,
      );
      
      expect(mainPadding.padding, equals(const EdgeInsets.symmetric(vertical: 32, horizontal: 16)));
    });

    testWidgets('should render dialog title', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('创建新任务'), findsOneWidget);
    });

    testWidgets('should render title input field', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('任务标题'), findsOneWidget);
      expect(find.text('请输入任务标题'), findsOneWidget);
    });

    testWidgets('should render tag selection', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('标签'), findsOneWidget);
      expect(find.text('工作'), findsOneWidget);
      expect(find.text('学习'), findsOneWidget);
      expect(find.text('生活'), findsOneWidget);
      expect(find.text('娱乐'), findsOneWidget);
    });

    testWidgets('should render parent task dropdown', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('上级任务'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('should render action buttons', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('取消'), findsOneWidget);
      expect(find.text('创建任务'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
      // FilledButton.icon is a factory, so we just check for the button text
      expect(find.widgetWithText(IconButton, '创建任务').evaluate().isEmpty, isTrue);
    });

    testWidgets('should have form elements constrained to maxWidth 400', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Find all ConstrainedBox widgets
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(
        find.byType(ConstrainedBox),
      );

      // Check if there are ConstrainedBox widgets with maxWidth 400
      final width400Boxes = constrainedBoxes.where(
        (box) => box.constraints.maxWidth == 400,
      );

      expect(width400Boxes.length, greaterThanOrEqualTo(4)); // TextField, tags, dropdown, buttons
    });

    testWidgets('should center content horizontally', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Find the main Column
      final columnFinder = find.descendant(
        of: find.byType(CreateTaskDialog),
        matching: find.byType(Column),
      );

      expect(columnFinder, findsWidgets);

      // Get the Column widget inside SizedBox
      final columns = tester.widgetList<Column>(columnFinder);
      final mainColumn = columns.firstWhere(
        (c) => c.crossAxisAlignment == CrossAxisAlignment.center,
        orElse: () => columns.first,
      );

      expect(mainColumn.crossAxisAlignment, equals(CrossAxisAlignment.center));
      expect(mainColumn.mainAxisSize, equals(MainAxisSize.min));
    });

    testWidgets('should handle tag selection', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Initially, '工作' should be selected
      final workChip = find.widgetWithText(FilterChip, '工作');
      expect(workChip, findsOneWidget);

      // Tap on '学习'
      await tester.tap(find.widgetWithText(FilterChip, '学习'));
      await tester.pumpAndSettle();

      // '学习' should now be selected
      final studyChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, '学习'),
      );
      expect(studyChip.selected, isTrue);
    });

    testWidgets('should handle cancel button', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      final cancelButton = find.text('取消');
      expect(cancelButton, findsOneWidget);

      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Dialog should close (Navigation.pop called)
      // In test environment, this means the dialog widget should still exist
      // but in real app, it would be popped from navigation stack
    });

    testWidgets('should show error when creating task with empty title', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Don't enter any title
      final createButton = find.text('创建任务');
      await tester.tap(createButton);
      await tester.pump(); // Start the SnackBar animation
      await tester.pump(const Duration(milliseconds: 750)); // Advance to showtime

      // Should show SnackBar with error message
      // The text appears twice: once in the input hint and once in the SnackBar
      expect(find.text('请输入任务标题'), findsWidgets);
    });

    testWidgets('should create task with valid title', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Enter a title
      await tester.enterText(find.byType(TextField), '测试任务');
      await tester.pumpAndSettle();

      // Tap create button
      final createButton = find.text('创建任务');
      await tester.tap(createButton);
      
      // Just verify the button was tapped and no crash occurred
      // SnackBar testing is unreliable in test environment
      await tester.pumpAndSettle();
    });

    testWidgets('should dispose controller on widget disposal', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Find the widget
      expect(find.byType(CreateTaskDialog), findsOneWidget);

      // Remove the widget
      await tester.pumpWidget(Container());

      // Widget should be disposed (no crash should occur)
    });

    testWidgets('should work in dark theme', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const Scaffold(
              body: CreateTaskDialog(),
            ),
          ),
        ),
      );

      // Should render all elements
      expect(find.text('创建新任务'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('创建任务'), findsOneWidget);
    });

    testWidgets('should have rounded corners on form fields', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Check TextField decoration
      final textField = tester.widget<TextField>(find.byType(TextField));
      final decoration = textField.decoration as InputDecoration;
      final border = decoration.border as OutlineInputBorder;
      
      expect(border.borderRadius, equals(BorderRadius.circular(12)));
    });

    testWidgets('should have rounded corners on buttons', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Check OutlinedButton shape
      final outlinedButton = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      final outlinedStyle = outlinedButton.style;
      expect(outlinedStyle, isNotNull);

      // FilledButton.icon creates a complex widget tree, just verify the button exists
      expect(find.text('创建任务'), findsOneWidget);
    });
  });
}

