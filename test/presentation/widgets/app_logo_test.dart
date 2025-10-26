import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/presentation/widgets/app_logo.dart';

void main() {
  group('AppLogo', () {
    testWidgets('should render logo with text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const AppLogo(
              size: 48.0,
              showText: true,
            ),
          ),
        ),
      );

      // 验证容器存在
      expect(find.byType(Container), findsOneWidget);
      
      // 验证图标存在
      expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);
      
      // 验证文字存在
      expect(find.text('GranoFlow'), findsOneWidget);
    });

    testWidgets('should render logo without text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const AppLogo(
              size: 32.0,
              showText: false,
            ),
          ),
        ),
      );

      // 验证容器存在
      expect(find.byType(Container), findsOneWidget);
      
      // 验证图标存在
      expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);
      
      // 验证文字不存在
      expect(find.text('GranoFlow'), findsNothing);
    });

    testWidgets('should apply different variants', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                AppLogo(variant: AppLogoVariant.primary),
                AppLogo(variant: AppLogoVariant.secondary),
                AppLogo(variant: AppLogoVariant.onSurface),
                AppLogo(variant: AppLogoVariant.onPrimary),
              ],
            ),
          ),
        ),
      );

      // 验证所有变体都渲染了
      expect(find.byType(AppLogo), findsNWidgets(4));
    });

    testWidgets('should render with background in light theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: AppLogo(
              size: 40.0,
              showText: true,
              withBackground: true,
            ),
          ),
        ),
      );
      
      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should render with background in dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: AppLogo(
              size: 40.0,
              showText: true,
              withBackground: true,
            ),
          ),
        ),
      );
      
      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });
  });

  group('AppLogoIcon', () {
    testWidgets('should render icon only', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const AppLogoIcon(
              size: 24.0,
            ),
          ),
        ),
      );

      // 验证容器存在
      expect(find.byType(Container), findsOneWidget);
      
      // 验证图标存在
      expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);
    });

    testWidgets('should apply different variants', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                AppLogoIcon(variant: AppLogoVariant.primary),
                AppLogoIcon(variant: AppLogoVariant.secondary),
                AppLogoIcon(variant: AppLogoVariant.onSurface),
                AppLogoIcon(variant: AppLogoVariant.onPrimary),
              ],
            ),
          ),
        ),
      );

      // 验证所有变体都渲染了
      expect(find.byType(AppLogoIcon), findsNWidgets(4));
    });
  });
}
