import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/tasks/quick_tasks/quick_tasks_section.dart';

Task _createTask({required String id}) {
  final idNum = int.tryParse(id) ?? 0;
  return Task(
    id: id,

    title: 'Quick Task $id',
    status: TaskStatus.pending,
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

  testWidgets('QuickTasksCollapsibleSection toggles expansion', (tester) async {
    final task = _createTask(id: '1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskTreeProvider.overrideWithProvider((taskId) {
            return StreamProvider<TaskTreeNode>((ref) {
              final nodeTask = task.copyWith(id: taskId);
              return Stream.value(
                TaskTreeNode(task: nodeTask, children: const <TaskTreeNode>[]),
              );
            });
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: QuickTasksCollapsibleSection(
              asyncTasks: AsyncValue.data(<Task>[task]),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    final context = tester.element(find.byType(Scaffold));
    final l10n = AppLocalizations.of(context);

    expect(find.text(l10n.projectQuickTasksTitle), findsOneWidget);
    expect(find.text('Quick Task 1'), findsNothing);

    await tester.tap(find.text(l10n.projectQuickTasksTitle));
    await tester.pumpAndSettle();

    expect(find.text('Quick Task 1'), findsOneWidget);
  });
}

