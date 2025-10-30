import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/presentation/tasks/widgets/empty_placeholder.dart';

void main() {
  testWidgets('EmptyPlaceholder shows message', (tester) async {
    const message = 'Nothing here yet';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: EmptyPlaceholder(message: message)),
      ),
    );

    expect(find.text(message), findsOneWidget);
  });
}

