import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/providers/tag_providers.dart';
import 'package:granoflow/core/services/task_service.dart';
import 'package:granoflow/core/theme/app_theme.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/data/models/tag.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/projects/projects_page.dart';
import 'package:granoflow/presentation/tasks/projects/projects_dashboard.dart';
import 'package:granoflow/presentation/widgets/gradient_page_scaffold.dart';
import 'package:granoflow/presentation/widgets/main_drawer.dart';
import 'package:granoflow/presentation/widgets/page_app_bar.dart';

class _FakeTaskEditActions extends TaskEditActionsNotifier {
  @override
  Future<void> build() async {}

  @override
  Future<void> archive(int taskId) async {}

  @override
  Future<void> addSubtask({required int parentId, required String title}) async {}

  @override
  Future<void> editTitle({required int taskId, required String title}) async {}
}

class _FakeTaskService extends Fake implements TaskService {}

void main() {
  Widget buildTestWidget({List<Task>? projects}) {
    return ProviderScope(
      overrides: [
        projectsProvider.overrideWith(
          (ref) => Stream<List<Task>>.value(projects ?? const <Task>[]),
        ),
        projectMilestonesProvider.overrideWithProvider((projectId) {
          return StreamProvider<List<Task>>((ref) {
            return Stream.value(const <Task>[]);
          });
        }),
        quickTasksProvider.overrideWith(
          (ref) => Stream<List<Task>>.value(const <Task>[]),
        ),
        projectsExpandedTaskIdProvider.overrideWith((ref) => null),
        taskEditActionsNotifierProvider.overrideWith(() => _FakeTaskEditActions()),
        taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
        tagsByKindProvider.overrideWith(
          (ref, kind) async => <Tag>[],
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
          Locale('zh', 'CN'),
          Locale('zh', 'HK'),
        ],
        home: const ProjectsPage(),
      ),
    );
  }

  group('ProjectsPage Widget Tests', () {
    testWidgets('should render ProjectsPage with correct structure', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // 验证 GradientPageScaffold 存在
      expect(find.byType(GradientPageScaffold), findsOneWidget);

      // 验证 PageAppBar 存在
      expect(find.byType(PageAppBar), findsOneWidget);

      // 验证 ProjectsDashboard 存在
      expect(find.byType(ProjectsDashboard), findsOneWidget);

      // 打开 drawer 后验证 MainDrawer 存在
      final ScaffoldState scaffoldState = tester.state(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();
      expect(find.byType(MainDrawer), findsOneWidget);
    });

    testWidgets('should display localized title in AppBar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final l10n = AppLocalizations.of(tester.element(find.byType(ProjectsPage)));
      // 在 AppBar 中查找标题（可能有多个同名文本，但 AppBar 中的应该存在）
      expect(find.byType(AppBar), findsOneWidget);
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.title, isA<Text>());
      final titleText = appBar.title as Text;
      expect(titleText.data, equals(l10n.projectListTitle));
    });

    testWidgets('should render MainDrawer in drawer', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // 打开 drawer
      final ScaffoldState scaffoldState = tester.state(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // 验证 MainDrawer 内容存在
      expect(find.byType(MainDrawer), findsOneWidget);
    });

    testWidgets('should render ProjectsDashboard with empty project list', (tester) async {
      await tester.pumpWidget(buildTestWidget(projects: []));
      await tester.pump();

      final l10n = AppLocalizations.of(tester.element(find.byType(ProjectsPage)));
      expect(find.text(l10n.projectListEmpty), findsOneWidget);
    });

    testWidgets('should render ProjectsDashboard with projects', (tester) async {
      final project = Task(
        id: 1,
        taskId: 'project-1',
        title: 'Test Project',
        status: TaskStatus.pending,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        dueAt: null,
        tags: const <String>[],
        sortIndex: 0,
        templateLockCount: 0,
        allowInstantComplete: false,
        logs: const <TaskLogEntry>[],
        taskKind: TaskKind.project,
      );

      await tester.pumpWidget(buildTestWidget(projects: [project]));
      await tester.pump();

      expect(find.text('Test Project'), findsOneWidget);
    });

    testWidgets('should have correct page structure with Scaffold', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // 验证 Scaffold 存在（通过 GradientPageScaffold 内部创建）
      expect(find.byType(Scaffold), findsOneWidget);

      // 验证 AppBar 存在
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should render ProjectsDashboard correctly', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // 验证 ProjectsDashboard 被正确渲染
      final dashboard = tester.widget<ProjectsDashboard>(find.byType(ProjectsDashboard));
      expect(dashboard, isNotNull);
    });
  });
}
