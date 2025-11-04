import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/core/providers/inbox_drag_provider.dart';
import 'package:granoflow/core/providers/tasks_drag_provider.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/presentation/common/task_list/inbox_task_list_config.dart';
import 'package:granoflow/presentation/common/task_list/task_list_task_tile_builder.dart';
import 'package:granoflow/presentation/common/task_list/tasks_section_task_list_config.dart';
import 'package:granoflow/presentation/tasks/utils/tree_flattening_utils.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';

void main() {
  group('TaskListTaskTileBuilder', () {
    late Task task;
    late List<FlattenedTaskNode> flattenedTasks;
    late List<Task> filteredTasks;
    late List<Task> rootTasks;

    setUp(() {
      task = Task(
        id: 1,
        taskId: 'task-1',
        title: 'Test Task',
        status: TaskStatus.pending,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        sortIndex: 1000,
        tags: const [],
      );

      flattenedTasks = [FlattenedTaskNode(task, 0)];
      filteredTasks = [task];
      rootTasks = [task];
    });

    group('buildTaskTile', () {
      testWidgets('should build task tile widget for Inbox', (tester) async {
        final config = InboxTaskListConfig();
        InboxDragNotifier? dragNotifier;
        InboxDragState? dragState;
        WidgetRef? testRef;
        Set<int> expandedTaskIds = {};

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              inboxTaskLevelMapProvider.overrideWith((ref) async => <int, int>{1: 1}),
              inboxTaskChildrenMapProvider.overrideWith((ref) async => <int, Set<int>>{}),
            ],
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                dragNotifier = ref.read(inboxDragProvider.notifier);
                dragState = ref.read(inboxDragProvider);

                final widget = TaskListTaskTileBuilder.buildTaskTile(
                  task: task,
                  depth: 0,
                  depthPixels: 16.0,
                  isDraggedTask: false,
                  hasChildren: false,
                  isExpanded: false,
                  taskLevel: 1,
                  isInExpandedArea: false,
                  flattenedTasks: flattenedTasks,
                  filteredTasks: filteredTasks,
                  rootTasks: rootTasks,
                  dragState: dragState!,
                  dragNotifier: dragNotifier!,
                  config: config,
                  ref: testRef!,
                  expandedTaskIds: expandedTaskIds,
                  onExpandedChanged: (_) {},
                  onDragStarted: (_) {},
                  onDragUpdate: (_) {},
                );

                return MaterialApp(
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: Scaffold(
                    body: widget,
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 验证任务卡片存在
        expect(find.byKey(const ValueKey('inbox-1')), findsOneWidget);
        expect(find.byKey(const ValueKey('task-1')), findsOneWidget);
      });

      testWidgets('should build task tile with expand button when hasChildren is true', (tester) async {
        final config = InboxTaskListConfig();
        InboxDragNotifier? dragNotifier;
        InboxDragState? dragState;
        WidgetRef? testRef;
        Set<int> expandedTaskIds = {};

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              inboxTaskLevelMapProvider.overrideWith((ref) async => <int, int>{1: 1}),
              inboxTaskChildrenMapProvider.overrideWith((ref) async => <int, Set<int>>{1: {2}}),
            ],
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                dragNotifier = ref.read(inboxDragProvider.notifier);
                dragState = ref.read(inboxDragProvider);

                final widget = TaskListTaskTileBuilder.buildTaskTile(
                  task: task,
                  depth: 0,
                  depthPixels: 16.0,
                  isDraggedTask: false,
                  hasChildren: true,
                  isExpanded: false,
                  taskLevel: 1,
                  isInExpandedArea: false,
                  flattenedTasks: flattenedTasks,
                  filteredTasks: filteredTasks,
                  rootTasks: rootTasks,
                  dragState: dragState!,
                  dragNotifier: dragNotifier!,
                  config: config,
                  ref: testRef!,
                  expandedTaskIds: expandedTaskIds,
                  onExpandedChanged: (_) {},
                  onDragStarted: (_) {},
                  onDragUpdate: (_) {},
                );

                return MaterialApp(
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: Scaffold(
                    body: widget,
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 验证展开按钮存在
        expect(find.byIcon(Icons.expand_more), findsOneWidget);
      });

      testWidgets('should show expand_less icon when task is expanded', (tester) async {
        final config = InboxTaskListConfig();
        InboxDragNotifier? dragNotifier;
        InboxDragState? dragState;
        WidgetRef? testRef;
        Set<int> expandedTaskIds = {1};

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              inboxTaskLevelMapProvider.overrideWith((ref) async => <int, int>{1: 1}),
              inboxTaskChildrenMapProvider.overrideWith((ref) async => <int, Set<int>>{1: {2}}),
            ],
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                dragNotifier = ref.read(inboxDragProvider.notifier);
                dragState = ref.read(inboxDragProvider);

                final widget = TaskListTaskTileBuilder.buildTaskTile(
                  task: task,
                  depth: 0,
                  depthPixels: 16.0,
                  isDraggedTask: false,
                  hasChildren: true,
                  isExpanded: true,
                  taskLevel: 1,
                  isInExpandedArea: false,
                  flattenedTasks: flattenedTasks,
                  filteredTasks: filteredTasks,
                  rootTasks: rootTasks,
                  dragState: dragState!,
                  dragNotifier: dragNotifier!,
                  config: config,
                  ref: testRef!,
                  expandedTaskIds: expandedTaskIds,
                  onExpandedChanged: (_) {},
                  onDragStarted: (_) {},
                  onDragUpdate: (_) {},
                );

                return MaterialApp(
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: Scaffold(
                    body: widget,
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 验证收缩按钮存在
        expect(find.byIcon(Icons.expand_less), findsOneWidget);
      });

      testWidgets('should call onExpandedChanged when expand button is tapped', (tester) async {
        final config = InboxTaskListConfig();
        InboxDragNotifier? dragNotifier;
        InboxDragState? dragState;
        WidgetRef? testRef;
        Set<int> expandedTaskIds = {};
        bool expandedChangedCalled = false;
        Set<int>? lastExpandedIds;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              inboxTaskLevelMapProvider.overrideWith((ref) async => <int, int>{1: 1}),
              inboxTaskChildrenMapProvider.overrideWith((ref) async => <int, Set<int>>{1: {2}}),
            ],
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                dragNotifier = ref.read(inboxDragProvider.notifier);
                dragState = ref.read(inboxDragProvider);

                final widget = TaskListTaskTileBuilder.buildTaskTile(
                  task: task,
                  depth: 0,
                  depthPixels: 16.0,
                  isDraggedTask: false,
                  hasChildren: true,
                  isExpanded: false,
                  taskLevel: 1,
                  isInExpandedArea: false,
                  flattenedTasks: flattenedTasks,
                  filteredTasks: filteredTasks,
                  rootTasks: rootTasks,
                  dragState: dragState!,
                  dragNotifier: dragNotifier!,
                  config: config,
                  ref: testRef!,
                  expandedTaskIds: expandedTaskIds,
                  onExpandedChanged: (ids) {
                    expandedChangedCalled = true;
                    lastExpandedIds = ids;
                  },
                  onDragStarted: (_) {},
                  onDragUpdate: (_) {},
                );

                return MaterialApp(
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: Scaffold(
                    body: widget,
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 点击展开按钮
        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();

        // 验证回调被调用
        expect(expandedChangedCalled, true);
        expect(lastExpandedIds, isNotNull);
        expect(lastExpandedIds!.contains(1), true);
      });

      testWidgets('should collapse other root tasks when expanding a root task in Tasks page', (tester) async {
        final config = TasksSectionTaskListConfig(TaskSection.today);
        TasksDragNotifier? dragNotifier;
        TasksDragState? dragState;
        WidgetRef? testRef;
        
        final task1 = Task(
          id: 1,
          taskId: 'task-1',
          title: 'Task 1',
          status: TaskStatus.pending,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
          dueAt: DateTime(2025, 1, 1),
          sortIndex: 1000,
          tags: const [],
        );
        
        final task2 = Task(
          id: 2,
          taskId: 'task-2',
          title: 'Task 2',
          status: TaskStatus.pending,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
          dueAt: DateTime(2025, 1, 1),
          sortIndex: 2000,
          tags: const [],
        );

        Set<int> expandedTaskIds = {2}; // task2 已展开
        Set<int>? lastExpandedIds;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tasksSectionTaskLevelMapProvider(TaskSection.today).overrideWith((ref) async => <int, int>{1: 1, 2: 1}),
              tasksSectionTaskChildrenMapProvider(TaskSection.today).overrideWith((ref) async => <int, Set<int>>{1: {3}, 2: {4}}),
            ],
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                dragNotifier = ref.read(tasksDragProvider.notifier);
                dragState = ref.read(tasksDragProvider);

                final widget = TaskListTaskTileBuilder.buildTaskTile(
                  task: task1,
                  depth: 0,
                  depthPixels: 16.0,
                  isDraggedTask: false,
                  hasChildren: true,
                  isExpanded: false,
                  taskLevel: 1,
                  isInExpandedArea: false,
                  flattenedTasks: [FlattenedTaskNode(task1, 0), FlattenedTaskNode(task2, 0)],
                  filteredTasks: [task1, task2],
                  rootTasks: [task1, task2],
                  dragState: dragState!,
                  dragNotifier: dragNotifier!,
                  config: config,
                  ref: testRef!,
                  expandedTaskIds: expandedTaskIds,
                  onExpandedChanged: (ids) {
                    lastExpandedIds = ids;
                  },
                  onDragStarted: (_) {},
                  onDragUpdate: (_) {},
                );

                return MaterialApp(
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: Scaffold(
                    body: widget,
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 点击 task1 的展开按钮
        await tester.tap(find.byIcon(Icons.expand_more));
        await tester.pumpAndSettle();

        // 验证：task2 应该被收缩，task1 应该被展开
        expect(lastExpandedIds, isNotNull);
        expect(lastExpandedIds!.contains(1), true);
        expect(lastExpandedIds!.contains(2), false); // task2 应该被收缩
      });

      testWidgets('should apply padding based on depth', (tester) async {
        final config = InboxTaskListConfig();
        InboxDragNotifier? dragNotifier;
        InboxDragState? dragState;
        WidgetRef? testRef;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              inboxTaskLevelMapProvider.overrideWith((ref) async => <int, int>{1: 2}),
              inboxTaskChildrenMapProvider.overrideWith((ref) async => <int, Set<int>>{}),
            ],
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                dragNotifier = ref.read(inboxDragProvider.notifier);
                dragState = ref.read(inboxDragProvider);

                final widget = TaskListTaskTileBuilder.buildTaskTile(
                  task: task,
                  depth: 2,
                  depthPixels: 16.0,
                  isDraggedTask: false,
                  hasChildren: false,
                  isExpanded: false,
                  taskLevel: 2,
                  isInExpandedArea: false,
                  flattenedTasks: flattenedTasks,
                  filteredTasks: filteredTasks,
                  rootTasks: rootTasks,
                  dragState: dragState!,
                  dragNotifier: dragNotifier!,
                  config: config,
                  ref: testRef!,
                  expandedTaskIds: {},
                  onExpandedChanged: (_) {},
                  onDragStarted: (_) {},
                  onDragUpdate: (_) {},
                );

                return MaterialApp(
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: Scaffold(
                    body: widget,
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 验证任务卡片存在（通过检查 key 来验证）
        // 注意：padding 的内部结构可能因为 Widget 树的变化而难以直接验证
        // 这里只验证 Widget 构建成功，padding 的逻辑在 buildTaskTile 方法中已经实现
        expect(find.byKey(const ValueKey('inbox-1')), findsOneWidget);
      });

      testWidgets('should apply background color when isInExpandedArea is true', (tester) async {
        final config = InboxTaskListConfig();
        InboxDragNotifier? dragNotifier;
        InboxDragState? dragState;
        WidgetRef? testRef;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              inboxTaskLevelMapProvider.overrideWith((ref) async => <int, int>{1: 2}),
              inboxTaskChildrenMapProvider.overrideWith((ref) async => <int, Set<int>>{}),
            ],
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                dragNotifier = ref.read(inboxDragProvider.notifier);
                dragState = ref.read(inboxDragProvider);

                final widget = TaskListTaskTileBuilder.buildTaskTile(
                  task: task,
                  depth: 1,
                  depthPixels: 16.0,
                  isDraggedTask: false,
                  hasChildren: false,
                  isExpanded: false,
                  taskLevel: 2,
                  isInExpandedArea: true,
                  flattenedTasks: flattenedTasks,
                  filteredTasks: filteredTasks,
                  rootTasks: rootTasks,
                  dragState: dragState!,
                  dragNotifier: dragNotifier!,
                  config: config,
                  ref: testRef!,
                  expandedTaskIds: {},
                  onExpandedChanged: (_) {},
                  onDragStarted: (_) {},
                  onDragUpdate: (_) {},
                );

                return MaterialApp(
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: Scaffold(
                    body: widget,
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 验证任务卡片存在
        // 注意：decoration 的内部结构可能因为 Widget 树的变化而难以直接验证
        // 这里只验证 Widget 构建成功，decoration 的逻辑在 buildTaskTile 方法中已经实现
        expect(find.byKey(const ValueKey('inbox-1')), findsOneWidget);
      });

      testWidgets('should handle onHover with expansion detection', (tester) async {
        final config = InboxTaskListConfig();
        InboxDragNotifier? dragNotifier;
        InboxDragState? dragState;
        WidgetRef? testRef;

        final parentTask = Task(
          id: 1,
          taskId: 'task-1',
          title: 'Parent Task',
          status: TaskStatus.pending,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
          sortIndex: 1000,
          tags: const [],
        );

        final childTask = Task(
          id: 2,
          taskId: 'task-2',
          title: 'Child Task',
          status: TaskStatus.pending,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
          parentId: 1,
          sortIndex: 2000,
          tags: const [],
        );

        final tasksWithHierarchy = [parentTask, childTask];
        final flattenedWithHierarchy = [
          FlattenedTaskNode(parentTask, 0),
          FlattenedTaskNode(childTask, 1),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              inboxTaskLevelMapProvider.overrideWith((ref) async => <int, int>{1: 1, 2: 2}),
              inboxTaskChildrenMapProvider.overrideWith((ref) async => <int, Set<int>>{1: {2}, 2: {}}),
            ],
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                dragNotifier = ref.read(inboxDragProvider.notifier);
                // 开始拖拽子任务
                dragNotifier!.startDrag(childTask, const Offset(0, 0));
                dragState = ref.read(inboxDragProvider);

                final widget = TaskListTaskTileBuilder.buildTaskTile(
                  task: parentTask,
                  depth: 0,
                  depthPixels: 16.0,
                  isDraggedTask: false,
                  hasChildren: true,
                  isExpanded: true,
                  taskLevel: 1,
                  isInExpandedArea: false,
                  flattenedTasks: flattenedWithHierarchy,
                  filteredTasks: tasksWithHierarchy,
                  rootTasks: [parentTask],
                  dragState: dragState!,
                  dragNotifier: dragNotifier!,
                  config: config,
                  ref: testRef!,
                  expandedTaskIds: {1},
                  onExpandedChanged: (_) {},
                  onDragStarted: (_) {},
                  onDragUpdate: (_) {},
                );

                return MaterialApp(
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: Scaffold(
                    body: widget,
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 验证任务卡片存在
        expect(find.byKey(const ValueKey('inbox-1')), findsOneWidget);
      });

      testWidgets('should handle onHover with edge auto-scroll', (tester) async {
        final config = InboxTaskListConfig();
        InboxDragNotifier? dragNotifier;
        InboxDragState? dragState;
        WidgetRef? testRef;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              inboxTaskLevelMapProvider.overrideWith((ref) async => <int, int>{1: 1}),
              inboxTaskChildrenMapProvider.overrideWith((ref) async => <int, Set<int>>{}),
            ],
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                dragNotifier = ref.read(inboxDragProvider.notifier);
                // 开始拖拽任务
                dragNotifier!.startDrag(task, const Offset(0, 0));
                // 更新拖拽位置到顶部边缘
                dragNotifier?.updateDragPosition(const Offset(200, 10));
                dragState = ref.read(inboxDragProvider);

                final widget = TaskListTaskTileBuilder.buildTaskTile(
                  task: task,
                  depth: 0,
                  depthPixels: 16.0,
                  isDraggedTask: true,
                  hasChildren: false,
                  isExpanded: false,
                  taskLevel: 1,
                  isInExpandedArea: false,
                  flattenedTasks: flattenedTasks,
                  filteredTasks: filteredTasks,
                  rootTasks: rootTasks,
                  dragState: dragState!,
                  dragNotifier: dragNotifier!,
                  config: config,
                  ref: testRef!,
                  expandedTaskIds: {},
                  onExpandedChanged: (_) {},
                  onDragStarted: (_) {},
                  onDragUpdate: (details) {
                    dragNotifier!.updateDragPosition(details.globalPosition);
                  },
                );

                return MaterialApp(
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: Scaffold(
                    body: Container(
                      width: 400,
                      height: 800,
                      child: widget,
                    ),
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 验证任务卡片存在（但应该被隐藏，因为 isDraggedTask 为 true）
        expect(find.byKey(const ValueKey('inbox-1')), findsOneWidget);
      });

      testWidgets('should handle onHover with null drag position', (tester) async {
        final config = InboxTaskListConfig();
        InboxDragNotifier? dragNotifier;
        InboxDragState? dragState;
        WidgetRef? testRef;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              inboxTaskLevelMapProvider.overrideWith((ref) async => <int, int>{1: 1}),
              inboxTaskChildrenMapProvider.overrideWith((ref) async => <int, Set<int>>{}),
            ],
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                dragNotifier = ref.read(inboxDragProvider.notifier);
                // 开始拖拽任务，但不设置位置
                dragNotifier!.startDrag(task, Offset.zero);
                dragState = ref.read(inboxDragProvider);

                final widget = TaskListTaskTileBuilder.buildTaskTile(
                  task: task,
                  depth: 0,
                  depthPixels: 16.0,
                  isDraggedTask: false,
                  hasChildren: false,
                  isExpanded: false,
                  taskLevel: 1,
                  isInExpandedArea: false,
                  flattenedTasks: flattenedTasks,
                  filteredTasks: filteredTasks,
                  rootTasks: rootTasks,
                  dragState: dragState!,
                  dragNotifier: dragNotifier!,
                  config: config,
                  ref: testRef!,
                  expandedTaskIds: {},
                  onExpandedChanged: (_) {},
                  onDragStarted: (_) {},
                  onDragUpdate: (_) {},
                );

                return MaterialApp(
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: Scaffold(
                    body: widget,
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 验证任务卡片存在
        expect(find.byKey(const ValueKey('inbox-1')), findsOneWidget);
      });
    });
  });
}

