import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/presentation/tasks/widgets/depth_bars.dart';

void main() {
  testWidgets('DepthBars renders bars based on depth', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DepthBars(depth: 3)),
      ),
    );

    final barsFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Container && widget.constraints?.maxWidth == 4 && widget.constraints?.minHeight == 40,
    );
    expect(barsFinder, findsNWidgets(3));
  });

  testWidgets('DepthBars renders placeholder when depth is zero', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DepthBars(depth: 0)),
      ),
    );

    expect(find.byType(SizedBox), findsWidgets);
  });
}

