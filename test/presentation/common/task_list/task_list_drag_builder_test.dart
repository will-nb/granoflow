import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:granoflow/core/providers/inbox_drag_provider.dart';
import 'package:granoflow/core/providers/tasks_drag_provider.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/common/task_list/inbox_task_list_config.dart';
import 'package:granoflow/presentation/common/task_list/task_list_drag_builder.dart';
import 'package:granoflow/presentation/common/task_list/tasks_section_task_list_config.dart';
import 'package:granoflow/presentation/tasks/utils/tree_flattening_utils.dart';

void main() {
  group('TaskListDragBuilder', () {
    late List<Task> tasks;
    late List<FlattenedTaskNode> flattenedTasks;
    late List<Task> rootTasks;
    late Map<String, int> taskIdToIndex;
    late Map<String, bool> taskIdToHasChildren;
    late Map<String, int> levelMap;
    late Map<String, Set<String>> childrenMap;

    setUp(() {
      tasks = [
        Task(
          id: '1',

          title: 'Task 1',
          status: TaskStatus.pending,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
          sortIndex: 1000,
          tags: const [],
        ),
        Task(
          id: '2',

          title: 'Task 2',
          status: TaskStatus.pending,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
          sortIndex: 2000,
          tags: const [],
        ),
      ];

      flattenedTasks = tasks.map((task) => FlattenedTaskNode(task, 0)).toList();
      rootTasks = tasks;
      taskIdToIndex = {'1': 0, '2': 1};
      taskIdToHasChildren = {'1': false, '2': false};
      levelMap = {'1': 1, '2': 1};
      childrenMap = {'1': {}, '2': {}};
    });

    group('buildTaskListDragUI', () {
      testWidgets(
        'should build widgets list with top insertion target, tasks, and bottom insertion target',
        (tester) async {
          final config = InboxTaskListConfig();
          InboxDragNotifier? dragNotifier;
          InboxDragState? dragState;
          WidgetRef? testRef;

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                // 层级功能已移除，不再需要这些 provider
              ],
              child: Consumer(
                builder: (context, ref, child) {
                  testRef = ref;
                  dragNotifier = ref.read(inboxDragProvider.notifier);
                  dragState = ref.read(inboxDragProvider);

                  final widgets = TaskListDragBuilder.buildTaskListDragUI(
                    flattenedTasks: flattenedTasks,
                    rootTasks: rootTasks,
                    taskIdToIndex: taskIdToIndex,
                    taskIdToHasChildren: taskIdToHasChildren,
                    levelMap: levelMap,
                    childrenMap: childrenMap,
                    expandedTaskIds: {},
                    filteredTasks: tasks,
                    config: config,
                    dragState: dragState!,
                    dragNotifier: dragNotifier!,
                    ref: testRef!,
                    onExpandedChanged: (_) {},
                    onDragStarted: (_) {},
                    onDragEnd: () {},
                    onDragUpdate: (_) {},
                  );

                  return MaterialApp(
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    home: Scaffold(body: Column(children: widgets)),
                  );
                },
              ),
            ),
          );

          await tester.pumpAndSettle();

          // 验证顶部插入目标存在
          expect(
            find.byKey(const ValueKey('inbox-insertion-first')),
            findsOneWidget,
          );

          // 验证任务卡片存在
          expect(find.byKey(const ValueKey('inbox-1')), findsOneWidget);
          expect(find.byKey(const ValueKey('inbox-2')), findsOneWidget);

          // 验证中间插入目标存在
          expect(
            find.byKey(const ValueKey('inbox-insertion-1')),
            findsOneWidget,
          );

          // 验证底部插入目标存在
          expect(
            find.byKey(const ValueKey('inbox-insertion-last')),
            findsOneWidget,
          );
        },
      );

      testWidgets('should build widgets for Tasks page', (tester) async {
        final config = TasksSectionTaskListConfig(TaskSection.today);
        TasksDragNotifier? dragNotifier;
        TasksDragState? dragState;
        WidgetRef? testRef;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              // 层级功能已移除，不再需要这些 provider
            ],
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                dragNotifier = ref.read(tasksDragProvider.notifier);
                dragState = ref.read(tasksDragProvider);

                final widgets = TaskListDragBuilder.buildTaskListDragUI(
                  flattenedTasks: flattenedTasks,
                  rootTasks: rootTasks,
                  taskIdToIndex: taskIdToIndex,
                  taskIdToHasChildren: taskIdToHasChildren,
                  levelMap: levelMap,
                  childrenMap: childrenMap,
                  expandedTaskIds: {},
                  filteredTasks: tasks,
                  config: config,
                  dragState: dragState!,
                  dragNotifier: dragNotifier!,
                  ref: testRef!,
                  onExpandedChanged: (_) {},
                  onDragStarted: (_) {},
                  onDragEnd: () {},
                  onDragUpdate: (_) {},
                );

                return MaterialApp(
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: Scaffold(body: Column(children: widgets)),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 验证顶部插入目标存在
        expect(
          find.byKey(const ValueKey('tasks-insertion-first')),
          findsOneWidget,
        );

        // 验证任务卡片存在
        expect(find.byKey(const ValueKey('tasks-1')), findsOneWidget);
        expect(find.byKey(const ValueKey('tasks-2')), findsOneWidget);
      });

      testWidgets('should handle empty flattened tasks list', (tester) async {
        final config = InboxTaskListConfig();
        InboxDragNotifier? dragNotifier;
        InboxDragState? dragState;
        WidgetRef? testRef;

        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                dragNotifier = ref.read(inboxDragProvider.notifier);
                dragState = ref.read(inboxDragProvider);

                final widgets = TaskListDragBuilder.buildTaskListDragUI(
                  flattenedTasks: [],
                  rootTasks: [],
                  taskIdToIndex: {},
                  taskIdToHasChildren: {},
                  levelMap: {},
                  childrenMap: {},
                  expandedTaskIds: {},
                  filteredTasks: [],
                  config: config,
                  dragState: dragState!,
                  dragNotifier: dragNotifier!,
                  ref: testRef!,
                  onExpandedChanged: (_) {},
                  onDragStarted: (_) {},
                  onDragEnd: () {},
                  onDragUpdate: (_) {},
                );

                return MaterialApp(
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: Scaffold(body: Column(children: widgets)),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 验证只有顶部插入目标存在（没有底部插入目标，因为没有任务）
        expect(
          find.byKey(const ValueKey('inbox-insertion-first')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('inbox-insertion-last')),
          findsNothing,
        );
      });

      testWidgets('should handle tasks with children', (tester) async {
        final config = InboxTaskListConfig();
        InboxDragNotifier? dragNotifier;
        InboxDragState? dragState;
        WidgetRef? testRef;

        final parentTask = Task(
          id: '1',

          title: 'Parent Task',
          status: TaskStatus.pending,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
          sortIndex: 1000,
          tags: const [],
        );

        final childTask = Task(
          id: '2',

          title: 'Child Task',
          status: TaskStatus.pending,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
          
          sortIndex: 2000,
          tags: const [],
        );

        final tasksWithChildren = [parentTask, childTask];
        final flattenedWithChildren = [
          FlattenedTaskNode(parentTask, 0),
          FlattenedTaskNode(childTask, 1),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              // 层级功能已移除，不再需要这些 provider
            ],
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                dragNotifier = ref.read(inboxDragProvider.notifier);
                dragState = ref.read(inboxDragProvider);

                final widgets = TaskListDragBuilder.buildTaskListDragUI(
                  flattenedTasks: flattenedWithChildren,
                  rootTasks: [parentTask],
                  taskIdToIndex: {'1': 0},
                  taskIdToHasChildren: {'1': true, '2': false},
                  levelMap: {'1': 1, '2': 2},
                  childrenMap: {
                    '1': {'2'},
                    '2': {},
                  },
                  expandedTaskIds: {'1'}, // 父任务已展开
                  filteredTasks: tasksWithChildren,
                  config: config,
                  dragState: dragState!,
                  dragNotifier: dragNotifier!,
                  ref: testRef!,
                  onExpandedChanged: (_) {},
                  onDragStarted: (_) {},
                  onDragEnd: () {},
                  onDragUpdate: (_) {},
                );

                return MaterialApp(
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: Scaffold(body: Column(children: widgets)),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 验证父任务和子任务都存在
        expect(find.byKey(const ValueKey('inbox-1')), findsOneWidget);
        expect(find.byKey(const ValueKey('inbox-2')), findsOneWidget);

        // 验证中间插入目标存在（在父任务和子任务之间）
        expect(find.byKey(const ValueKey('inbox-insertion-1')), findsOneWidget);
      });
    });

    group('dragged task handling', () {
      testWidgets('should handle dragged task state', (tester) async {
        final config = InboxTaskListConfig();
        InboxDragNotifier? dragNotifier;
        InboxDragState? dragState;
        WidgetRef? testRef;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              // 层级功能已移除，不再需要这些 provider
            ],
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                dragNotifier = ref.read(inboxDragProvider.notifier);
                dragState = ref.read(inboxDragProvider);

                final widgets = TaskListDragBuilder.buildTaskListDragUI(
                  flattenedTasks: flattenedTasks,
                  rootTasks: rootTasks,
                  taskIdToIndex: taskIdToIndex,
                  taskIdToHasChildren: taskIdToHasChildren,
                  levelMap: levelMap,
                  childrenMap: childrenMap,
                  expandedTaskIds: {},
                  filteredTasks: tasks,
                  config: config,
                  dragState: dragState!,
                  dragNotifier: dragNotifier!,
                  ref: testRef!,
                  onExpandedChanged: (_) {},
                  onDragStarted: (_) {},
                  onDragEnd: () {},
                  onDragUpdate: (_) {},
                );

                return MaterialApp(
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: Scaffold(body: Column(children: widgets)),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 验证任务卡片存在
        // 注意：拖拽状态的处理逻辑在 buildTaskTile 中，这里只验证 Widget 构建成功
        expect(find.byKey(const ValueKey('inbox-1')), findsOneWidget);
        expect(find.byKey(const ValueKey('inbox-2')), findsOneWidget);
      });
    });
  });
}
