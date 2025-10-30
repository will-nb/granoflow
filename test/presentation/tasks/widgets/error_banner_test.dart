import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/presentation/tasks/widgets/error_banner.dart';

void main() {
  testWidgets('ErrorBanner renders message with error colors', (tester) async {
    const message = 'Something went wrong';

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
        home: const Scaffold(body: ErrorBanner(message: message)),
      ),
    );

    expect(find.text(message), findsOneWidget);
    final containerFinder = find.byWidgetPredicate(
      (widget) => widget is Container && widget.decoration is BoxDecoration,
    );
    final container = tester.widget<Container>(containerFinder);
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, isNotNull);
  });
}

