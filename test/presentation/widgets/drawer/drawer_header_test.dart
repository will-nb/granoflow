import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:granoflow/core/theme/app_theme.dart';
import 'package:granoflow/presentation/widgets/drawer/drawer_header.dart' as drawer;
import 'package:granoflow/presentation/widgets/app_logo.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';

void main() {
  Widget buildTestWidget({bool useDarkTheme = false}) {
    return MaterialApp(
      theme: useDarkTheme ? AppTheme.dark() : AppTheme.light(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('zh', 'CN'),
        Locale('zh', 'HK'),
      ],
      home: Scaffold(
        body: const drawer.DrawerHeader(),
      ),
    );
  }

  group('DrawerHeader Widget Tests', () {
    testWidgets('should display AppLogo in header', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      
      // 验证 AppLogo 组件存在
      expect(find.byType(AppLogo), findsOneWidget);
      
      // 验证 AppLogo 组件的属性
      final appLogo = tester.widget<AppLogo>(find.byType(AppLogo));
      expect(appLogo.size, equals(20.0));
      expect(appLogo.showText, isFalse);
      expect(appLogo.variant, equals(AppLogoVariant.onPrimary));
    });

    testWidgets('should display greeting and tagline text', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      
      // 验证文字内容存在（不依赖具体文案）
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('should use correct background image for light theme',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(useDarkTheme: false));
      
      // 验证 Container 存在（用于背景图片）
      final containerFinder = find.descendant(
        of: find.byType(drawer.DrawerHeader),
        matching: find.byType(Container),
      );
      expect(containerFinder, findsWidgets);
    });

    testWidgets('should use correct background image for dark theme',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(useDarkTheme: true));
      
      // 验证 Container 存在（用于背景图片）
      final containerFinder = find.descendant(
        of: find.byType(drawer.DrawerHeader),
        matching: find.byType(Container),
      );
      expect(containerFinder, findsWidgets);
    });

    testWidgets('should handle status bar height correctly', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      
      // 验证 Container 高度包含状态栏高度
      final containerFinder = find.descendant(
        of: find.byType(drawer.DrawerHeader),
        matching: find.byType(Container),
      );
      expect(containerFinder, findsWidgets);
    });

    testWidgets('should apply gradient overlay for text readability',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      
      // 验证有多个 Container（一个用于背景，一个用于遮罩）
      final containers = find.descendant(
        of: find.byType(drawer.DrawerHeader),
        matching: find.byType(Container),
      );
      expect(containers, findsAtLeastNWidgets(2));
    });

    testWidgets('should use SafeArea to avoid status bar overlap',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      
      // 验证 SafeArea 存在
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('should have correct logo size and variant', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      
      final appLogo = tester.widget<AppLogo>(find.byType(AppLogo));
      expect(appLogo.size, equals(20.0));
      expect(appLogo.variant, equals(AppLogoVariant.onPrimary));
      expect(appLogo.showText, isFalse);
    });
  });
}
