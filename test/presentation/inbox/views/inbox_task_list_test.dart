import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/services/task_service.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/inbox/views/inbox_task_list.dart';
import 'package:granoflow/core/theme/app_theme.dart';

class _FakeTaskService extends Fake implements TaskService {}

void main() {
  group('InboxTaskList', () {
    testWidgets('should render tasks list correctly', (tester) async {
      final tasks = <Task>[
        Task(
          id: '1',

          title: 'First Task',
          status: TaskStatus.inbox,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
          sortIndex: 1000,
          tags: const <String>[],
        ),
        Task(
          id: '2',

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
            taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
            contextTagOptionsProvider.overrideWith((ref) async => const []),
            urgencyTagOptionsProvider.overrideWith((ref) async => const []),
            importanceTagOptionsProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: InboxTaskList(tasks: tasks)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证任务列表正确显示
      expect(find.text('First Task'), findsOneWidget);
      expect(find.text('Second Task'), findsOneWidget);
    });
  });
}
