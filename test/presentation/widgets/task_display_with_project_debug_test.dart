import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/core/providers/repository_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/providers/tasks_drag_provider.dart';
import 'package:granoflow/core/services/task_service.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/data/repositories/task_repository.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/inbox/inbox_page.dart';
import 'package:granoflow/presentation/tasks/views/task_section_panel.dart';
import 'package:granoflow/core/theme/app_theme.dart';
import 'package:granoflow/data/models/tag.dart';
import 'package:granoflow/data/models/task_template.dart';
import 'package:granoflow/presentation/tasks/utils/task_collection_utils.dart';
import 'package:granoflow/presentation/tasks/utils/hierarchy_utils.dart';

class _FakeTaskService extends Fake implements TaskService {}

/// 调试测试：验证 inbox 和 tasks 页面是否都能显示所有根任务
/// 
/// 测试场景：
/// 1. 普通任务（无 projectId/milestoneId）- 应该在两个页面都显示
/// 2. 关联项目的任务（有 projectId）- 应该在两个页面都显示
/// 3. 关联里程碑的任务（有 milestoneId）- 应该在两个页面都显示
/// 
/// 关键问题：isProjectOrMilestone 函数会过滤掉关联项目的任务，这是错误的
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 创建测试用的任务
  Task createTask({
    required int id,
    String? projectId,
    String? milestoneId,
    TaskStatus status = TaskStatus.inbox,
    DateTime? dueAt,
    int? parentId,
  }) {
    return Task(
      id: id,
      taskId: 'task-$id',
      title: 'Task $id${projectId != null ? " (Project)" : ""}${milestoneId != null ? " (Milestone)" : ""}',
      status: status,
      projectId: projectId,
      milestoneId: milestoneId,
      parentId: parentId,
      sortIndex: id.toDouble() * 1024,
      dueAt: dueAt ?? (status == TaskStatus.pending ? DateTime(2025, 11, 2, 23, 59, 59) : null),
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      tags: const [],
      templateLockCount: 0,
      logs: const [],
    );
  }

  group('Task Display Debug Tests - All Root Tasks Should Display', () {
    testWidgets('InboxPage should display ALL root tasks including those with projectId', (tester) async {
      // 创建根任务：1个普通任务，1个关联项目的任务，1个关联里程碑的任务
      final regularRootTask = createTask(id: 1, status: TaskStatus.inbox);
      final rootTaskWithProject = createTask(
        id: 2,
        status: TaskStatus.inbox,
        projectId: 'prj-test-001',
      );
      final rootTaskWithMilestone = createTask(
        id: 3,
        status: TaskStatus.inbox,
        milestoneId: 'mil-test-001',
      );

      // 调试：检查 collectRoots 和 isProjectOrMilestone 的行为
      final allTasks = [regularRootTask, rootTaskWithProject, rootTaskWithMilestone];
      final roots = collectRoots(allTasks);
      print('=== Inbox Debug ===');
      print('All tasks: ${allTasks.length}');
      print('Root tasks (before filter): ${roots.length}');
      print('Root task IDs: ${roots.map((t) => t.id).toList()}');
      
      // 检查每个根任务是否被 isProjectOrMilestone 过滤
      for (final root in roots) {
        final isFiltered = isProjectOrMilestone(root);
        print('Task ${root.id} (projectId: ${root.projectId}, milestoneId: ${root.milestoneId}): isProjectOrMilestone = $isFiltered');
      }
      
      final filteredRoots = roots.where((task) => !isProjectOrMilestone(task)).toList();
      print('Root tasks (after filter): ${filteredRoots.length}');
      print('Filtered root task IDs: ${filteredRoots.map((t) => t.id).toList()}');
      print('========================');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskRepositoryProvider.overrideWith((ref) {
              return _TestTaskRepository([
                regularRootTask,
                rootTaskWithProject,
                rootTaskWithMilestone,
              ]);
            }),
            inboxTaskLevelMapProvider.overrideWith((ref) async => {
              regularRootTask.id: 1,
              rootTaskWithProject.id: 1,
              rootTaskWithMilestone.id: 1,
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

      // 验证所有根任务都应该显示
      // 注意：如果任务被过滤掉，这里会失败
      expect(find.text('Task 1'), findsOneWidget, reason: 'Regular root task should be displayed');
      expect(find.text('Task 2 (Project)'), findsOneWidget, reason: 'Root task with projectId should be displayed');
      expect(find.text('Task 3 (Milestone)'), findsOneWidget, reason: 'Root task with milestoneId should be displayed');
    });

    testWidgets('TaskSectionPanel should display ALL root tasks including those with projectId', (tester) async {
      // 创建根任务：1个普通任务，1个关联项目的任务，1个关联里程碑的任务
      final regularRootTask = createTask(
        id: 1,
        status: TaskStatus.pending,
        dueAt: DateTime(2025, 11, 2, 23, 59, 59),
      );
      final rootTaskWithProject = createTask(
        id: 2,
        status: TaskStatus.pending,
        projectId: 'prj-test-001',
        dueAt: DateTime(2025, 11, 2, 23, 59, 59),
      );
      final rootTaskWithMilestone = createTask(
        id: 3,
        status: TaskStatus.pending,
        milestoneId: 'mil-test-001',
        dueAt: DateTime(2025, 11, 2, 23, 59, 59),
      );

      // 调试：检查 collectRoots 和 isProjectOrMilestone 的行为
      final allTasks = [regularRootTask, rootTaskWithProject, rootTaskWithMilestone];
      final roots = collectRoots(allTasks);
      print('=== Tasks Debug ===');
      print('All tasks: ${allTasks.length}');
      print('Root tasks (before filter): ${roots.length}');
      print('Root task IDs: ${roots.map((t) => t.id).toList()}');
      
      // 检查每个根任务是否被 isProjectOrMilestone 过滤
      for (final root in roots) {
        final isFiltered = isProjectOrMilestone(root);
        print('Task ${root.id} (projectId: ${root.projectId}, milestoneId: ${root.milestoneId}): isProjectOrMilestone = $isFiltered');
      }
      
      final filteredRoots = roots.where((task) => !isProjectOrMilestone(task)).toList();
      print('Root tasks (after filter): ${filteredRoots.length}');
      print('Filtered root task IDs: ${filteredRoots.map((t) => t.id).toList()}');
      print('========================');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskRepositoryProvider.overrideWith((ref) {
              return _TestTaskRepository([
                regularRootTask,
                rootTaskWithProject,
                rootTaskWithMilestone,
              ]);
            }),
            taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
            tasksSectionTaskLevelMapProvider.overrideWith(
              (ref, section) async => {
                regularRootTask.id: 1,
                rootTaskWithProject.id: 1,
                rootTaskWithMilestone.id: 1,
              },
            ),
            tasksSectionTaskChildrenMapProvider.overrideWith(
              (ref, section) async => <int, Set<int>>{},
            ),
            tasksSectionExpandedTaskIdProvider.overrideWith(
              (ref, section) => <int>{},
            ),
            tasksDragProvider.overrideWith(
              (ref) => TasksDragNotifier(),
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
                  regularRootTask,
                  rootTaskWithProject,
                  rootTaskWithMilestone,
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(); // Pump again to allow async providers to resolve

      // 验证所有根任务都应该显示
      // 注意：如果任务被过滤掉，这里会失败
      expect(find.text('Task 1'), findsOneWidget, reason: 'Regular root task should be displayed');
      expect(find.text('Task 2 (Project)'), findsOneWidget, reason: 'Root task with projectId should be displayed');
      expect(find.text('Task 3 (Milestone)'), findsOneWidget, reason: 'Root task with milestoneId should be displayed');
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
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
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
  Future<int> clearAllTrashedTasks() async => 0;

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

  @override
  Future<List<Task>> listCompletedTasks({
    required int limit,
    required int offset,
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  }) async => [];

  @override
  Future<List<Task>> listArchivedTasks({
    required int limit,
    required int offset,
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  }) async => [];

  @override
  Future<int> countCompletedTasks() async => 0;

  @override
  Future<int> countArchivedTasks() async => 0;

  @override
  Future<List<Task>> listTrashedTasks({
    required int limit,
    required int offset,
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  }) async => [];

  @override
  Future<int> countTrashedTasks() async => 0;
}

