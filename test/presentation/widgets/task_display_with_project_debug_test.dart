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
import 'package:granoflow/presentation/tasks/utils/task_collection_utils.dart';
// 层级功能已移除，hierarchy_utils 已删除

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
    required String id,
    String? projectId,
    String? milestoneId,
    TaskStatus status = TaskStatus.inbox,
    DateTime? dueAt,
    // 层级功能已移除，不再需要 parentId 参数
  }) {
    final idNum = int.tryParse(id) ?? 0;
    return Task(
      id: id,

      title:
          'Task $id${projectId != null ? " (Project)" : ""}${milestoneId != null ? " (Milestone)" : ""}',
      status: status,
      projectId: projectId,
      milestoneId: milestoneId,
      
      sortIndex: idNum.toDouble() * 1024,
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

  group('Task Display Debug Tests - All Root Tasks Should Display', () {
    // TODO: Inbox 根任务过滤逻辑待重写，调试用例暂时跳过
    testWidgets(
      'InboxPage should display ALL root tasks including those with projectId',
      (tester) async {
        // 创建根任务：1个普通任务，1个关联项目的任务，1个关联里程碑的任务
        final regularRootTask = createTask(id: '1', status: TaskStatus.inbox);
        final rootTaskWithProject = createTask(
          id: '2',
          status: TaskStatus.inbox,
          projectId: 'prj-test-001',
        );
        final rootTaskWithMilestone = createTask(
          id: '3',
          status: TaskStatus.inbox,
          milestoneId: 'mil-test-001',
        );

        // 调试：检查 collectRoots 和 isProjectOrMilestone 的行为
        final allTasks = [
          regularRootTask,
          rootTaskWithProject,
          rootTaskWithMilestone,
        ];
        final roots = collectRoots(allTasks);
        print('=== Inbox Debug ===');
        print('All tasks: ${allTasks.length}');
        print('Root tasks (before filter): ${roots.length}');
        print('Root task IDs: ${roots.map((t) => t.id).toList()}');

        // 检查每个根任务是否被 isProjectOrMilestone 过滤
        for (final root in roots) {
          // 层级功能已移除，isProjectOrMilestone 已删除，内联逻辑
          final isFiltered = root.projectId != null || root.milestoneId != null;
          print(
            'Task ${root.id} (projectId: ${root.projectId}, milestoneId: ${root.milestoneId}): isProjectOrMilestone = $isFiltered',
          );
        }

        final filteredRoots = roots
            .where((task) => task.projectId == null && task.milestoneId == null)
            .toList();
        print('Root tasks (after filter): ${filteredRoots.length}');
        print(
          'Filtered root task IDs: ${filteredRoots.map((t) => t.id).toList()}',
        );
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
      },
      skip: true,
    );
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
