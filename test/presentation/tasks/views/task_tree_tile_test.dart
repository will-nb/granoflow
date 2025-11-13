import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/services/task_service.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/tasks/views/task_tree_tile.dart';

class _FakeTaskService extends Fake implements TaskService {}

Task _createTask({required String id, DateTime? dueAt}) {
  // 层级功能已移除，不再需要 parentId 参数
  final taskDueAt = dueAt ?? DateTime(2025, 1, 15); // 使用固定日期
  final idNum = int.tryParse(id) ?? 0;
  return Task(
    id: id,
    title: 'Task $id',
    status: TaskStatus.pending,
    dueAt: taskDueAt,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    sortIndex: idNum.toDouble(),
    tags: const [],
    templateLockCount: 0,
    allowInstantComplete: false,
    logs: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TaskTreeTile renders task', (tester) async {
    // 层级功能已移除，所有任务都是平级的
    final today = DateTime.now();
    final root = _createTask(id: '1', dueAt: today);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
          taskTreeProvider.overrideWithProvider((taskId) {
            return StreamProvider<TaskTreeNode>((ref) {
              // 层级功能已移除，所有任务树只包含单个任务
              return Stream.value(
                TaskTreeNode(
                  task: root.copyWith(id: taskId),
                  children: const <TaskTreeNode>[],
                ),
              );
            });
          }),
          contextTagOptionsProvider.overrideWith((ref) async => const []),
          priorityTagOptionsProvider.overrideWith((ref) async => const []),
          urgencyTagOptionsProvider.overrideWith((ref) async => const []),
          importanceTagOptionsProvider.overrideWith((ref) async => const []),
          taskProjectHierarchyProvider.overrideWith(
            (ref, taskId) => Stream.value(null),
          ),
          // 层级功能已移除，不再需要 parentTaskProvider
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TaskTreeTile(
              section: TaskSection.today,
              rootTask: root,
              editMode: false,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Task 1'), findsOneWidget);
    await tester.pumpAndSettle();

    // 不再显示子任务，所以不需要测试子任务显示
  });
}
