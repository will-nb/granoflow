import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/data/models/tag.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/data/models/task_template.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/services/task_service.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/inbox/inbox_page.dart';
import 'package:granoflow/core/theme/app_theme.dart';

Tag _tag(String slug, TagKind kind) => Tag(
  id: slug.hashCode,
  slug: slug,
  kind: kind,
  localizedLabels: {'en': slug},
);

Task _task(String id, String title) => Task(
  id: id,

  title: title,
  status: TaskStatus.inbox,
  createdAt: DateTime(2025, 1, 1),
  updatedAt: DateTime(2025, 1, 1),
  tags: const <String>[],
);

TaskTemplate _template(String title) => TaskTemplate(
  id: title.hashCode,
  title: title,
  createdAt: DateTime(2025, 1, 1),
  updatedAt: DateTime(2025, 1, 1),
);

class _NoopTaskService extends Fake implements TaskService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('InboxPage shows empty placeholder when no tasks', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inboxTasksProvider.overrideWith(
            (ref) => Stream<List<Task>>.value(const <Task>[]),
          ),
          inboxTaskLevelMapProvider.overrideWith(
            (ref) async => <String, int>{},
          ),
          inboxTaskChildrenMapProvider.overrideWith(
            (ref) async => <String, Set<String>>{},
          ),
          templateSuggestionsProvider.overrideWithProvider(
            (query) => FutureProvider(
              (ref) async => <TaskTemplate>[_template('Template')],
            ),
          ),
          contextTagOptionsProvider.overrideWith(
            (ref) async => <Tag>[_tag('@home', TagKind.context)],
          ),
          urgencyTagOptionsProvider.overrideWith((ref) async => const <Tag>[]),
          importanceTagOptionsProvider.overrideWith(
            (ref) async => const <Tag>[],
          ),
          executionTagOptionsProvider.overrideWith(
            (ref) async => const <Tag>[],
          ),
          taskServiceProvider.overrideWith((ref) => _NoopTaskService()),
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

    final l10n = AppLocalizations.of(tester.element(find.byType(InboxPage)));
    expect(find.text(l10n.inboxEmptyTitle), findsOneWidget);
  });

  testWidgets('InboxPage renders inbox tasks', (tester) async {
    final task = _task(1, 'Inbox Item');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inboxTasksProvider.overrideWith(
            (ref) => Stream<List<Task>>.value(<Task>[task]),
          ),
          inboxTaskLevelMapProvider.overrideWith(
            (ref) async => <String, int>{task.id: 1},
          ),
          inboxTaskChildrenMapProvider.overrideWith(
            (ref) async => <String, Set<String>>{},
          ),
          templateSuggestionsProvider.overrideWithProvider(
            (query) => FutureProvider((ref) async => const <TaskTemplate>[]),
          ),
          contextTagOptionsProvider.overrideWith((ref) async => const <Tag>[]),
          urgencyTagOptionsProvider.overrideWith((ref) async => const <Tag>[]),
          importanceTagOptionsProvider.overrideWith(
            (ref) async => const <Tag>[],
          ),
          executionTagOptionsProvider.overrideWith(
            (ref) async => const <Tag>[],
          ),
          taskServiceProvider.overrideWith((ref) => _NoopTaskService()),
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

    expect(find.text('Inbox Item'), findsOneWidget);
  });
}
