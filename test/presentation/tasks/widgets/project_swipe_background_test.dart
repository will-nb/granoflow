import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/presentation/tasks/widgets/project_swipe_background.dart';

void main() {
  testWidgets('projectSwipeBackground renders icon and label', (tester) async {
    const label = 'Archive';
    final widget = projectSwipeBackground(
      color: Colors.blue,
      icon: Icons.archive_outlined,
      label: label,
      alignment: Alignment.center,
    );

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

    expect(find.text(label), findsOneWidget);
    expect(find.byIcon(Icons.archive_outlined), findsOneWidget);
  });
}

