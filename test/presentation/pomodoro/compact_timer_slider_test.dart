import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/presentation/pomodoro/widgets/compact_timer_slider.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

void main() {
  Widget _buildTestApp(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('显示默认 HH:MM 标签', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        const CompactTimerSlider(elapsed: Duration(minutes: 75), diameter: 220),
      ),
    );

    expect(find.text('01:15'), findsOneWidget);
    expect(find.byType(SleekCircularSlider), findsOneWidget);
  });

  testWidgets('支持自定义 innerWidget', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        CompactTimerSlider(
          elapsed: const Duration(minutes: 10),
          diameter: 200,
          innerBuilder: (context, _) => const Text('Custom'),
        ),
      ),
    );

    expect(find.text('Custom'), findsOneWidget);
    expect(find.textContaining('00:'), findsNothing);
  });

  testWidgets('进度值与渐变参数可定制', (tester) async {
    const elapsed = Duration(minutes: 5, seconds: 30);
    final palette = CompactTimerPalette.paused();

    await tester.pumpWidget(
      _buildTestApp(
        CompactTimerSlider(elapsed: elapsed, diameter: 210, palette: palette),
      ),
    );

    final slider = tester.widget<SleekCircularSlider>(
      find.byType(SleekCircularSlider),
    );

    expect(slider.initialValue, closeTo(5.5, 0.001));
    final appearance = slider.appearance;
    final colors = appearance.customColors;
    expect(colors?.progressBarColors, palette.progressGradient);
  });
}
