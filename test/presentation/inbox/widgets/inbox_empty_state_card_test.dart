import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/presentation/inbox/widgets/inbox_empty_state_card.dart';

void main() {
  testWidgets('InboxEmptyStateCard renders title, message and action', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InboxEmptyStateCard(
            title: 'Inbox Zero',
            message: 'All caught up!',
            actionLabel: 'Go to Tasks',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Inbox Zero'), findsOneWidget);
    expect(find.text('All caught up!'), findsOneWidget);
    expect(find.text('Go to Tasks'), findsOneWidget);

    await tester.tap(find.text('Go to Tasks'));
    expect(tapped, isTrue);
  });
}

