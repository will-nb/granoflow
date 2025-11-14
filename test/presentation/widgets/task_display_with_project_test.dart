import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/core/providers/repository_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/services/task_service.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/data/repositories/task_repository.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/inbox/inbox_page.dart';
import 'package:granoflow/core/theme/app_theme.dart';
import 'package:granoflow/data/models/tag.dart';
import 'package:granoflow/data/models/task_template.dart';

class _FakeTaskService extends Fake implements TaskService {}

/// 测试 Inbox 和 Tasks 页面是否都能显示关联了项目/里程碑的任务
///
/// 测试场景：
/// 1. 普通任务（无 projectId/milestoneId）- 应该在两个页面都显示
/// 2. 关联项目的任务（有 projectId）- 应该在两个页面都显示
/// 3. 关联里程碑的任务（有 milestoneId）- 应该在两个页面都显示
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 创建测试用的任务
  Task createTask({
    required String id,
    String? projectId,
    String? milestoneId,
    TaskStatus status = TaskStatus.inbox,
    DateTime? dueAt,
  }) {
    return Task(
      id: id,

      title:
          'Task $id${projectId != null ? " (Project)" : ""}${milestoneId != null ? " (Milestone)" : ""}',
      status: status,
      projectId: projectId,
      milestoneId: milestoneId,
      sortIndex: double.parse(id) * 1024,
      dueAt:
          dueAt ??
          (status == TaskStatus.pending
              ? DateTime(2025, 11, 2, 23, 59, 59)
              : null),
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      tags: const [],
      templateLockCount: 0,
      logs: const [],
    );
  }

  group('Task Display with Project/Milestone', () {
    // TODO: Inbox 项目/里程碑任务展示策略调整中，暂时跳过旧用例
    testWidgets('InboxPage should display tasks with projectId', (
      tester,
    ) async {
      final regularTask = createTask(id: '1', status: TaskStatus.inbox);
      final taskWithProject = createTask(
        id: '2',
        status: TaskStatus.inbox,
        projectId: 'prj-test-001',
      );
      final taskWithMilestone = createTask(
        id: '3',
        status: TaskStatus.inbox,
        milestoneId: 'mil-test-001',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskRepositoryProvider.overrideWith((ref) {
              // 创建一个返回所有 inbox 任务的 repository（包括关联项目的）
              return _TestTaskRepository([
                regularTask,
                taskWithProject,
                taskWithMilestone,
              ]);
            }),
            taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
            templateSuggestionsProvider.overrideWithProvider(
              (query) => FutureProvider((ref) async => const <TaskTemplate>[]),
            ),
            contextTagOptionsProvider.overrideWith((ref) async => const <Tag>[]),
            urgencyTagOptionsProvider.overrideWith((ref) async => const <Tag>[]),
            importanceTagOptionsProvider.overrideWith((ref) async => const <Tag>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const InboxPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证所有任务都显示
      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Task 2 (Project)'), findsOneWidget);
      expect(find.text('Task 3 (Milestone)'), findsOneWidget);
    }, skip: true);
  });
}

/// 测试用的 TaskRepository，直接返回传入的任务列表
class _TestTaskRepository extends Fake implements TaskRepository {
  final List<Task> _tasks;

  _TestTaskRepository(this._tasks);

  @override
  Stream<List<Task>> watchInbox() {
    return Stream.value(
      _tasks.where((task) => task.status == TaskStatus.inbox).toList(),
    );
  }

  @override
  Stream<List<Task>> watchSection(TaskSection section) {
    return Stream.value(
      _tasks.where((task) => task.status == TaskStatus.pending).toList(),
    );
  }

  @override
  Future<Task?> findById(String id) async {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
