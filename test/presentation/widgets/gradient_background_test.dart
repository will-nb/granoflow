import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:granoflow/core/theme/app_gradients.dart';
import 'package:granoflow/presentation/widgets/gradient_background.dart';

void main() {
  group('GradientBackground', () {
    testWidgets('should render with default gradient type', (tester) async {
      const child = Text('Test Content');
      
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppGradientsExtension.light],
          ),
          home: const Scaffold(
            body: GradientBackground(
              child: child,
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('should render with custom gradient', (tester) async {
      const child = Text('Test Content');
      final customGradient = AppGradients.mintLake;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppGradientsExtension.light],
          ),
          home: Scaffold(
            body: GradientBackground(
              customGradient: customGradient,
              child: child,
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('should apply opacity correctly', (tester) async {
      const child = Text('Test Content');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppGradientsExtension.light],
          ),
          home: const Scaffold(
            body: GradientBackground(
              opacity: 0.5,
              child: child,
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byType(Opacity), findsOneWidget);
    });
  });

  group('GradientCard', () {
    testWidgets('should render with default properties', (tester) async {
      const child = Text('Card Content');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppGradientsExtension.light],
          ),
          home: const Scaffold(
            body: GradientCard(
              child: child,
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('should apply custom margin and padding', (tester) async {
      const child = Text('Card Content');
      const margin = EdgeInsets.all(16.0);
      const padding = EdgeInsets.all(24.0);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppGradientsExtension.light],
          ),
          home: const Scaffold(
            body: GradientCard(
              margin: margin,
              padding: padding,
              child: child,
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('should apply custom border radius', (tester) async {
      const child = Text('Card Content');
      const borderRadius = BorderRadius.all(Radius.circular(20.0));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppGradientsExtension.light],
          ),
          home: const Scaffold(
            body: GradientCard(
              borderRadius: borderRadius,
              child: child,
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });
  });

  group('GradientButton', () {
    testWidgets('should render enabled button', (tester) async {
      const child = Text('Button');
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppGradientsExtension.light],
          ),
          home: Scaffold(
            body: GradientButton(
              onPressed: () => tapped = true,
              child: child,
            ),
          ),
        ),
      );

      expect(find.text('Button'), findsOneWidget);
      expect(find.byType(GradientButton), findsOneWidget);

      // 测试点击
      await tester.tap(find.byType(GradientButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('should render disabled button', (tester) async {
      const child = Text('Button');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppGradientsExtension.light],
          ),
          home: const Scaffold(
            body: GradientButton(
              onPressed: null,
              disabled: true,
              child: child,
            ),
          ),
        ),
      );

      expect(find.text('Button'), findsOneWidget);
      expect(find.byType(GradientButton), findsOneWidget);
    });

    testWidgets('should apply custom padding', (tester) async {
      const child = Text('Button');
      const padding = EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppGradientsExtension.light],
          ),
          home: Scaffold(
            body: GradientButton(
              onPressed: () {},
              padding: padding,
              child: child,
            ),
          ),
        ),
      );

      expect(find.text('Button'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });
  });

  group('GradientPageBackground', () {
    testWidgets('should render with safe area', (tester) async {
      const child = Text('Page Content');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppGradientsExtension.light],
          ),
          home: const Scaffold(
            body: GradientPageBackground(
              safeArea: true,
              child: child,
            ),
          ),
        ),
      );

      expect(find.text('Page Content'), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('should render without safe area', (tester) async {
      const child = Text('Page Content');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppGradientsExtension.light],
          ),
          home: const Scaffold(
            body: GradientPageBackground(
              safeArea: false,
              child: child,
            ),
          ),
        ),
      );

      expect(find.text('Page Content'), findsOneWidget);
      expect(find.byType(SafeArea), findsNothing);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('should use custom gradient', (tester) async {
      const child = Text('Page Content');
      final customGradient = AppGradients.oceanDepth;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppGradientsExtension.light],
          ),
          home: Scaffold(
            body: GradientPageBackground(
              customGradient: customGradient,
              child: child,
            ),
          ),
        ),
      );

      expect(find.text('Page Content'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });
  });

  group('GradientBlendMode', () {
    testWidgets('should render with blend mode', (tester) async {
      const child = Text('Blend Content');

      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: GradientBlendMode(
              blendMode: BlendMode.srcOver,
              child: child,
            ),
          ),
        ),
      );

      expect(find.text('Blend Content'), findsOneWidget);
      expect(find.byType(GradientBlendMode), findsOneWidget);
    });
  });
}
