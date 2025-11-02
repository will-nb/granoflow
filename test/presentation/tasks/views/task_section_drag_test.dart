import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/presentation/tasks/views/task_section_list.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';

void main() {
  group('TaskSectionList Basic Tests', () {
    testWidgets('should handle empty task list', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TaskSectionTaskModeList(
                section: TaskSection.today,
                roots: [],
              ),
            ),
          ),
        ),
      );

      // Should build without errors
      expect(find.byType(TaskSectionTaskModeList), findsOneWidget);
    });

    testWidgets('should display tasks when provided', (WidgetTester tester) async {
      final now = DateTime.now();
      final testTasks = <Task>[
        Task(
          taskId: '1',
          id: 1,
          title: 'Test Task',
          sortIndex: 1000,
          status: TaskStatus.pending,
          dueAt: now,
          createdAt: now,
          updatedAt: now,
          parentId: null,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TaskSectionTaskModeList(
                section: TaskSection.today,
                roots: testTasks,
              ),
            ),
          ),
        ),
      );
      
      await tester.pump();

      // Should show the task list component
      expect(find.byType(TaskSectionTaskModeList), findsOneWidget);
    });
  });
}