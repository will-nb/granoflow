import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/services/task_service.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/data/models/tag.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/inbox/views/inbox_task_list.dart';
import 'package:granoflow/core/theme/app_theme.dart';

class _StubTag extends Tag {
  _StubTag(String slug, TagKind kind)
      : super(id: slug.hashCode, slug: slug, kind: kind, localizedLabels: {'en': slug});
}

class _RecordingTaskService extends Fake implements TaskService {
  int? updatedTaskId;
  double? receivedSortIndex;

  @override
  Future<void> updateDetails({
    required int taskId,
    required TaskUpdate payload,
  }) async {
    updatedTaskId = taskId;
    receivedSortIndex = payload.sortIndex;
  }
}

void main() {
  testWidgets('InboxTaskList reorders tasks and updates sort index', (tester) async {
    final taskService = _RecordingTaskService();

    final tasks = <Task>[
      Task(
        id: 1,
        taskId: 'task-1',
        title: 'First Task',
        status: TaskStatus.inbox,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        sortIndex: 1000,
        tags: const <String>[],
      ),
      Task(
        id: 2,
        taskId: 'task-2',
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
          taskServiceProvider.overrideWith((ref) => taskService),
          contextTagOptionsProvider.overrideWith((ref) async => [_StubTag('@home', TagKind.context)]),
          urgencyTagOptionsProvider.overrideWith((ref) async => [_StubTag('#urgent', TagKind.urgency)]),
          importanceTagOptionsProvider.overrideWith((ref) async => [_StubTag('#important', TagKind.importance)]),
          executionTagOptionsProvider.overrideWith((ref) async => const <Tag>[]),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: InboxTaskList(tasks: tasks),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final listView = tester.widget<ReorderableListView>(find.byType(ReorderableListView));
    listView.onReorder(1, 0);
    await tester.pump();

    expect(taskService.updatedTaskId, equals(2));
    expect(taskService.receivedSortIndex, equals(0));
  });
}

