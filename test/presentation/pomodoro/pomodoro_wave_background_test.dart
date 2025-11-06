import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:granoflow/core/theme/pomodoro_gradients.dart';
import 'package:granoflow/core/utils/gradient_composer.dart';
import 'package:granoflow/presentation/pomodoro/widgets/pomodoro_wave_background.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Composite wave gradient', () {
    test('light normal gradient包含多层纹理', () {
      final composite = PomodoroGradients.getWaveGradient(
        brightness: Brightness.light,
        state: PomodoroState.normal,
      );

      expect(composite.layers.isNotEmpty, isTrue);
      expect(
        composite.layersOf<WaveTextureLayer>().isNotEmpty,
        isTrue,
        reason: '白天模式应包含泡沫纹理层',
      );
    });

    test('dark normal gradient包含粒子层', () {
      final composite = PomodoroGradients.getWaveGradient(
        brightness: Brightness.dark,
        state: PomodoroState.normal,
      );

      expect(
        composite.layersOf<WaveParticleLayer>().isNotEmpty,
        isTrue,
        reason: '夜间模式应包含星点粒子层',
      );
    });
  });

  testWidgets('PomodoroWaveBackground 在 light 模式下使用正确的背景图片', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          body: PomodoroWaveBackground(state: PomodoroState.normal),
        ),
      ),
    );

    await tester.pump();

    // 验证 Container 存在
    expect(find.byType(Container), findsOneWidget);
    
    // 验证 DecorationImage 存在
    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.image, isNotNull);
    expect(decoration.image!.image, isA<AssetImage>());
    
    final assetImage = decoration.image!.image as AssetImage;
    expect(assetImage.assetName, 'assets/images/clock-background-light.png');
    expect(decoration.image!.fit, BoxFit.cover);
  });

  testWidgets('PomodoroWaveBackground 在 dark 模式下使用正确的背景图片', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: PomodoroWaveBackground(state: PomodoroState.normal),
        ),
      ),
    );

    await tester.pump();

    // 验证 Container 存在
    expect(find.byType(Container), findsOneWidget);
    
    // 验证 DecorationImage 存在
    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.image, isNotNull);
    expect(decoration.image!.image, isA<AssetImage>());
    
    final assetImage = decoration.image!.image as AssetImage;
    expect(assetImage.assetName, 'assets/images/clock-background-dark.png');
    expect(decoration.image!.fit, BoxFit.cover);
  });
}
