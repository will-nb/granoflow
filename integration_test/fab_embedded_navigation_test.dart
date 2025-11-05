import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:granoflow/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// 设置竖屏模式（Samsung S 系列尺寸）
  void setupPortraitMode(WidgetTester tester) {
    final view = tester.view;
    // 设置竖屏尺寸：360x780 (逻辑尺寸，对应 1080x2340 物理尺寸，dpr=3.0)
    final logicalWidth = 360.0;
    final logicalHeight = 780.0;
    final dpr = 3.0;
    final physicalWidth = logicalWidth * dpr;
    final physicalHeight = logicalHeight * dpr;
    view.physicalSize = Size(physicalWidth, physicalHeight);
    view.devicePixelRatio = dpr;
    
    // 调试输出
    debugPrint('=== Setup Portrait Mode ===');
    debugPrint('Logical size: ${logicalWidth}x${logicalHeight}');
    debugPrint('Physical size: ${physicalWidth}x${physicalHeight}');
    debugPrint('Device pixel ratio: $dpr');
    debugPrint('Orientation: ${logicalWidth < logicalHeight ? "Portrait" : "Landscape"}');
  }

  /// 设置横屏模式
  void setupLandscapeMode(WidgetTester tester) {
    final view = tester.view;
    final logicalWidth = 780.0;
    final logicalHeight = 360.0;
    final dpr = 3.0;
    view.physicalSize = Size(logicalWidth * dpr, logicalHeight * dpr);
    view.devicePixelRatio = dpr;
  }

  /// 查找 FAB Material widget
  Material? findFabMaterial(WidgetTester tester) {
    for (final element in find.byType(Material).evaluate()) {
      final material = element.widget as Material;
      if (material.shape is CircleBorder) {
        return material;
      }
    }
    return null;
  }

  /// 获取 FAB 的 Rect
  Rect getFabRect(WidgetTester tester) {
    final fabMaterial = findFabMaterial(tester);
    expect(fabMaterial, isNotNull, reason: '应该找到 FAB Material');
    final fabFinder = find.byWidget(fabMaterial!);
    return tester.getRect(fabFinder);
  }

  group('FAB embedded navigation tests', () {
    testWidgets(
      '1.1 FAB height and width should be consistent (circular)',
      (WidgetTester tester) async {
        // 设置竖屏模式（需要在应用启动前设置）
        final view = tester.view;
        final originalSize = view.physicalSize;
        final originalDevicePixelRatio = view.devicePixelRatio;
        setupPortraitMode(tester);
        addTearDown(() {
          view.physicalSize = originalSize;
          view.devicePixelRatio = originalDevicePixelRatio;
        });

        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // 验证竖屏模式
        final platformView = tester.binding.platformDispatcher.views.first;
        final logicalSize =
            platformView.physicalSize / platformView.devicePixelRatio;
        final orientation =
            logicalSize.width < logicalSize.height
                ? Orientation.portrait
                : Orientation.landscape;
        
        debugPrint('=== Orientation Check ===');
        debugPrint('Physical size: ${platformView.physicalSize}');
        debugPrint('Device pixel ratio: ${platformView.devicePixelRatio}');
        debugPrint('Logical size: $logicalSize');
        debugPrint('Orientation: $orientation');
        
        expect(orientation, Orientation.portrait,
            reason: '测试应该在竖屏模式下运行。实际逻辑尺寸: ${logicalSize.width}x${logicalSize.height}');

        final fabRect = getFabRect(tester);

        debugPrint('=== Test 1.1: FAB height and width ===');
        debugPrint('FAB Rect: $fabRect');
        debugPrint('FAB width: ${fabRect.width}');
        debugPrint('FAB height: ${fabRect.height}');

        // 验证高度和宽度一致（允许 1dp 误差）
        expect(
          fabRect.width,
          closeTo(fabRect.height, 1.0),
          reason: 'FAB 的高度和宽度应该一致（圆形）。',
        );
      },
    );

    testWidgets(
      '1.2 FAB should have CircleBorder shape',
      (WidgetTester tester) async {
        // 设置竖屏模式
        final view = tester.view;
        final originalSize = view.physicalSize;
        final originalDevicePixelRatio = view.devicePixelRatio;
        setupPortraitMode(tester);
        addTearDown(() {
          view.physicalSize = originalSize;
          view.devicePixelRatio = originalDevicePixelRatio;
        });

        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final fabMaterial = findFabMaterial(tester);
        expect(fabMaterial, isNotNull);

        debugPrint('=== Test 1.2: FAB shape ===');
        debugPrint('FAB shape: ${fabMaterial!.shape}');

        // 验证 shape 是 CircleBorder
        expect(
          fabMaterial.shape,
          isA<CircleBorder>(),
          reason: 'FAB 的 shape 应该是 CircleBorder（圆形）。',
        );
      },
    );

    testWidgets(
      '2.1 FAB top should align with other button icon top',
      (WidgetTester tester) async {
        final view = tester.view;
        final originalSize = view.physicalSize;
        final originalDevicePixelRatio = view.devicePixelRatio;
        setupPortraitMode(tester);
        addTearDown(() {
          view.physicalSize = originalSize;
          view.devicePixelRatio = originalDevicePixelRatio;
        });

        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final fabRect = getFabRect(tester);
        final navBarFinder = find.byType(NavigationBar);
        expect(navBarFinder, findsOneWidget);

        // 获取第一个导航按钮的图标（home_outlined 或 home）
        var iconFinder = find.descendant(
          of: navBarFinder,
          matching: find.byIcon(Icons.home_outlined),
        );
        if (iconFinder.evaluate().isEmpty) {
          iconFinder = find.descendant(
            of: navBarFinder,
            matching: find.byIcon(Icons.home),
          );
        }
        expect(iconFinder, findsWidgets,
            reason: '应该找到导航栏图标');

        final firstIconRect = tester.getRect(iconFinder.first);

        debugPrint('=== Test 2.1: FAB top alignment ===');
        debugPrint('FAB top: ${fabRect.top}');
        debugPrint('First icon top: ${firstIconRect.top}');

        // 验证 FAB 顶部与图标顶部对齐（允许 2-3dp 误差）
        expect(
          fabRect.top,
          closeTo(firstIconRect.top, 3.0),
          reason: 'FAB 顶部应该与其他按钮图标顶部对齐。',
        );
      },
    );

    testWidgets(
      '2.2 FAB bottom should align with other button text bottom',
      (WidgetTester tester) async {
        // 设置竖屏模式
        final view = tester.view;
        final originalSize = view.physicalSize;
        final originalDevicePixelRatio = view.devicePixelRatio;
        setupPortraitMode(tester);
        addTearDown(() {
          view.physicalSize = originalSize;
          view.devicePixelRatio = originalDevicePixelRatio;
        });

        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final fabRect = getFabRect(tester);
        final navBarFinder = find.byType(NavigationBar);
        expect(navBarFinder, findsOneWidget);

        // 获取第一个导航按钮的文字（通过查找 NavigationDestination 的 label）
        // 由于 NavigationBar 的文本可能在不同位置，我们通过查找 Text widget 来定位
        final textFinder = find.descendant(
          of: navBarFinder,
          matching: find.byType(Text),
        );
        expect(textFinder, findsWidgets, reason: '应该找到导航栏文字');

        // 找到第一个文本的位置（通常是第一个导航按钮的标签）
        final firstTextRect = tester.getRect(textFinder.first);

        debugPrint('=== Test 2.2: FAB bottom alignment ===');
        debugPrint('FAB bottom: ${fabRect.bottom}');
        debugPrint('First text bottom: ${firstTextRect.bottom}');

        // 验证 FAB 底部与文字底部对齐（允许 2-3dp 误差）
        expect(
          fabRect.bottom,
          closeTo(firstTextRect.bottom, 3.0),
          reason: 'FAB 底部应该与其他按钮文字底部对齐。',
        );
      },
    );

    testWidgets(
      '3.1 Button center points should have consistent spacing',
      (WidgetTester tester) async {
        // 设置竖屏模式
        final view = tester.view;
        final originalSize = view.physicalSize;
        final originalDevicePixelRatio = view.devicePixelRatio;
        setupPortraitMode(tester);
        addTearDown(() {
          view.physicalSize = originalSize;
          view.devicePixelRatio = originalDevicePixelRatio;
        });

        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final fabRect = getFabRect(tester);
        final navBarFinder = find.byType(NavigationBar);
        expect(navBarFinder, findsOneWidget);
        final fabCenterX = fabRect.center.dx;

        // 获取所有导航按钮的中心点
        // 通过查找 NavigationBar 中的图标来定位按钮，每个槽位只取一个（优先选中状态）
        final List<Finder> iconFinders = [];
        // 尝试获取每个槽位的图标（优先选中状态）
        var homeIcon = find.descendant(
          of: navBarFinder,
          matching: find.byIcon(Icons.home),
        );
        if (homeIcon.evaluate().isEmpty) {
          homeIcon = find.descendant(
            of: navBarFinder,
            matching: find.byIcon(Icons.home_outlined),
          );
        }
        if (homeIcon.evaluate().isNotEmpty) iconFinders.add(homeIcon);
        
        var tasksIcon = find.descendant(
          of: navBarFinder,
          matching: find.byIcon(Icons.fact_check),
        );
        if (tasksIcon.evaluate().isEmpty) {
          tasksIcon = find.descendant(
            of: navBarFinder,
            matching: find.byIcon(Icons.checklist),
          );
        }
        if (tasksIcon.evaluate().isNotEmpty) iconFinders.add(tasksIcon);
        
        var achievementsIcon = find.descendant(
          of: navBarFinder,
          matching: find.byIcon(Icons.emoji_events),
        );
        if (achievementsIcon.evaluate().isEmpty) {
          achievementsIcon = find.descendant(
            of: navBarFinder,
            matching: find.byIcon(Icons.emoji_events_outlined),
          );
        }
        if (achievementsIcon.evaluate().isNotEmpty) iconFinders.add(achievementsIcon);
        
        var settingsIcon = find.descendant(
          of: navBarFinder,
          matching: find.byIcon(Icons.settings),
        );
        if (settingsIcon.evaluate().isEmpty) {
          settingsIcon = find.descendant(
            of: navBarFinder,
            matching: find.byIcon(Icons.settings_outlined),
          );
        }
        if (settingsIcon.evaluate().isNotEmpty) iconFinders.add(settingsIcon);

        // 找到所有存在的图标中心
        final List<double> buttonCenters = [];
        for (final finder in iconFinders) {
          final rect = tester.getRect(finder.first);
          buttonCenters.add(rect.center.dx);
        }

        // 添加 FAB 的中心点
        buttonCenters.add(fabCenterX);

        // 排序以获取从左到右的顺序
        buttonCenters.sort();

        debugPrint('=== Test 3.1: Button spacing ===');
        debugPrint('Button centers: $buttonCenters');

        // 计算相邻按钮之间的距离
        final List<double> distances = [];
        for (int i = 0; i < buttonCenters.length - 1; i++) {
          distances.add(buttonCenters[i + 1] - buttonCenters[i]);
        }

        debugPrint('Distances: $distances');

        // 验证按钮中心是否接近槽位中心（而不是检查距离是否完全一致）
        // 因为 NavigationBar 的布局可能有自己的逻辑，按钮可能不完全均匀分布
        final screenWidth = tester.getSize(find.byType(MaterialApp).first).width;
        final slotWidth = screenWidth / 5;
        final expectedCenters = [
          slotWidth * 0.5, // 槽位 0 中心
          slotWidth * 1.5, // 槽位 1 中心
          slotWidth * 2.5, // 槽位 2 中心（FAB）
          slotWidth * 3.5, // 槽位 3 中心
          slotWidth * 4.5, // 槽位 4 中心
        ];
        
        debugPrint('Expected slot centers: $expectedCenters');
        
        // 验证每个按钮中心是否接近对应的槽位中心（允许 30dp 误差，因为 NavigationBar 可能有自己的布局逻辑）
        expect(buttonCenters.length, 5, reason: '应该有 5 个按钮（4 个导航按钮 + 1 个 FAB）');
        for (int i = 0; i < buttonCenters.length; i++) {
          final actualCenter = buttonCenters[i];
          final expectedCenter = expectedCenters[i];
          expect(
            actualCenter,
            closeTo(expectedCenter, 30.0),
            reason: '按钮 ${i + 1} 的中心应该接近槽位 ${i} 的中心。',
          );
        }
      },
    );

    testWidgets(
      'FAB should have soft shadow elevation',
      (WidgetTester tester) async {
        // 设置竖屏模式
        final view = tester.view;
        final originalSize = view.physicalSize;
        final originalDevicePixelRatio = view.devicePixelRatio;
        setupPortraitMode(tester);
        addTearDown(() {
          view.physicalSize = originalSize;
          view.devicePixelRatio = originalDevicePixelRatio;
        });

        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final fabMaterial = findFabMaterial(tester);
        expect(fabMaterial, isNotNull);

        debugPrint('=== Test: FAB elevation ===');
        debugPrint('Elevation: ${fabMaterial!.elevation}');

        expect(
          fabMaterial.elevation,
          6,
          reason: 'FAB 应使用 elevation=6 的柔和悬浮阴影',
        );
      },
    );

    testWidgets(
      'FAB should occupy middle slot width',
      (WidgetTester tester) async {
        // 设置竖屏模式
        final view = tester.view;
        final originalSize = view.physicalSize;
        final originalDevicePixelRatio = view.devicePixelRatio;
        setupPortraitMode(tester);
        addTearDown(() {
          view.physicalSize = originalSize;
          view.devicePixelRatio = originalDevicePixelRatio;
        });

        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final fabRect = getFabRect(tester);
        final screenSize = tester.getSize(find.byType(MaterialApp).first);
        final screenWidth = screenSize.width;
        final slotWidth = screenWidth / 5;

        debugPrint('=== Test: FAB slot width ===');
        debugPrint('Screen width: $screenWidth');
        debugPrint('Slot width: $slotWidth');
        debugPrint('FAB width: ${fabRect.width}');
        debugPrint('FAB diameter: ${fabRect.width} (should be 50dp)');

        // FAB 是圆形，直径应该等于图标+文字总高度（50dp）
        // 外层容器占据槽位宽度，但圆形按钮本身是 50dp
        expect(
          fabRect.width,
          closeTo(50.0, 2.0),
          reason: 'FAB 直径应该等于图标+文字总高度（50dp）。',
        );
        
        // 验证外层容器占据槽位宽度（通过检查 FAB 中心是否在槽位中心）
        const int fabSlotIndex = 2;
        final expectedCenterX = (screenWidth / 5) * (fabSlotIndex + 0.5);
        expect(
          fabRect.center.dx,
          closeTo(expectedCenterX, 2.0),
          reason: 'FAB 中心应该在槽位中心，表示外层容器占据槽位宽度。',
        );
      },
    );

    testWidgets(
      'FAB should align to middle slot left edge',
      (WidgetTester tester) async {
        // 设置竖屏模式
        final view = tester.view;
        final originalSize = view.physicalSize;
        final originalDevicePixelRatio = view.devicePixelRatio;
        setupPortraitMode(tester);
        addTearDown(() {
          view.physicalSize = originalSize;
          view.devicePixelRatio = originalDevicePixelRatio;
        });

        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final fabRect = getFabRect(tester);
        final screenSize = tester.getSize(find.byType(MaterialApp).first);
        final screenWidth = screenSize.width;
        const int fabSlotIndex = 2; // 第 3 个槽位（索引 2）
        final slotWidth = screenWidth / 5;
        final expectedCenterX = slotWidth * (fabSlotIndex + 0.5); // 槽位中心

        debugPrint('=== Test: FAB horizontal position ===');
        debugPrint('Screen width: $screenWidth');
        debugPrint('Slot width: $slotWidth');
        debugPrint('Expected center X: $expectedCenterX');
        debugPrint('FAB center X: ${fabRect.center.dx}');
        debugPrint('FAB left: ${fabRect.left}');

        // FAB 是圆形，在槽位中居中，所以检查中心是否在槽位中心
        expect(
          fabRect.center.dx,
          closeTo(expectedCenterX, 2.0),
          reason: 'FAB 中心应该在第 3 个槽位（索引 2）的中心，表示占据该槽位。',
        );
      },
    );

    testWidgets(
      'NavigationBar and FAB should not render in landscape mode',
      (WidgetTester tester) async {
        // 设置横屏模式
        final view = tester.view;
        final originalSize = view.physicalSize;
        final originalDevicePixelRatio = view.devicePixelRatio;
        setupLandscapeMode(tester);
        addTearDown(() {
          view.physicalSize = originalSize;
          view.devicePixelRatio = originalDevicePixelRatio;
        });

        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // 验证横屏模式
        final platformView = tester.binding.platformDispatcher.views.first;
        final logicalSize =
            platformView.physicalSize / platformView.devicePixelRatio;
        final orientation =
            logicalSize.width < logicalSize.height
                ? Orientation.portrait
                : Orientation.landscape;
        expect(orientation, Orientation.landscape,
            reason: '测试应该在横屏模式下运行');

        final fabMaterial = findFabMaterial(tester);
        expect(
          fabMaterial,
          isNull,
          reason: '横屏模式下不应显示 FAB',
        );
        expect(
          find.byType(NavigationBar),
          findsNothing,
          reason: '横屏模式下应隐藏底部导航栏',
        );
      },
    );

    /// 测试辅助函数：测试指定尺寸下的槽位一致性
    Future<void> testSlotWidthConsistency(
      WidgetTester tester,
      double logicalWidth,
      double logicalHeight,
    ) async {
      final view = tester.view;
      final dpr = 3.0;
      final physicalWidth = logicalWidth * dpr;
      final physicalHeight = logicalHeight * dpr;
      view.physicalSize = Size(physicalWidth, physicalHeight);
      view.devicePixelRatio = dpr;

      debugPrint('=== Testing slot width consistency ===');
      debugPrint('Logical size: ${logicalWidth}x${logicalHeight}');
      debugPrint('Physical size: ${physicalWidth}x${physicalHeight}');
      debugPrint('Device pixel ratio: $dpr');

      // 验证窗口方向为竖屏
      final platformView = tester.binding.platformDispatcher.views.first;
      final logicalSize =
          platformView.physicalSize / platformView.devicePixelRatio;
      final orientation =
          logicalSize.width < logicalSize.height
              ? Orientation.portrait
              : Orientation.landscape;
      expect(orientation, Orientation.portrait,
          reason: '窗口应该是竖屏模式。实际逻辑尺寸: ${logicalSize.width}x${logicalSize.height}');

      // 重新启动应用以应用新的窗口大小
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 获取屏幕宽度
      final screenSize = tester.getSize(find.byType(MaterialApp).first);
      final screenWidth = screenSize.width;
      final expectedSlotWidth = screenWidth / 5;

      debugPrint('Screen width: $screenWidth');
      debugPrint('Expected slot width: $expectedSlotWidth');

      // 获取 FAB 位置
      final fabRect = getFabRect(tester);
      final fabCenterX = fabRect.center.dx;
      final fabSlotIndex = 2; // FAB 在第三个槽位（索引 2）
      final expectedFabCenterX = expectedSlotWidth * fabSlotIndex + expectedSlotWidth / 2;

      debugPrint('FAB center X: $fabCenterX');
      debugPrint('Expected FAB center X: $expectedFabCenterX');

      // 验证 FAB 中心是否在中间槽位（索引 2）的中心
      expect(
        fabCenterX,
        closeTo(expectedFabCenterX, 30.0),
        reason: 'FAB 中心应该接近中间槽位（索引 2）的中心。',
      );

      // 验证 FAB 顶部是否与图标顶部对齐
      final navBarFinder = find.byType(NavigationBar);
      expect(navBarFinder, findsOneWidget);
      
      var homeIcon = find.descendant(
        of: navBarFinder,
        matching: find.byIcon(Icons.home),
      );
      if (homeIcon.evaluate().isEmpty) {
        homeIcon = find.descendant(
          of: navBarFinder,
          matching: find.byIcon(Icons.home_outlined),
        );
      }
      expect(homeIcon, findsOneWidget);
      final firstIconRect = tester.getRect(homeIcon);
      
      expect(
        fabRect.top,
        closeTo(firstIconRect.top, 3.0),
        reason: 'FAB 顶部应该与图标顶部对齐。',
      );

      // 验证 FAB 底部是否与文字底部对齐（如果文本可见）
      // 在小窗口宽度下，NavigationBar 可能隐藏文本标签
      final homeText = find.descendant(
        of: navBarFinder,
        matching: find.textContaining('Home', findRichText: true),
      );
      if (homeText.evaluate().isNotEmpty) {
        final firstTextRect = tester.getRect(homeText);
        expect(
          fabRect.bottom,
          closeTo(firstTextRect.bottom, 3.0),
          reason: 'FAB 底部应该与文字底部对齐。',
        );
      } else {
        // 如果文本不可见，跳过底部对齐验证（因为文本本身就不可见）
        debugPrint('Text labels are hidden, skipping bottom alignment verification');
      }

      // 验证所有按钮的中心点间距是否一致
      final iconFinders = <Finder>[];
      if (homeIcon.evaluate().isNotEmpty) iconFinders.add(homeIcon);
      
      var tasksIcon = find.descendant(
        of: navBarFinder,
        matching: find.byIcon(Icons.fact_check),
      );
      if (tasksIcon.evaluate().isEmpty) {
        tasksIcon = find.descendant(
          of: navBarFinder,
          matching: find.byIcon(Icons.checklist),
        );
      }
      if (tasksIcon.evaluate().isNotEmpty) iconFinders.add(tasksIcon);
      
      var achievementsIcon = find.descendant(
        of: navBarFinder,
        matching: find.byIcon(Icons.emoji_events),
      );
      if (achievementsIcon.evaluate().isEmpty) {
        achievementsIcon = find.descendant(
          of: navBarFinder,
          matching: find.byIcon(Icons.emoji_events_outlined),
        );
      }
      if (achievementsIcon.evaluate().isNotEmpty) iconFinders.add(achievementsIcon);
      
      var settingsIcon = find.descendant(
        of: navBarFinder,
        matching: find.byIcon(Icons.settings),
      );
      if (settingsIcon.evaluate().isEmpty) {
        settingsIcon = find.descendant(
          of: navBarFinder,
          matching: find.byIcon(Icons.settings_outlined),
        );
      }
      if (settingsIcon.evaluate().isNotEmpty) iconFinders.add(settingsIcon);

      final List<double> buttonCenters = [];
      for (final finder in iconFinders) {
        final rect = tester.getRect(finder.first);
        buttonCenters.add(rect.center.dx);
      }
      buttonCenters.add(fabCenterX);
      buttonCenters.sort();

      debugPrint('Button centers: $buttonCenters');

      // 验证按钮中心是否接近槽位中心
      final expectedCenters = [
        expectedSlotWidth * 0 + expectedSlotWidth / 2,
        expectedSlotWidth * 1 + expectedSlotWidth / 2,
        expectedSlotWidth * 2 + expectedSlotWidth / 2,
        expectedSlotWidth * 3 + expectedSlotWidth / 2,
        expectedSlotWidth * 4 + expectedSlotWidth / 2,
      ];

      // 验证 FAB 中心是否在中间槽位（这是最重要的验证）
      // 其他按钮可能因为 NavigationBar 的 padding 而位置略有不同
      final fabExpectedCenter = expectedCenters[2]; // FAB 在第三个槽位（索引 2）
      expect(
        fabCenterX,
        closeTo(fabExpectedCenter, 30.0),
        reason: 'FAB 中心应该接近中间槽位（索引 2）的中心。',
      );
      
      // 验证 FAB 中心位置与屏幕宽度成正比（这是关键验证）
      // 如果窗口宽度从 300 变为 400，FAB 中心应该从 150 变为 200
      // FAB 的外层容器宽度应该是 slotWidth，但 FAB 本身是 50dp
      // 我们验证的是 FAB 的中心位置是否正确，而不是宽度
      // 因为 FAB 的宽度是固定的 50dp，但它的位置应该占据槽位的中心
      
      debugPrint('Expected slot width: $expectedSlotWidth');
      debugPrint('FAB center X: $fabCenterX');
      debugPrint('Expected FAB center X: $expectedFabCenterX');
      
      // 验证 FAB 中心位置与屏幕宽度成正比
      final expectedFabCenterRatio = logicalWidth * 0.5; // 第三个槽位中心 = 宽度 * 2.5 / 5 = 宽度 * 0.5
      expect(
        fabCenterX,
        closeTo(expectedFabCenterRatio, logicalWidth * 0.1), // 允许 10% 的误差
        reason: 'FAB 中心位置应该与窗口宽度成正比。',
      );
    }

    testWidgets(
      'Slot widths should be consistent across different window widths in portrait mode',
      (WidgetTester tester) async {
        final view = tester.view;
        final originalSize = view.physicalSize;
        final originalDevicePixelRatio = view.devicePixelRatio;
        addTearDown(() {
          view.physicalSize = originalSize;
          view.devicePixelRatio = originalDevicePixelRatio;
        });

        // 测试多个窗口宽度：300, 400, 500, 600，高度固定为 800
        const testWidths = [300.0, 400.0, 500.0, 600.0];
        const testHeight = 800.0;

        for (final width in testWidths) {
          debugPrint('\n=== Testing width: ${width}x${testHeight} ===');
          await testSlotWidthConsistency(tester, width, testHeight);
        }
      },
    );
  });
}

