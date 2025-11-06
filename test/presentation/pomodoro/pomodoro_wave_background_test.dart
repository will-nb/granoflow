import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:granoflow/core/providers/pomodoro_animation_providers.dart';
import 'package:granoflow/core/theme/pomodoro_gradients.dart';
import 'package:granoflow/core/utils/gradient_composer.dart';
import 'package:granoflow/presentation/pomodoro/widgets/pomodoro_wave_background.dart';

class _PassiveTicker extends Ticker {
  _PassiveTicker(TickerCallback onTick) : super(onTick);

  @override
  TickerFuture start() => TickerFuture.complete();
}

class _TestWaveAnimationController extends WaveAnimationController {
  _TestWaveAnimationController({required WaveAnimationConfig config})
    : super(config: config);

  @override
  Ticker createTicker(TickerCallback onTick) => _PassiveTicker(onTick);
}

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

  testWidgets('PomodoroWaveBackground 在 light 模式下显示背景图片和动画层', (tester) async {
    final container = ProviderContainer(
      overrides: [
        waveAnimationControllerProvider.overrideWith((ref, args) {
          final config = ref.watch(waveAnimationConfigProvider(args));
          return _TestWaveAnimationController(config: config);
        }),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: PomodoroWaveBackground(state: PomodoroState.normal),
          ),
        ),
      ),
    );

    await tester.pump();

    // 验证 Stack 存在（找到 fit: StackFit.expand 的背景 Stack）
    Stack? backgroundStack;
    tester.allWidgets.forEach((widget) {
      if (widget is Stack && widget.fit == StackFit.expand) {
        backgroundStack = widget;
      }
    });
    expect(backgroundStack, isNotNull);
    
    // 验证背景图片 Container 存在
    final stack = backgroundStack!;
    expect(stack.children.length, greaterThanOrEqualTo(2));
    
    // 第一个子元素应该是背景图片 Container
    final imageContainer = stack.children[0] as Container;
    final imageDecoration = imageContainer.decoration as BoxDecoration;
    expect(imageDecoration.image, isNotNull);
    expect(imageDecoration.image!.image, isA<AssetImage>());
    final assetImage = imageDecoration.image!.image as AssetImage;
    expect(assetImage.assetName, 'assets/images/clock-background-light.png');
    expect(imageDecoration.image!.fit, BoxFit.cover);
    
    // 第二个子元素应该是 Opacity 包裹的动画层
    final opacityWidget = stack.children[1] as Opacity;
    expect(opacityWidget.opacity, 0.7);
    expect(find.byType(CustomPaint), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    container.dispose();
    await tester.pump();
  });

  testWidgets('PomodoroWaveBackground 在 dark 模式下显示背景图片和动画层', (tester) async {
    final container = ProviderContainer(
      overrides: [
        waveAnimationControllerProvider.overrideWith((ref, args) {
          final config = ref.watch(waveAnimationConfigProvider(args));
          return _TestWaveAnimationController(config: config);
        }),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: PomodoroWaveBackground(state: PomodoroState.normal),
          ),
        ),
      ),
    );

    await tester.pump();

    // 验证 Stack 存在（找到 fit: StackFit.expand 的背景 Stack）
    Stack? backgroundStack;
    tester.allWidgets.forEach((widget) {
      if (widget is Stack && widget.fit == StackFit.expand) {
        backgroundStack = widget;
      }
    });
    expect(backgroundStack, isNotNull);
    
    // 验证背景图片 Container 存在
    final stack = backgroundStack!;
    expect(stack.children.length, greaterThanOrEqualTo(2));
    
    // 第一个子元素应该是背景图片 Container
    final imageContainer = stack.children[0] as Container;
    final imageDecoration = imageContainer.decoration as BoxDecoration;
    expect(imageDecoration.image, isNotNull);
    expect(imageDecoration.image!.image, isA<AssetImage>());
    final assetImage = imageDecoration.image!.image as AssetImage;
    expect(assetImage.assetName, 'assets/images/clock-background-dark.png');
    expect(imageDecoration.image!.fit, BoxFit.cover);
    
    // 第二个子元素应该是 Opacity 包裹的动画层
    final opacityWidget = stack.children[1] as Opacity;
    expect(opacityWidget.opacity, 0.7);
    expect(find.byType(CustomPaint), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    container.dispose();
    await tester.pump();
  });
}
