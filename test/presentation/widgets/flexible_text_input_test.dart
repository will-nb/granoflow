import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/presentation/widgets/flexible_text_input.dart';
import 'package:granoflow/presentation/widgets/character_counter_chip.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';

void main() {
  group('FlexibleTextInput', () {
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
          body: Center(child: child),
        ),
      );
    }

    testWidgets('初始渲染正常', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          FlexibleTextInput(
            controller: controller,
            softLimit: 50,
            hardLimit: 100,
            hintText: '请输入标题',
            labelText: '标题',
          ),
        ),
      );

      // 验证组件渲染 (Verify component renders)
      expect(find.byType(FlexibleTextInput), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(CharacterCounterChip), findsOneWidget);
      
      // 验证标签文本 (Verify label text)
      expect(find.text('标题'), findsOneWidget);
      
      // 验证提示文本 (Verify hint text)
      expect(find.text('请输入标题'), findsOneWidget);
    });

    testWidgets('字符计数器正确显示', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          FlexibleTextInput(
            controller: controller,
            softLimit: 50,
            hardLimit: 100,
            hintText: '请输入',
          ),
        ),
      );

      // 输入文本 (Enter text)
      await tester.enterText(find.byType(TextField), 'Hello World');
      await tester.pumpAndSettle();

      // 验证字符计数 (Verify character count)
      expect(controller.text.length, 11);
      expect(find.textContaining('11/50'), findsOneWidget);
    });

    testWidgets('超过软限制时显示警告', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          FlexibleTextInput(
            controller: controller,
            softLimit: 10,
            hardLimit: 100,
            hintText: '请输入',
          ),
        ),
      );

      // 输入超过软限制的文本 (Enter text exceeding soft limit)
      await tester.enterText(
        find.byType(TextField),
        'This is a long text that exceeds the soft limit',
      );
      await tester.pumpAndSettle();

      // 验证显示警告 (Verify warning is displayed)
      expect(find.textContaining('已超出'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('达到硬限制时阻止输入', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          FlexibleTextInput(
            controller: controller,
            softLimit: 10,
            hardLimit: 20,
            hintText: '请输入',
          ),
        ),
      );

      // 尝试输入超过硬限制的文本 (Try to enter text exceeding hard limit)
      const longText = 'This text is definitely longer than 20 characters!';
      await tester.enterText(find.byType(TextField), longText);
      await tester.pumpAndSettle();

      // 验证文本被截断到硬限制 (Verify text is truncated to hard limit)
      expect(controller.text.length, lessThanOrEqualTo(20));
      expect(find.textContaining('20/20'), findsOneWidget);
      expect(find.byIcon(Icons.error_rounded), findsOneWidget);
    });

    testWidgets('多行切换逻辑正确（包含换行符）', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          FlexibleTextInput(
            controller: controller,
            softLimit: 50,
            hardLimit: 100,
            hintText: '请输入',
          ),
        ),
      );

      // 直接设置包含换行符的文本 (Set text with newline directly)
      controller.text = 'Line 1\nLine 2';
      await tester.pumpAndSettle();

      // 验证切换到多行模式 (Verify switched to multi-line mode)
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLines, greaterThan(1));
      
      // 删除换行符 (Remove newline)
      controller.text = 'Line 1 Line 2';
      await tester.pumpAndSettle();

      // 验证切换回单行模式 (Verify switched back to single line)
      final textFieldAfter = tester.widget<TextField>(find.byType(TextField));
      expect(textFieldAfter.maxLines, 1);
    });

    testWidgets('多行切换逻辑正确（长文本带空格）', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          FlexibleTextInput(
            controller: controller,
            softLimit: 50,
            hardLimit: 100,
            hintText: '请输入',
          ),
        ),
      );

      // 输入超过30字符且包含空格的文本 (Enter text > 30 chars with spaces)
      await tester.enterText(
        find.byType(TextField),
        'This is a long text with spaces',
      );
      await tester.pumpAndSettle();

      // 验证切换到多行模式 (Verify switched to multi-line mode)
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLines, greaterThan(1));
      
      // 删除部分文本 (Remove some text)
      await tester.enterText(find.byType(TextField), 'Short');
      await tester.pumpAndSettle();

      // 验证切换回单行模式 (Verify switched back to single line)
      final textFieldAfter = tester.widget<TextField>(find.byType(TextField));
      expect(textFieldAfter.maxLines, 1);
    });

    testWidgets('焦点状态切换正常', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          FlexibleTextInput(
            controller: controller,
            softLimit: 50,
            hardLimit: 100,
            hintText: '请输入',
          ),
        ),
      );

      // 点击输入框获得焦点 (Tap to gain focus)
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      // 验证焦点动画（AnimatedScale 应该存在）(Verify focus animation)
      expect(find.byType(AnimatedScale), findsOneWidget);
      
      // 点击外部失去焦点 (Tap outside to lose focus)
      await tester.tapAt(const Offset(0, 0));
      await tester.pumpAndSettle();
    });

    testWidgets('onChanged 回调正常工作', (WidgetTester tester) async {
      String? changedValue;
      
      await tester.pumpWidget(
        createTestWidget(
          FlexibleTextInput(
            controller: controller,
            softLimit: 50,
            hardLimit: 100,
            hintText: '请输入',
            onChanged: (value) {
              changedValue = value;
            },
          ),
        ),
      );

      // 输入文本 (Enter text)
      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pumpAndSettle();

      // 验证回调被调用 (Verify callback was called)
      expect(changedValue, 'Test');
    });

    testWidgets('禁用状态正常工作', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          FlexibleTextInput(
            controller: controller,
            softLimit: 50,
            hardLimit: 100,
            hintText: '请输入',
            enabled: false,
          ),
        ),
      );

      // 验证 TextField 被禁用 (Verify TextField is disabled)
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, false);
    });

    testWidgets('Semantics 标签存在', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          FlexibleTextInput(
            controller: controller,
            softLimit: 50,
            hardLimit: 100,
            hintText: '请输入',
            labelText: '标题',
          ),
        ),
      );

      // 验证组件包含标签文本 (Verify component contains label text)
      expect(find.text('标题'), findsOneWidget);
      expect(find.byType(Semantics), findsWidgets);
    });

    test('断言失败：softLimit > hardLimit', () {
      // 验证断言 (Verify assertion)
      expect(
        () => FlexibleTextInput(
          controller: controller,
          softLimit: 100,
          hardLimit: 50,
          hintText: '请输入',
        ),
        throwsAssertionError,
      );
    });
  });
}
