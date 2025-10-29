import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/presentation/widgets/character_counter_chip.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';

void main() {
  group('CharacterCounterChip', () {
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

    testWidgets('显示正常状态（count <= softLimit）', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const CharacterCounterChip(
            currentCount: 10,
            softLimit: 50,
            hardLimit: 100,
          ),
        ),
      );

      // 验证显示正确的文本 (Verify correct text is displayed)
      expect(find.textContaining('建議'), findsOneWidget);
      expect(find.textContaining('10/50'), findsOneWidget);
      
      // 验证没有警告图标 (Verify no warning icon)
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
      expect(find.byIcon(Icons.error_rounded), findsNothing);
    });

    testWidgets('显示警告状态（softLimit < count < hardLimit）', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const CharacterCounterChip(
            currentCount: 75,
            softLimit: 50,
            hardLimit: 100,
          ),
        ),
      );

      // 验证显示警告文本 (Verify warning text is displayed)
      expect(find.textContaining('已超出'), findsOneWidget);
      expect(find.textContaining('75/50'), findsOneWidget);
      
      // 验证显示警告图标 (Verify warning icon is displayed)
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('显示错误状态（count == hardLimit）', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const CharacterCounterChip(
            currentCount: 100,
            softLimit: 50,
            hardLimit: 100,
          ),
        ),
      );

      // 验证显示错误文本 (Verify error text is displayed)
      expect(find.textContaining('100/100'), findsOneWidget);
      
      // 验证显示错误图标 (Verify error icon is displayed)
      expect(find.byIcon(Icons.error_rounded), findsOneWidget);
    });

    testWidgets('英文本地化正确显示', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Center(
              child: const CharacterCounterChip(
                currentCount: 10,
                softLimit: 50,
                hardLimit: 100,
              ),
            ),
          ),
        ),
      );

      // 验证英文文本 (Verify English text)
      expect(find.textContaining('Suggested'), findsOneWidget);
      expect(find.textContaining('10/50'), findsOneWidget);
    });

    testWidgets('Semantics 标签正确', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const CharacterCounterChip(
            currentCount: 10,
            softLimit: 50,
            hardLimit: 100,
          ),
        ),
      );

      // 验证组件渲染正常 (Verify component renders normally)
      expect(find.byType(CharacterCounterChip), findsOneWidget);
      expect(find.textContaining('10/50'), findsOneWidget);
    });

    testWidgets('动画过渡正常', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const CharacterCounterChip(
            currentCount: 10,
            softLimit: 50,
            hardLimit: 100,
          ),
        ),
      );

      // 初始渲染 (Initial render)
      await tester.pumpAndSettle();
      expect(find.byType(CharacterCounterChip), findsOneWidget);
      
      // AnimatedContainer 应该存在 (AnimatedContainer should exist)
      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(CharacterCounterChip),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(container.duration, const Duration(milliseconds: 200));
      expect(container.curve, Curves.easeInOut);
    });

    test('断言失败：softLimit > hardLimit', () {
      // 验证断言 (Verify assertion)
      expect(
        () => CharacterCounterChip(
          currentCount: 10,
          softLimit: 100,
          hardLimit: 50,
        ),
        throwsAssertionError,
      );
    });
  });
}
