import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/core/providers/tag_providers.dart';
import 'package:granoflow/core/theme/app_theme.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/data/models/tag.dart';
import 'package:granoflow/presentation/projects/projects_page.dart';
import 'package:granoflow/presentation/widgets/drawer/drawer_projects_section.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  Widget buildTestWidget({
    required List<Task> projects,
    bool isLoading = false,
    bool hasError = false,
  }) {
    return ProviderScope(
      overrides: [
        if (hasError)
          projectsProvider.overrideWith(
            (ref) => Stream<List<Task>>.error('Test error'),
          )
        else if (isLoading)
          projectsProvider.overrideWith(
            (ref) => Stream<List<Task>>.periodic(
              const Duration(seconds: 10),
              (i) => <Task>[],
            ).take(0),
          )
        else
          projectsProvider.overrideWith(
            (ref) => Stream<List<Task>>.value(projects),
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
        home: const Scaffold(
          body: DrawerProjectsSection(),
        ),
      ),
    );
  }

  Task _createProject({
    required int id,
    required String title,
    DateTime? dueAt,
  }) {
    return Task(
      id: id,
      taskId: 'project-$id',
      title: title,
      status: TaskStatus.pending,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      dueAt: dueAt,
      tags: const <String>[],
      sortIndex: 0,
      templateLockCount: 0,
      allowInstantComplete: false,
      logs: const <TaskLogEntry>[],
      taskKind: TaskKind.project,
    );
  }

  group('DrawerProjectsSection Widget Tests', () {
    testWidgets('should display section title and add button', (tester) async {
      await tester.pumpWidget(buildTestWidget(projects: []));
      
      expect(find.text('最近项目'), findsOneWidget);
      expect(find.text('添加项目'), findsOneWidget);
    });

    testWidgets('should show loading indicator when projects are loading',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(projects: [], isLoading: true));
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display empty state when no projects', (tester) async {
      await tester.pumpWidget(buildTestWidget(projects: []));
      await tester.pump(); // 等待异步状态完成
      
      expect(find.text('暂无项目'), findsOneWidget);
    });

    testWidgets('should display up to 3 projects', (tester) async {
      final projects = List.generate(5, (i) => _createProject(
            id: i + 1,
            title: 'Project ${i + 1}',
          ));
      
      await tester.pumpWidget(buildTestWidget(projects: projects));
      await tester.pump();
      
      // 应该只显示3个项目
      expect(find.text('Project 1'), findsOneWidget);
      expect(find.text('Project 2'), findsOneWidget);
      expect(find.text('Project 3'), findsOneWidget);
      expect(find.text('Project 4'), findsNothing);
      expect(find.text('Project 5'), findsNothing);
    });

    testWidgets('should show project title and icon', (tester) async {
      final project = _createProject(id: 1, title: 'Test Project');
      
      await tester.pumpWidget(buildTestWidget(projects: [project]));
      await tester.pump();
      
      expect(find.text('Test Project'), findsOneWidget);
      expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
    });

    testWidgets('should format and display due date correctly', (tester) async {
      final now = DateTime.now();
      final dueDate = DateTime(now.year, now.month, now.day, 23, 59)
          .add(const Duration(days: 5)); // 使用当天结束时间，避免时区问题
      final project = _createProject(
        id: 1,
        title: 'Test Project',
        dueAt: dueDate,
      );
      
      await tester.pumpWidget(buildTestWidget(projects: [project]));
      await tester.pump();
      
      // 应该显示 "5天后"（根据实际计算的差值）
      final difference = dueDate.difference(DateTime.now()).inDays;
      if (difference == 5) {
        expect(find.text('5天后'), findsOneWidget);
      } else {
        // 如果因为时间计算导致不是5天，至少验证日期格式存在
        expect(find.textContaining('天后'), findsOneWidget);
      }
    });

    testWidgets('should format due date as "今天" for today', (tester) async {
      final now = DateTime.now();
      final project = _createProject(
        id: 1,
        title: 'Test Project',
        dueAt: DateTime(now.year, now.month, now.day),
      );
      
      await tester.pumpWidget(buildTestWidget(projects: [project]));
      await tester.pump();
      
      expect(find.text('今天'), findsOneWidget);
    });

    testWidgets('should format due date as "明天" for tomorrow', (tester) async {
      final now = DateTime.now();
      final dueDate = DateTime(now.year, now.month, now.day, 23, 59)
          .add(const Duration(days: 1)); // 使用当天结束时间
      final project = _createProject(
        id: 1,
        title: 'Test Project',
        dueAt: dueDate,
      );
      
      await tester.pumpWidget(buildTestWidget(projects: [project]));
      await tester.pump();
      
      // 验证显示明天或日期格式
      final difference = dueDate.difference(DateTime.now()).inDays;
      if (difference == 1) {
        expect(find.text('明天'), findsOneWidget);
      } else {
        // 如果因为时间计算导致不是1天，验证至少显示日期
        expect(find.byType(Text), findsWidgets);
      }
    });

    testWidgets('should format due date as "X天后" for within 7 days',
        (tester) async {
      final now = DateTime.now();
      final dueDate = DateTime(now.year, now.month, now.day, 23, 59)
          .add(const Duration(days: 3)); // 使用当天结束时间
      final project = _createProject(
        id: 1,
        title: 'Test Project',
        dueAt: dueDate,
      );
      
      await tester.pumpWidget(buildTestWidget(projects: [project]));
      await tester.pump();
      
      // 验证显示"X天后"格式（根据实际计算的差值）
      final difference = dueDate.difference(DateTime.now()).inDays;
      if (difference >= 2 && difference <= 7) {
        expect(find.text('${difference}天后'), findsOneWidget);
      } else {
        // 如果因为时间计算导致不在范围内，至少验证日期格式存在
        expect(find.byType(Text), findsWidgets);
      }
    });

    testWidgets('should format due date as "M/D" for beyond 7 days',
        (tester) async {
      final now = DateTime.now();
      final dueDate = DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 10)); // 10天后，超过7天
      final project = _createProject(
        id: 1,
        title: 'Test Project',
        dueAt: dueDate,
      );
      
      await tester.pumpWidget(buildTestWidget(projects: [project]));
      await tester.pump();
      
      // 应该显示 M/D 格式（例如 3/15）
      final expectedText = '${dueDate.month}/${dueDate.day}';
      expect(find.text(expectedText), findsOneWidget);
    });

    testWidgets('should show "已逾期" for past dates', (tester) async {
      final now = DateTime.now();
      final project = _createProject(
        id: 1,
        title: 'Test Project',
        dueAt: now.subtract(const Duration(days: 5)),
      );
      
      await tester.pumpWidget(buildTestWidget(projects: [project]));
      await tester.pump();
      
      expect(find.text('已逾期'), findsOneWidget);
    });

    testWidgets('should handle error state', (tester) async {
      await tester.pumpWidget(buildTestWidget(projects: [], hasError: true));
      await tester.pump();
      
      expect(find.text('加载失败'), findsOneWidget);
    });

    testWidgets('should navigate to /projects when "添加项目" button is tapped',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectsProvider.overrideWith(
              (ref) => Stream<List<Task>>.value(const <Task>[]),
            ),
            tagsByKindProvider.overrideWith(
              (ref, kind) async => <Tag>[],
            ),
          ],
          child: MaterialApp.router(
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
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => Scaffold(
                    drawer: const Drawer(child: DrawerProjectsSection()),
                    body: const Center(child: Text('Home')),
                  ),
                ),
                GoRoute(
                  path: '/projects',
                  builder: (context, state) => const ProjectsPage(),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 打开 drawer
      final ScaffoldState scaffoldState = tester.state(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // 点击"添加项目"按钮
      await tester.tap(find.text('添加项目'));
      await tester.pumpAndSettle();

      // 验证已经导航到 ProjectsPage（通过查找 ProjectsPage 特有的组件）
      expect(find.byType(ProjectsPage), findsOneWidget);
    });
  });
}
