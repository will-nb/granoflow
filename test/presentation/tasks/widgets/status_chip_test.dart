import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/presentation/tasks/widgets/status_chip.dart';

void main() {
  testWidgets('StatusChip renders label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusChip(label: 'Overdue', color: Colors.red),
        ),
      ),
    );

    expect(find.text('Overdue'), findsOneWidget);
    expect(find.byType(Chip), findsOneWidget);
  });
}

