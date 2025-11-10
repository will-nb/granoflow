import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/services/task_service.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/data/models/tag.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/inbox/views/inbox_task_list.dart';
import 'package:granoflow/core/theme/app_theme.dart';

class _StubTag extends Tag {
  _StubTag(String slug, TagKind kind)
    : super(
        id: slug.hashCode,
        slug: slug,
        kind: kind,
        localizedLabels: {'en': slug},
      );
}

class _FakeTaskService extends Fake implements TaskService {}

void main() {
  group('InboxTaskList', () {
    testWidgets('should render tasks list correctly', (tester) async {
      final tasks = <Task>[
        Task(
          id: '1',

          title: 'First Task',
          status: TaskStatus.inbox,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
          sortIndex: 1000,
          tags: const <String>[],
        ),
        Task(
          id: '2',

          title: 'Second Task',
          status: TaskStatus.inbox,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
          sortIndex: 2000,
          tags: const <String>[],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
            inboxTaskLevelMapProvider.overrideWith(
              (ref) async => <String, int>{'1': 1, '2': 1},
            ),
            inboxTaskChildrenMapProvider.overrideWith(
              (ref) async => <String, Set<String>>{},
            ),
            contextTagOptionsProvider.overrideWith(
              (ref) async => [_StubTag('@home', TagKind.context)],
            ),
            urgencyTagOptionsProvider.overrideWith(
              (ref) async => [_StubTag('#urgent', TagKind.urgency)],
            ),
            importanceTagOptionsProvider.overrideWith(
              (ref) async => [_StubTag('#important', TagKind.importance)],
            ),
            executionTagOptionsProvider.overrideWith(
              (ref) async => const <Tag>[],
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: InboxTaskList(tasks: tasks)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证任务列表正常渲染
      expect(find.text('First Task'), findsOneWidget);
      expect(find.text('Second Task'), findsOneWidget);
    });

    testWidgets('should display tasks with hierarchy', (tester) async {
      final parentTask = Task(
        id: '1',

        title: 'Parent Task',
        status: TaskStatus.inbox,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        sortIndex: 1000,
        tags: const <String>[],
      );

      final childTask = Task(
        id: '2',

        title: 'Child Task',
        status: TaskStatus.inbox,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        parentId: 1,
        sortIndex: 2000,
        tags: const <String>[],
      );

      final tasks = [parentTask, childTask];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
            inboxTaskLevelMapProvider.overrideWith(
              (ref) async => <String, int>{'1': 1, '2': 2},
            ),
            inboxTaskChildrenMapProvider.overrideWith(
              (ref) async => <String, Set<String>>{
                '1': {'2'},
                '2': {},
              },
            ),
            inboxExpandedTaskIdProvider.overrideWith((ref) => {'1'}), // 父任务默认展开
            contextTagOptionsProvider.overrideWith((ref) async => const []),
            urgencyTagOptionsProvider.overrideWith((ref) async => const []),
            importanceTagOptionsProvider.overrideWith((ref) async => const []),
            executionTagOptionsProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: InboxTaskList(tasks: tasks)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证父任务和子任务都显示（父任务展开后）
      expect(find.text('Parent Task'), findsOneWidget);
      expect(find.text('Child Task'), findsOneWidget);
    });

    testWidgets('should handle expand/collapse functionality', (tester) async {
      final parentTask = Task(
        id: '1',

        title: 'Parent Task',
        status: TaskStatus.inbox,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        sortIndex: 1000,
        tags: const <String>[],
      );

      final childTask = Task(
        id: '2',

        title: 'Child Task',
        status: TaskStatus.inbox,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        parentId: 1,
        sortIndex: 2000,
        tags: const <String>[],
      );

      final tasks = [parentTask, childTask];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
            inboxTaskLevelMapProvider.overrideWith(
              (ref) async => <String, int>{'1': 1, '2': 2},
            ),
            inboxTaskChildrenMapProvider.overrideWith(
              (ref) async => <String, Set<String>>{
                '1': {'2'},
                '2': {},
              },
            ),
            contextTagOptionsProvider.overrideWith((ref) async => const []),
            urgencyTagOptionsProvider.overrideWith((ref) async => const []),
            importanceTagOptionsProvider.overrideWith((ref) async => const []),
            executionTagOptionsProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: InboxTaskList(tasks: tasks)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证父任务有展开按钮（因为有子任务）
      expect(find.byIcon(Icons.expand_more), findsOneWidget);

      // 点击展开按钮
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      // 验证展开后图标变为收缩图标
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
    });

    testWidgets('should show insertion targets when dragging', (tester) async {
      final tasks = <Task>[
        Task(
          id: '1',

          title: 'First Task',
          status: TaskStatus.inbox,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
          sortIndex: 1000,
          tags: const <String>[],
        ),
        Task(
          id: '2',

          title: 'Second Task',
          status: TaskStatus.inbox,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
          sortIndex: 2000,
          tags: const <String>[],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
            inboxTaskLevelMapProvider.overrideWith(
              (ref) async => <String, int>{'1': 1, '2': 1},
            ),
            inboxTaskChildrenMapProvider.overrideWith(
              (ref) async => <String, Set<String>>{},
            ),
            contextTagOptionsProvider.overrideWith((ref) async => const []),
            urgencyTagOptionsProvider.overrideWith((ref) async => const []),
            importanceTagOptionsProvider.overrideWith((ref) async => const []),
            executionTagOptionsProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: InboxTaskList(tasks: tasks)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证插入目标存在（顶部、中间、底部）
      expect(
        find.byKey(const ValueKey('inbox-insertion-first')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('inbox-insertion-1')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('inbox-insertion-last')),
        findsOneWidget,
      );
    });

    testWidgets('should handle empty tasks list', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
            inboxTaskLevelMapProvider.overrideWith(
              (ref) async => <String, int>{},
            ),
            inboxTaskChildrenMapProvider.overrideWith(
              (ref) async => <String, Set<String>>{},
            ),
            contextTagOptionsProvider.overrideWith((ref) async => const []),
            urgencyTagOptionsProvider.overrideWith((ref) async => const []),
            importanceTagOptionsProvider.overrideWith((ref) async => const []),
            executionTagOptionsProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: InboxTaskList(tasks: [])),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证空列表不会崩溃
      // 注意：空列表时，顶部插入目标可能不存在（因为 flattenedTasks 为空）
      // 这里只验证 Widget 构建成功，不崩溃
      expect(find.byType(InboxTaskList), findsOneWidget);
    });

    testWidgets('should filter out trashed tasks', (tester) async {
      final activeTask = Task(
        id: '1',

        title: 'Active Task',
        status: TaskStatus.inbox,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        sortIndex: 1000,
        tags: const <String>[],
      );

      final trashedTask = Task(
        id: '2',

        title: 'Trashed Task',
        status: TaskStatus.trashed,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        sortIndex: 2000,
        tags: const <String>[],
      );

      final tasks = [activeTask, trashedTask];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
            inboxTaskLevelMapProvider.overrideWith(
              (ref) async => <String, int>{'1': 1},
            ),
            inboxTaskChildrenMapProvider.overrideWith(
              (ref) async => <String, Set<String>>{},
            ),
            contextTagOptionsProvider.overrideWith((ref) async => const []),
            urgencyTagOptionsProvider.overrideWith((ref) async => const []),
            importanceTagOptionsProvider.overrideWith((ref) async => const []),
            executionTagOptionsProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: InboxTaskList(tasks: tasks)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证只有活跃任务显示
      expect(find.text('Active Task'), findsOneWidget);
      expect(find.text('Trashed Task'), findsNothing);
    });

    testWidgets('should handle task updates and rebuild', (tester) async {
      final task1 = Task(
        id: '1',

        title: 'Original Title',
        status: TaskStatus.inbox,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        sortIndex: 1000,
        tags: const <String>[],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
            inboxTaskLevelMapProvider.overrideWith(
              (ref) async => <String, int>{'1': 1},
            ),
            inboxTaskChildrenMapProvider.overrideWith(
              (ref) async => <String, Set<String>>{},
            ),
            contextTagOptionsProvider.overrideWith((ref) async => const []),
            urgencyTagOptionsProvider.overrideWith((ref) async => const []),
            importanceTagOptionsProvider.overrideWith((ref) async => const []),
            executionTagOptionsProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: InboxTaskList(tasks: [task1])),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证原始标题显示
      expect(find.text('Original Title'), findsOneWidget);

      // 更新任务列表
      final updatedTask1 = Task(
        id: '1',

        title: 'Updated Title',
        status: TaskStatus.inbox,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 2),
        sortIndex: 1000,
        tags: const <String>[],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
            inboxTaskLevelMapProvider.overrideWith(
              (ref) async => <String, int>{'1': 1},
            ),
            inboxTaskChildrenMapProvider.overrideWith(
              (ref) async => <String, Set<String>>{},
            ),
            contextTagOptionsProvider.overrideWith((ref) async => const []),
            urgencyTagOptionsProvider.overrideWith((ref) async => const []),
            importanceTagOptionsProvider.overrideWith((ref) async => const []),
            executionTagOptionsProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: InboxTaskList(tasks: [updatedTask1])),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证更新后的标题显示
      expect(find.text('Updated Title'), findsOneWidget);
      expect(find.text('Original Title'), findsNothing);
    });

    testWidgets('should handle multiple levels of hierarchy', (tester) async {
      final level1Task = Task(
        id: '1',

        title: 'Level 1 Task',
        status: TaskStatus.inbox,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        sortIndex: 1000,
        tags: const <String>[],
      );

      final level2Task = Task(
        id: '2',

        title: 'Level 2 Task',
        status: TaskStatus.inbox,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        parentId: 1,
        sortIndex: 2000,
        tags: const <String>[],
      );

      final level3Task = Task(
        id: '3',

        title: 'Level 3 Task',
        status: TaskStatus.inbox,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        parentId: 2,
        sortIndex: 3000,
        tags: const <String>[],
      );

      final tasks = [level1Task, level2Task, level3Task];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
            inboxTaskLevelMapProvider.overrideWith(
              (ref) async => <String, int>{'1': 1, '2': 2, '3': 3},
            ),
            inboxTaskChildrenMapProvider.overrideWith(
              (ref) async => <String, Set<String>>{
                '1': {'2'},
                '2': {'3'},
                '3': {},
              },
            ),
            inboxExpandedTaskIdProvider.overrideWith(
              (ref) => {'1', '2'},
            ), // 前两级默认展开
            contextTagOptionsProvider.overrideWith((ref) async => const []),
            urgencyTagOptionsProvider.overrideWith((ref) async => const []),
            importanceTagOptionsProvider.overrideWith((ref) async => const []),
            executionTagOptionsProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: InboxTaskList(tasks: tasks)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证所有层级的任务都显示（展开后）
      expect(find.text('Level 1 Task'), findsOneWidget);
      expect(find.text('Level 2 Task'), findsOneWidget);
      expect(find.text('Level 3 Task'), findsOneWidget);
    });
  });
}
