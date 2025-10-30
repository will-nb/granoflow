import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/presentation/tasks/widgets/empty_section_hint.dart';

void main() {
  testWidgets('EmptySectionHint displays provided message centered', (tester) async {
    const message = 'No tasks yet';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: EmptySectionHint(message: message)),
      ),
    );

    expect(find.text(message), findsOneWidget);
    final text = tester.widget<Text>(find.text(message));
    expect(text.textAlign, TextAlign.center);
  });
}

