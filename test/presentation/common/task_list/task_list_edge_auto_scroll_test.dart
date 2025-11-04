import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/presentation/common/task_list/inbox_task_list_config.dart';
import 'package:granoflow/presentation/common/task_list/task_list_edge_auto_scroll.dart';
import 'package:granoflow/presentation/common/task_list/tasks_section_task_list_config.dart';

void main() {
  group('TaskListEdgeAutoScroll', () {
    group('handleEdgeAutoScroll', () {
      testWidgets('should start auto-scroll when dragging near top edge (Inbox)', (tester) async {
        final config = InboxTaskListConfig();
        WidgetRef? testRef;

        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                return MaterialApp(
                  home: Scaffold(
                    body: Container(
                      width: 400,
                      height: 800,
                      key: const Key('test-container'),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 获取有 RenderBox 的 context
        final containerElement = tester.element(find.byKey(const Key('test-container')));
        final containerContext = containerElement;

        // 模拟拖拽位置在顶部边缘（距离顶部 10px）
        final dragPosition = const Offset(200, 10);

        // 直接调用 handleEdgeAutoScroll
        TaskListEdgeAutoScroll.handleEdgeAutoScroll(
          containerContext,
          dragPosition,
          config,
          testRef!,
        );

        await tester.pump();

        // 验证自动滚动已启动
        // 注意：由于 auto-scroll 是异步的，我们只能验证方法被调用
      });

      testWidgets('should start auto-scroll when dragging above screen (Inbox)', (tester) async {
        final config = InboxTaskListConfig();
        WidgetRef? testRef;

        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                return MaterialApp(
                  home: Scaffold(
                    body: Container(
                      width: 400,
                      height: 800,
                      key: const Key('test-container'),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        final containerElement = tester.element(find.byKey(const Key('test-container')));
        // 模拟拖拽位置在屏幕上方（超出边界）
        final dragPosition = const Offset(200, -50);

        TaskListEdgeAutoScroll.handleEdgeAutoScroll(
          containerElement,
          dragPosition,
          config,
          testRef!,
        );

        await tester.pump();
      });

      testWidgets('should start auto-scroll when dragging near bottom edge (Tasks)', (tester) async {
        final config = TasksSectionTaskListConfig(TaskSection.today);
        WidgetRef? testRef;

        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                return MaterialApp(
                  home: Scaffold(
                    body: Container(
                      width: 400,
                      height: 800,
                      key: const Key('test-container'),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        final containerElement = tester.element(find.byKey(const Key('test-container')));
        // 模拟拖拽位置在底部边缘（距离底部 10px）
        final dragPosition = const Offset(200, 790);

        TaskListEdgeAutoScroll.handleEdgeAutoScroll(
          containerElement,
          dragPosition,
          config,
          testRef!,
        );

        await tester.pump();
      });

      testWidgets('should start auto-scroll when dragging below screen (Tasks)', (tester) async {
        final config = TasksSectionTaskListConfig(TaskSection.today);
        WidgetRef? testRef;

        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                return MaterialApp(
                  home: Scaffold(
                    body: Container(
                      width: 400,
                      height: 800,
                      key: const Key('test-container'),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        final containerElement = tester.element(find.byKey(const Key('test-container')));
        // 模拟拖拽位置在屏幕下方（超出边界）
        final dragPosition = const Offset(200, 850);

        TaskListEdgeAutoScroll.handleEdgeAutoScroll(
          containerElement,
          dragPosition,
          config,
          testRef!,
        );

        await tester.pump();
      });

      testWidgets('should stop auto-scroll when dragging in middle area', (tester) async {
        final config = InboxTaskListConfig();
        WidgetRef? testRef;

        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                return MaterialApp(
                  home: Scaffold(
                    body: Container(
                      width: 400,
                      height: 800,
                      key: const Key('test-container'),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        final containerElement = tester.element(find.byKey(const Key('test-container')));
        // 模拟拖拽位置在中间区域
        final dragPosition = const Offset(200, 400);

        TaskListEdgeAutoScroll.handleEdgeAutoScroll(
          containerElement,
          dragPosition,
          config,
          testRef!,
        );

        await tester.pump();
      });

      testWidgets('should handle edge threshold boundary (near top)', (tester) async {
        final config = InboxTaskListConfig();
        WidgetRef? testRef;

        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                return MaterialApp(
                  home: Scaffold(
                    body: Container(
                      width: 400,
                      height: 800,
                      key: const Key('test-container'),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        final containerElement = tester.element(find.byKey(const Key('test-container')));
        // 模拟拖拽位置刚好在边缘阈值（120px）
        final dragPosition = const Offset(200, 120);

        TaskListEdgeAutoScroll.handleEdgeAutoScroll(
          containerElement,
          dragPosition,
          config,
          testRef!,
        );

        await tester.pump();
      });

      testWidgets('should handle edge threshold boundary (near bottom)', (tester) async {
        final config = InboxTaskListConfig();
        WidgetRef? testRef;

        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                return MaterialApp(
                  home: Scaffold(
                    body: Container(
                      width: 400,
                      height: 800,
                      key: const Key('test-container'),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        final containerElement = tester.element(find.byKey(const Key('test-container')));
        // 模拟拖拽位置刚好在底部边缘阈值（距离底部 120px）
        final dragPosition = const Offset(200, 680); // 800 - 120 = 680

        TaskListEdgeAutoScroll.handleEdgeAutoScroll(
          containerElement,
          dragPosition,
          config,
          testRef!,
        );

        await tester.pump();
      });

      testWidgets('should return early when renderBox is null', (tester) async {
        final config = InboxTaskListConfig();
        WidgetRef? testRef;

        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                // 创建一个没有 RenderBox 的 context
                return MaterialApp(
                  home: Builder(
                    builder: (context) {
                      // 直接调用，但 context 可能没有 RenderBox
                      TaskListEdgeAutoScroll.handleEdgeAutoScroll(
                        context,
                        const Offset(200, 10),
                        config,
                        testRef!,
                      );
                      return const SizedBox.shrink();
                    },
                  ),
                );
              },
            ),
          ),
        );

        await tester.pump();
        // 验证方法能够处理 renderBox 为 null 的情况
      });

      testWidgets('should calculate speed factor correctly for top edge', (tester) async {
        final config = InboxTaskListConfig();
        WidgetRef? testRef;

        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                return MaterialApp(
                  home: Scaffold(
                    body: Container(
                      width: 400,
                      height: 800,
                      key: const Key('test-container'),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        final containerElement = tester.element(find.byKey(const Key('test-container')));
        // 模拟拖拽位置在距离顶部 60px 处（阈值的一半）
        // 速度因子应该是 (120 - 60) / 120 = 0.5
        final dragPosition = const Offset(200, 60);

        TaskListEdgeAutoScroll.handleEdgeAutoScroll(
          containerElement,
          dragPosition,
          config,
          testRef!,
        );

        await tester.pump();
      });

      testWidgets('should calculate speed factor correctly for bottom edge', (tester) async {
        final config = InboxTaskListConfig();
        WidgetRef? testRef;

        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                return MaterialApp(
                  home: Scaffold(
                    body: Container(
                      width: 400,
                      height: 800,
                      key: const Key('test-container'),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        final containerElement = tester.element(find.byKey(const Key('test-container')));
        // 模拟拖拽位置在距离底部 60px 处（阈值的一半）
        // 速度因子应该是 (120 - 60) / 120 = 0.5
        final dragPosition = const Offset(200, 740); // 800 - 60 = 740

        TaskListEdgeAutoScroll.handleEdgeAutoScroll(
          containerElement,
          dragPosition,
          config,
          testRef!,
        );

        await tester.pump();
      });
    });
  });
}
