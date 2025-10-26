import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:granoflow/core/theme/app_theme.dart';
import 'package:granoflow/presentation/widgets/main_drawer.dart';
import 'package:granoflow/presentation/widgets/app_logo.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';

void main() {
  Widget buildTestWidget() {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(),
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
          body: const MainDrawer(),
        ),
      ),
    );
  }

  group('MainDrawer Widget Tests', () {
    testWidgets('should display AppLogo in header', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      
      // 验证 AppLogo 组件存在
      expect(find.byType(AppLogo), findsOneWidget);
      
      // 验证 AppLogo 组件的属性
      final appLogo = tester.widget<AppLogo>(find.byType(AppLogo));
      expect(appLogo.size, equals(28.0));
      expect(appLogo.showText, isFalse);
      expect(appLogo.variant, equals(AppLogoVariant.onPrimary));
    });

    testWidgets('should have correct logo size', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      
      final appLogo = tester.widget<AppLogo>(find.byType(AppLogo));
      expect(appLogo.size, equals(28.0));
    });

    testWidgets('should maintain layout spacing', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      
      // 验证 SizedBox 存在（Logo 和文字之间的间距）
      expect(find.byType(SizedBox), findsWidgets);
      
      // 验证 Row 布局存在
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('should display greeting text', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      
      // 验证文字内容存在
      expect(find.textContaining('GranoFlow'), findsOneWidget);
    });

    testWidgets('should use correct logo variant', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      
      final appLogo = tester.widget<AppLogo>(find.byType(AppLogo));
      expect(appLogo.variant, equals(AppLogoVariant.onPrimary));
    });

    testWidgets('should not show logo text', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      
      final appLogo = tester.widget<AppLogo>(find.byType(AppLogo));
      expect(appLogo.showText, isFalse);
    });
  });
}
