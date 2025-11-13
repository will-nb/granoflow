import 'package:go_router/go_router.dart';
import 'app_shell.dart';
import '../home/home_page.dart';
import '../tasks/task_list_page.dart';
import 'settings_controls.dart';
import '../inbox/inbox_page.dart';
import '../completion_management/completed_page.dart';
import '../completion_management/archived_page.dart';
import '../completion_management/trash_page.dart';
import '../projects/projects_page.dart';
import '../projects/project_detail_page.dart';
import '../review/calendar_review_page.dart';

/// 应用路由配置
class AppRouter {
  /// 路由配置
  static final GoRouter router = GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/tasks',
            name: 'tasks',
            builder: (context, state) {
              final sectionParam = state.uri.queryParameters['section'];
              final scrollToPinned = state.uri.queryParameters['scrollToPinned'] == 'true';
              return TaskListPage(
                initialSection: sectionParam,
                scrollToPinned: scrollToPinned,
              );
            },
          ),
          GoRoute(
            path: '/projects',
            name: 'projects',
            builder: (context, state) => const ProjectsPage(),
          ),
          GoRoute(
            path: '/projects/:id',
            name: 'project_detail',
            builder: (context, state) {
              final projectId = state.pathParameters['id']!;
              return ProjectDetailPage(projectId: projectId);
            },
          ),
          GoRoute(
            path: '/achievements',
            name: 'achievements',
            builder: (context, state) => const CalendarReviewPage(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsControlsPage(),
          ),
          GoRoute(
            path: '/inbox',
            name: 'inbox',
            builder: (context, state) => const InboxPage(),
          ),
          GoRoute(
            path: '/completed',
            name: 'completed',
            builder: (context, state) => const CompletedPage(),
          ),
          GoRoute(
            path: '/archived',
            name: 'archived',
            builder: (context, state) => const ArchivedPage(),
          ),
          GoRoute(
            path: '/trash',
            name: 'trash',
            builder: (context, state) => const TrashPage(),
          ),
        ],
      ),
    ],
  );
}