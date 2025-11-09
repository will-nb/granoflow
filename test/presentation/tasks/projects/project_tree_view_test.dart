import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/services/task_service.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/tasks/projects/project_tree_view.dart';

class _FakeTaskService extends Fake implements TaskService {}

class _FakeTaskEditActions extends TaskEditActionsNotifier {
  @override
  Future<void> build() async {}

  @override
  Future<void> addSubtask({
    required String parentId,
    required String title,
  }) async {}

  @override
  Future<void> editTitle({
    required String taskId,
    required String title,
  }) async {}

  @override
  Future<void> archive(String taskId) async {}
}

void main() {
  testWidgets('ProjectTreeView expands to show children', (tester) async {
    final parent = Task(
      id: 1,

      title: 'Parent Task',
      status: TaskStatus.pending,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      parentId: null,

      projectId: null,
      milestoneId: null,
      sortIndex: 0,
      tags: const <String>[],
      templateLockCount: 0,
      seedSlug: null,
      allowInstantComplete: false,
      description: null,
      logs: const <TaskLogEntry>[],
    );
    final child = Task(
      id: 2,

      title: 'Child Task',
      status: TaskStatus.pending,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      parentId: 1,

      projectId: null,
      milestoneId: null,
      sortIndex: 1,
      tags: const <String>[],
      templateLockCount: 0,
      seedSlug: null,
      allowInstantComplete: false,
      description: null,
      logs: const <TaskLogEntry>[],
    );
    final tree = TaskTreeNode(
      task: parent,
      children: [TaskTreeNode(task: child, children: const [])],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expandedRootTaskIdProvider.overrideWith((ref) => parent.id),
          taskTreeProvider.overrideWithProvider((taskId) {
            return StreamProvider<TaskTreeNode>((ref) => Stream.value(tree));
          }),
          taskEditActionsNotifierProvider.overrideWith(
            () => _FakeTaskEditActions(),
          ),
          taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProjectTreeView(
                tree: tree,
                section: TaskSection.thisMonth,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Parent Task'), findsOneWidget);
  });
}
