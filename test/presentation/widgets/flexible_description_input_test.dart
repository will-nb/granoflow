import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/presentation/widgets/flexible_description_input.dart';
import 'package:granoflow/presentation/widgets/character_counter_chip.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';

void main() {
  group('FlexibleDescriptionInput', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    Widget createTestWidget(Widget child) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Center(child: child),
          ),
        ),
      );
    }

    testWidgets('初始状态为收起，显示"添加描述"', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          FlexibleDescriptionInput(
            controller: controller,
            softLimit: 200,
            hardLimit: 500,
            hintText: '请输入描述',
          ),
        ),
      );

      // 验证显示"添加描述"按钮 (Verify "Add Description" button is shown)
      expect(find.text('添加描述'), findsOneWidget);
      
      // 验证输入框未显示 (Verify input field is not shown)
      expect(find.byType(TextField), findsNothing);
      
      // 验证字符计数器未显示 (Verify counter is not shown)
      expect(find.byType(CharacterCounterChip), findsNothing);
    });

    testWidgets('点击展开按钮后显示输入框', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          FlexibleDescriptionInput(
            controller: controller,
            softLimit: 200,
            hardLimit: 500,
            hintText: '请输入描述',
          ),
        ),
      );

      // 点击展开按钮 (Tap expand button)
      await tester.tap(find.text('添加描述'));
      await tester.pumpAndSettle();

      // 验证输入框显示 (Verify input field is shown)
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(CharacterCounterChip), findsOneWidget);
      
      // 验证显示收起按钮 (Verify collapse button is shown)
      expect(find.text('收起描述'), findsOneWidget);
    });

    testWidgets('输入内容后，收起再展开显示"编辑描述"', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          FlexibleDescriptionInput(
            controller: controller,
            softLimit: 200,
            hardLimit: 500,
            hintText: '请输入描述',
          ),
        ),
      );

      // 展开 (Expand)
      await tester.tap(find.text('添加描述'));
      await tester.pumpAndSettle();

      // 输入内容 (Enter content)
      await tester.enterText(find.byType(TextField), 'Test description');
      await tester.pumpAndSettle();

      // 收起 (Collapse)
      await tester.tap(find.text('收起描述'));
      await tester.pumpAndSettle();

      // 验证显示"編輯描述" (Verify "Edit Description" is shown) - 注意是繁体中文
      expect(find.text('編輯描述'), findsOneWidget);
      expect(find.text('添加描述'), findsNothing);
    });

    testWidgets('字符计数器正确显示', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          FlexibleDescriptionInput(
            controller: controller,
            softLimit: 50,
            hardLimit: 100,
            hintText: '请输入描述',
          ),
        ),
      );

      // 展开并输入 (Expand and enter text)
      await tester.tap(find.text('添加描述'));
      await tester.pumpAndSettle();
      
      await tester.enterText(find.byType(TextField), 'This is a test description');
      await tester.pumpAndSettle();

      // 验证字符计数 (Verify character count) - 'This is a test description' = 26 字符
      expect(controller.text.length, 26);
      expect(find.textContaining('26/50'), findsOneWidget);
    });

    testWidgets('超限警告正确显示', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          FlexibleDescriptionInput(
            controller: controller,
            softLimit: 20,
            hardLimit: 100,
            hintText: '请输入描述',
          ),
        ),
      );

      // 展开并输入超限文本 (Expand and enter text exceeding soft limit)
      await tester.tap(find.text('添加描述'));
      await tester.pumpAndSettle();
      
      await tester.enterText(
        find.byType(TextField),
        'This is a very long description that exceeds the soft limit',
      );
      await tester.pumpAndSettle();

      // 验证警告显示 (Verify warning is shown)
      expect(find.textContaining('已超出'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('点击收起按钮后隐藏输入框', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          FlexibleDescriptionInput(
            controller: controller,
            softLimit: 200,
            hardLimit: 500,
            hintText: '请输入描述',
          ),
        ),
      );

      // 展开 (Expand)
      await tester.tap(find.text('添加描述'));
      await tester.pumpAndSettle();

      // 验证输入框显示 (Verify input is shown)
      expect(find.byType(TextField), findsOneWidget);

      // 点击收起 (Tap collapse)
      await tester.tap(find.text('收起描述'));
      await tester.pumpAndSettle();

      // 验证输入框隐藏 (Verify input is hidden)
      expect(find.byType(TextField), findsNothing);
      expect(find.text('添加描述'), findsOneWidget);
    });

    testWidgets('箭头旋转动画正常', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          FlexibleDescriptionInput(
            controller: controller,
            softLimit: 200,
            hardLimit: 500,
            hintText: '请输入描述',
          ),
        ),
      );

      // 验证箭头存在 (Verify arrow exists)
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
      
      // 展开 (Expand)
      await tester.tap(find.text('添加描述'));
      await tester.pump(); // 不使用 pumpAndSettle，以便观察动画
      
      // 验证 RotationTransition 存在（至少一个）(Verify RotationTransition exists)
      expect(find.byType(RotationTransition), findsWidgets);
      
      // 完成动画 (Complete animation)
      await tester.pumpAndSettle();
    });

    testWidgets('AnimatedSize 动画正常', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          FlexibleDescriptionInput(
            controller: controller,
            softLimit: 200,
            hardLimit: 500,
            hintText: '请输入描述',
          ),
        ),
      );

      // 验证 AnimatedSize 存在 (Verify AnimatedSize exists)
      expect(find.byType(AnimatedSize), findsOneWidget);
      
      final animatedSize = tester.widget<AnimatedSize>(find.byType(AnimatedSize));
      expect(animatedSize.duration, const Duration(milliseconds: 200));
      expect(animatedSize.curve, Curves.easeInOut);
    });

    testWidgets('onChanged 回调正常工作', (WidgetTester tester) async {
      String? changedValue;
      
      await tester.pumpWidget(
        createTestWidget(
          FlexibleDescriptionInput(
            controller: controller,
            softLimit: 200,
            hardLimit: 500,
            hintText: '请输入描述',
            onChanged: (value) {
              changedValue = value;
            },
          ),
        ),
      );

      // 展开并输入 (Expand and enter text)
      await tester.tap(find.text('添加描述'));
      await tester.pumpAndSettle();
      
      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pumpAndSettle();

      // 验证回调被调用 (Verify callback was called)
      expect(changedValue, 'Test');
    });

    testWidgets('禁用状态正常工作', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          FlexibleDescriptionInput(
            controller: controller,
            softLimit: 200,
            hardLimit: 500,
            hintText: '请输入描述',
            enabled: false,
          ),
        ),
      );

      // 尝试点击展开（应该无效）(Try to expand - should be ineffective)
      await tester.tap(find.text('添加描述'));
      await tester.pumpAndSettle();

      // 验证未展开 (Verify not expanded)
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('自定义 minLines 和 maxLines 正常工作', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          FlexibleDescriptionInput(
            controller: controller,
            softLimit: 200,
            hardLimit: 500,
            hintText: '请输入描述',
            minLines: 5,
            maxLines: 10,
          ),
        ),
      );

      // 展开 (Expand)
      await tester.tap(find.text('添加描述'));
      await tester.pumpAndSettle();

      // 验证行数设置 (Verify line settings)
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.minLines, 5);
      expect(textField.maxLines, 10);
    });

    testWidgets('Semantics 标签存在', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          FlexibleDescriptionInput(
            controller: controller,
            softLimit: 200,
            hardLimit: 500,
            hintText: '请输入描述',
            labelText: '项目描述',
          ),
        ),
      );

      // 验证组件渲染正常 (Verify component renders normally)
      expect(find.byType(FlexibleDescriptionInput), findsOneWidget);
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('英文本地化正确显示', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: FlexibleDescriptionInput(
              controller: controller,
              softLimit: 200,
              hardLimit: 500,
              hintText: 'Enter description',
            ),
          ),
        ),
      );

      // 验证英文文本 (Verify English text)
      expect(find.text('Add Description'), findsOneWidget);
      
      // 展开后验证收起按钮 (Expand and verify collapse button)
      await tester.tap(find.text('Add Description'));
      await tester.pumpAndSettle();
      
      expect(find.text('Hide Description'), findsOneWidget);
    });

    test('断言失败：softLimit > hardLimit', () {
      // 验证断言 (Verify assertion)
      expect(
        () => FlexibleDescriptionInput(
          controller: controller,
          softLimit: 500,
          hardLimit: 200,
          hintText: '请输入描述',
        ),
        throwsAssertionError,
      );
    });
  });
}
