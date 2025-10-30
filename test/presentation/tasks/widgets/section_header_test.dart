import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/presentation/tasks/widgets/section_header.dart';

void main() {
  testWidgets('SectionHeader displays title and subtitle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SectionHeader(title: 'Today', subtitle: '3 tasks'),
        ),
      ),
    );

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('3 tasks'), findsOneWidget);
  });
}

