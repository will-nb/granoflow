import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/theme/app_theme.dart';
import 'package:granoflow/presentation/widgets/gradient_page_scaffold.dart';

void main() {
  group('GradientPageScaffold Widget Tests', () {
    testWidgets('should render with required body parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const GradientPageScaffold(
            body: Center(child: Text('Test Body')),
          ),
        ),
      );

      expect(find.text('Test Body'), findsOneWidget);
    });

    testWidgets('should render with appBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: GradientPageScaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: AppBar(title: const Text('Test AppBar')),
            ),
            body: const Center(child: Text('Test Body')),
          ),
        ),
      );

      expect(find.text('Test AppBar'), findsOneWidget);
      expect(find.text('Test Body'), findsOneWidget);
    });

    testWidgets('should render with drawer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: GradientPageScaffold(
            appBar: AppBar(title: const Text('Test')),
            drawer: const Drawer(child: Text('Test Drawer')),
            body: const Center(child: Text('Test Body')),
          ),
        ),
      );

      // Open drawer using the scaffold state
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.text('Test Drawer'), findsOneWidget);
    });

    testWidgets('should render with floatingActionButton', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: GradientPageScaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
            body: const Center(child: Text('Test Body')),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should render with bottomNavigationBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const GradientPageScaffold(
            bottomNavigationBar: BottomAppBar(
              child: Text('Bottom Bar'),
            ),
            body: Center(child: Text('Test Body')),
          ),
        ),
      );

      expect(find.text('Bottom Bar'), findsOneWidget);
    });

    testWidgets('should use custom gradient when provided', (tester) async {
      const customGradient = LinearGradient(
        colors: [Colors.red, Colors.blue],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const GradientPageScaffold(
            gradient: customGradient,
            body: Center(child: Text('Test Body')),
          ),
        ),
      );

      // Find the Stack with fit: StackFit.expand (our background stack)
      // final allStacks = find.descendant(
      //   of: find.byType(Scaffold),
      //   matching: find.byType(Stack),
      // );
      
      Stack? backgroundStack;
      tester.allWidgets.forEach((widget) {
        if (widget is Stack && widget.fit == StackFit.expand) {
          backgroundStack = widget;
        }
      });

      expect(backgroundStack, isNotNull);
      
      // The gradient container should be the second child (index 1) in the Stack, wrapped in Opacity
      expect(backgroundStack!.children.length, greaterThanOrEqualTo(2));
      final opacityWidget = backgroundStack!.children[1] as Opacity;
      final gradientContainer = opacityWidget.child as Container;
      final decoration = gradientContainer.decoration as BoxDecoration;
      expect(decoration.gradient, equals(customGradient));
    });

    testWidgets('should use theme pageBackground gradient by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const GradientPageScaffold(
            body: Center(child: Text('Test Body')),
          ),
        ),
      );

      // Find the Stack with fit: StackFit.expand (our background stack)
      Stack? backgroundStack;
      tester.allWidgets.forEach((widget) {
        if (widget is Stack && widget.fit == StackFit.expand) {
          backgroundStack = widget;
        }
      });

      expect(backgroundStack, isNotNull);
      
      // The gradient container should be the second child (index 1) in the Stack, wrapped in Opacity
      expect(backgroundStack!.children.length, greaterThanOrEqualTo(2));
      final opacityWidget = backgroundStack!.children[1] as Opacity;
      final gradientContainer = opacityWidget.child as Container;
      final decoration = gradientContainer.decoration as BoxDecoration;
      expect(decoration.gradient, isNotNull);
    });

    testWidgets('should respect extendBodyBehindAppBar parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: GradientPageScaffold(
            extendBodyBehindAppBar: true,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: AppBar(title: const Text('Test AppBar')),
            ),
            body: const Center(child: Text('Test Body')),
          ),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.extendBodyBehindAppBar, isTrue);
    });

    testWidgets('should respect extendBody parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const GradientPageScaffold(
            extendBody: true,
            body: Center(child: Text('Test Body')),
          ),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.extendBody, isTrue);
    });

    testWidgets('should work in dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const GradientPageScaffold(
            body: Center(child: Text('Test Body')),
          ),
        ),
      );

      expect(find.text('Test Body'), findsOneWidget);

      // Find the Stack with fit: StackFit.expand (our background stack)
      Stack? backgroundStack;
      tester.allWidgets.forEach((widget) {
        if (widget is Stack && widget.fit == StackFit.expand) {
          backgroundStack = widget;
        }
      });

      expect(backgroundStack, isNotNull);
      
      // The gradient container should be the second child (index 1) in the Stack, wrapped in Opacity
      expect(backgroundStack!.children.length, greaterThanOrEqualTo(2));
      final opacityWidget = backgroundStack!.children[1] as Opacity;
      final gradientContainer = opacityWidget.child as Container;
      final decoration = gradientContainer.decoration as BoxDecoration;
      expect(decoration.gradient, isNotNull);
      
      // Verify background image exists (first child should be the image container)
      final imageContainer = backgroundStack!.children[0] as Container;
      final imageDecoration = imageContainer.decoration as BoxDecoration;
      expect(imageDecoration.image, isNotNull);
      expect(imageDecoration.image!.image, isA<AssetImage>());
      final assetImage = imageDecoration.image!.image as AssetImage;
      expect(assetImage.assetName, 'assets/images/background.dark.png');
    });
  });
}

