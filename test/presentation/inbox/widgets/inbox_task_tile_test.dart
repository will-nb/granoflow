import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/services/task_service.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/data/models/tag.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/inbox/widgets/inbox_task_tile.dart';
import 'package:granoflow/core/theme/app_theme.dart';

class _StubTag extends Tag {
  _StubTag(String slug, TagKind kind)
    : super(
        id: slug.hashCode.toString(),
        slug: slug,
        kind: kind,
        localizedLabels: {'en': slug},
      );
}

class _RecordingTaskService extends Fake implements TaskService {
  bool quickPlanCalled = false;
  bool deleteCalled = false;

  @override
  Future<void> planTask({
    required String taskId,
    required DateTime dueDateLocal,
    required TaskSection section,
  }) async {
    quickPlanCalled = true;
  }

  @override
  Future<void> softDelete(String taskId) async {
    deleteCalled = true;
  }
}

void main() {
  Task buildTask() {
    return Task(
      id: '10',

      title: 'Inbox task',
      status: TaskStatus.inbox,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      tags: const <String>[],
    );
  }

  testWidgets('InboxTaskTile swipe right triggers quick plan', (tester) async {
    final taskService = _RecordingTaskService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskServiceProvider.overrideWith((ref) => taskService),
          contextTagOptionsProvider.overrideWith(
            (ref) async => [_StubTag('home', TagKind.context)],
          ),
          urgencyTagOptionsProvider.overrideWith((ref) async => const <Tag>[]),
          importanceTagOptionsProvider.overrideWith(
            (ref) async => const <Tag>[],
          ),
            (ref) async => const <Tag>[],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: InboxTaskTile(task: buildTask())),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
    await dismissible.confirmDismiss!(DismissDirection.startToEnd);
    await tester.pump();

    expect(taskService.quickPlanCalled, isTrue);
  });

  testWidgets('InboxTaskTile swipe left triggers delete', (tester) async {
    final taskService = _RecordingTaskService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskServiceProvider.overrideWith((ref) => taskService),
          contextTagOptionsProvider.overrideWith(
            (ref) async => [_StubTag('home', TagKind.context)],
          ),
          urgencyTagOptionsProvider.overrideWith((ref) async => const <Tag>[]),
          importanceTagOptionsProvider.overrideWith(
            (ref) async => const <Tag>[],
          ),
            (ref) async => const <Tag>[],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: InboxTaskTile(task: buildTask())),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
    final future = dismissible.confirmDismiss!(DismissDirection.endToStart);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await future;

    expect(taskService.deleteCalled, isTrue);
  });
}
