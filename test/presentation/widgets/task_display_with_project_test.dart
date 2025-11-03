import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/core/providers/repository_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/providers/tasks_section_drag_provider.dart';
import 'package:granoflow/core/services/task_service.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/data/repositories/task_repository.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/inbox/inbox_page.dart';
import 'package:granoflow/presentation/tasks/views/task_section_panel.dart';
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
    required int id,
    String? projectId,
    String? milestoneId,
    TaskStatus status = TaskStatus.inbox,
    DateTime? dueAt,
  }) {
    return Task(
      id: id,
      taskId: 'task-$id',
      title: 'Task $id${projectId != null ? " (Project)" : ""}${milestoneId != null ? " (Milestone)" : ""}',
      status: status,
      projectId: projectId,
      milestoneId: milestoneId,
      sortIndex: id.toDouble() * 1024,
      dueAt: dueAt ?? (status == TaskStatus.pending ? DateTime(2025, 11, 2, 23, 59, 59) : null),
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      tags: const [],
      templateLockCount: 0,
      logs: const [],
    );
  }

  group('Task Display with Project/Milestone', () {
    testWidgets('InboxPage should display tasks with projectId', (tester) async {
      final regularTask = createTask(id: 1, status: TaskStatus.inbox);
      final taskWithProject = createTask(
        id: 2,
        status: TaskStatus.inbox,
        projectId: 'prj-test-001',
      );
      final taskWithMilestone = createTask(
        id: 3,
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
            inboxTaskLevelMapProvider.overrideWith((ref) async => {
              regularTask.id: 1,
              taskWithProject.id: 1,
              taskWithMilestone.id: 1,
            }),
            inboxTaskChildrenMapProvider.overrideWith((ref) async => <int, Set<int>>{}),
            taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
            templateSuggestionsProvider.overrideWithProvider(
              (query) => FutureProvider((ref) async => const <TaskTemplate>[]),
            ),
            contextTagOptionsProvider.overrideWith((ref) async => const <Tag>[]),
            urgencyTagOptionsProvider.overrideWith((ref) async => const <Tag>[]),
            importanceTagOptionsProvider.overrideWith((ref) async => const <Tag>[]),
            executionTagOptionsProvider.overrideWith((ref) async => const <Tag>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const InboxPage(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证所有任务都应该显示
      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Task 2 (Project)'), findsOneWidget);
      expect(find.text('Task 3 (Milestone)'), findsOneWidget);
    });

    testWidgets('TaskSectionPanel should display tasks with projectId', (tester) async {
      final regularTask = createTask(
        id: 1,
        status: TaskStatus.pending,
        dueAt: DateTime(2025, 11, 2, 23, 59, 59),
      );
      final taskWithProject = createTask(
        id: 2,
        status: TaskStatus.pending,
        projectId: 'prj-test-001',
        dueAt: DateTime(2025, 11, 2, 23, 59, 59),
      );
      final taskWithMilestone = createTask(
        id: 3,
        status: TaskStatus.pending,
        milestoneId: 'mil-test-001',
        dueAt: DateTime(2025, 11, 2, 23, 59, 59),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskRepositoryProvider.overrideWith((ref) {
              // 创建一个返回所有 today 任务的 repository（包括关联项目的）
              return _TestTaskRepository([
                regularTask,
                taskWithProject,
                taskWithMilestone,
              ]);
            }),
            taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
            tasksSectionTaskLevelMapProvider.overrideWith(
              (ref, section) async => {
                regularTask.id: 1,
                taskWithProject.id: 1,
                taskWithMilestone.id: 1,
              },
            ),
            tasksSectionTaskChildrenMapProvider.overrideWith(
              (ref, section) async => <int, Set<int>>{},
            ),
            tasksSectionExpandedTaskIdProvider.overrideWith(
              (ref, section) => <int>{},
            ),
            tasksSectionDragProvider.overrideWith(
              (ref, section) => TasksSectionDragNotifier(),
            ),
            urgencyTagOptionsProvider.overrideWith((ref) async => const <Tag>[]),
            importanceTagOptionsProvider.overrideWith((ref) async => const <Tag>[]),
            executionTagOptionsProvider.overrideWith((ref) async => const <Tag>[]),
            contextTagOptionsProvider.overrideWith((ref) async => const <Tag>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TaskSectionPanel(
                section: TaskSection.today,
                title: 'Today',
                editMode: false,
                onQuickAdd: () {},
                tasks: [
                  regularTask,
                  taskWithProject,
                  taskWithMilestone,
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(); // Pump again to allow async providers to resolve

      // 验证所有任务都应该显示
      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Task 2 (Project)'), findsOneWidget);
      expect(find.text('Task 3 (Milestone)'), findsOneWidget);
    });
  });
}

/// 测试用的 TaskRepository，直接返回传入的任务列表
class _TestTaskRepository implements TaskRepository {
  final List<Task> _tasks;

  _TestTaskRepository(this._tasks);

  @override
  Stream<List<Task>> watchSection(TaskSection section) {
    // 根据 section 过滤任务
    final filtered = _tasks.where((task) {
      if (section == TaskSection.today) {
        return task.status == TaskStatus.pending &&
            task.dueAt != null &&
            task.dueAt!.year == 2025 &&
            task.dueAt!.month == 11 &&
            task.dueAt!.day == 2;
      }
      return false;
    }).toList();
    return Stream.value(filtered);
  }

  @override
  Stream<List<Task>> watchInbox() {
    return Stream.value(
      _tasks.where((task) => task.status == TaskStatus.inbox).toList(),
    );
  }

  // 其他必需的方法实现为抛出异常或返回空值
  @override
  Stream<TaskTreeNode> watchTaskTree(int rootTaskId) =>
      throw UnimplementedError();

  @override
  Stream<List<Task>> watchProjects() => throw UnimplementedError();

  @override
  Stream<List<Task>> watchQuickTasks() => Stream.value([]);

  @override
  Stream<List<Task>> watchMilestones(int projectId) =>
      throw UnimplementedError();

  @override
  Stream<List<Task>> watchTasksByProjectId(String projectId) =>
      Stream.value([]);

  @override
  Stream<List<Task>> watchTasksByMilestoneId(String milestoneId) =>
      Stream.value([]);

  @override
  Future<List<Task>> listTasksByMilestoneId(String milestoneId) async => [];

  @override
  Stream<List<Task>> watchInboxFiltered({
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
  }) {
    // 返回所有 inbox 任务（测试中不过滤标签）
    return Stream.value(
      _tasks.where((task) => task.status == TaskStatus.inbox).toList(),
    );
  }

  @override
  Future<Task> createTask(TaskDraft draft) =>
      throw UnimplementedError();

  @override
  Future<void> updateTask(int taskId, TaskUpdate payload) =>
      throw UnimplementedError();

  @override
  Future<void> moveTask({
    required int taskId,
    required int? targetParentId,
    required TaskSection targetSection,
    required double sortIndex,
    DateTime? dueAt,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> markStatus({required int taskId, required TaskStatus status}) =>
      throw UnimplementedError();

  @override
  Future<void> archiveTask(int taskId) => throw UnimplementedError();

  @override
  Future<void> softDelete(int taskId) => throw UnimplementedError();

  @override
  Future<int> purgeObsolete(DateTime olderThan) async => 0;

  @override
  Future<void> adjustTemplateLock({required int taskId, required int delta}) =>
      throw UnimplementedError();

  @override
  Future<Task?> findById(int id) async =>
      _tasks.firstWhere((t) => t.id == id, orElse: () => throw StateError('Task not found'));

  @override
  Stream<Task?> watchTaskById(int id) => Stream.value(
      _tasks.firstWhere((t) => t.id == id, orElse: () => throw StateError('Task not found')));

  @override
  Future<Task?> findBySlug(String slug) async => null;

  @override
  Future<List<Task>> listRoots() async => [];

  @override
  Future<List<Task>> listChildren(int parentId) async => [];

  @override
  Future<void> upsertTasks(List<Task> tasks) => throw UnimplementedError();

  @override
  Future<List<Task>> listAll() async => _tasks;

  @override
  Future<List<Task>> searchByTitle(
    String query, {
    TaskStatus? status,
    int limit = 10,
  }) async =>
      [];

  @override
  Future<void> batchUpdate(Map<int, TaskUpdate> updates) =>
      throw UnimplementedError();

  @override
  Future<List<Task>> listSectionTasks(TaskSection section) async => [];
}
