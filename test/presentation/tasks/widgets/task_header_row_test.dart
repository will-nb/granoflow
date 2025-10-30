import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/services/task_service.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/tasks/widgets/task_header_row.dart';

class _FakeTaskService extends Fake implements TaskService {}

void main() {
  testWidgets('TaskHeaderRow renders title and convert icon', (tester) async {
    final task = Task(
      id: 1,
      taskId: 'task-1',
      title: 'Header Task',
      status: TaskStatus.pending,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      dueAt: DateTime(2025, 1, 2),
      tags: const [],
      templateLockCount: 0,
      allowInstantComplete: false,
      logs: const [],
      taskKind: TaskKind.regular,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TaskHeaderRow(
              task: task,
              showConvertAction: true,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Header Task'), findsOneWidget);
    expect(find.byIcon(Icons.autorenew), findsOneWidget);
  });
}
