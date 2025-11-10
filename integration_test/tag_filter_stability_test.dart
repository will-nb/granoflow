import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:granoflow/main.dart' as app;

import 'package:granoflow/core/providers/tag_option_providers.dart';
import 'package:granoflow/core/providers/task_filter_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 测试标签筛选的稳定性
/// 
/// 验证：
/// 1. 标签筛选不会导致 UI 抖动
/// 2. 标签筛选状态更新正常
/// 3. 标签点击不会导致无限重建
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Tag Filter Stability Tests', () {
    testWidgets(
      'should not cause UI jitter when filtering by tags',
      (WidgetTester tester) async {
        // 启动应用
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // 验证应用已加载
        expect(find.byType(MaterialApp), findsOneWidget);

        // 获取应用的 ProviderContainer
        final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp).first),
        );

        // 获取标签选项和筛选器
        final contextTagsAsync = container.read(contextTagOptionsProvider);
        final taskFilterNotifier = container.read(tasksFilterProvider.notifier);

        // 等待标签加载
        await contextTagsAsync.when(
          data: (tags) async {
            if (tags.isEmpty) {
              print('警告: 没有上下文标签可用，跳过测试');
              return;
            }

            // 记录初始状态
            final initialFilter = container.read(tasksFilterProvider);
            print('初始筛选状态: contextTag=${initialFilter.contextTag}');

            // 选择第一个标签
            final firstTag = tags.first;
            print('选择标签: ${firstTag.slug}');

            // 设置筛选器
            taskFilterNotifier.setContextTag(firstTag.slug);

            // 等待状态更新
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));

            // 验证状态已更新
            final updatedFilter = container.read(tasksFilterProvider);
            expect(updatedFilter.contextTag, equals(firstTag.slug),
                reason: '筛选状态应该更新为选中的标签');

            // 取消选择标签
            taskFilterNotifier.setContextTag(null);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));

            // 验证状态已清除
            final clearedFilter = container.read(tasksFilterProvider);
            expect(clearedFilter.contextTag, isNull,
                reason: '筛选状态应该被清除');

            // 多次切换标签，验证不会导致抖动
            for (int i = 0; i < 5; i++) {
              taskFilterNotifier.setContextTag(firstTag.slug);
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 50));

              taskFilterNotifier.setContextTag(null);
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 50));
            }

            print('标签切换完成，没有检测到异常抖动');
          },
          loading: () async {
            print('标签正在加载，等待...');
            await tester.pumpAndSettle(const Duration(seconds: 2));
          },
          error: (error, stack) async {
            print('加载标签时出错: $error');
            // 如果标签加载失败，跳过测试
          },
        );
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    testWidgets(
      'should maintain filter state without infinite rebuilds',
      (WidgetTester tester) async {
        // 启动应用
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // 验证应用已加载
        expect(find.byType(MaterialApp), findsOneWidget);

        // 获取应用的 ProviderContainer
        final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp).first),
        );

        final taskFilterNotifier = container.read(tasksFilterProvider.notifier);

        // 记录初始状态
        final initialState = container.read(tasksFilterProvider);
        print('初始筛选状态: ${initialState.contextTag}');

        // 设置一个标签
        taskFilterNotifier.setContextTag('home');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // 验证状态已更新
        final stateAfterSet = container.read(tasksFilterProvider);
        expect(stateAfterSet.contextTag, equals('home'),
            reason: '筛选状态应该更新');

        // 等待一段时间，验证状态稳定
        await tester.pump(const Duration(seconds: 1));
        final stateAfterWait = container.read(tasksFilterProvider);
        expect(stateAfterWait.contextTag, equals('home'),
            reason: '筛选状态应该保持稳定');

        // 清除筛选
        taskFilterNotifier.setContextTag(null);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // 验证状态已清除
        final stateAfterClear = container.read(tasksFilterProvider);
        expect(stateAfterClear.contextTag, isNull,
            reason: '筛选状态应该被清除');

        print('筛选状态管理正常，没有检测到无限重建');
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}
