import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/presentation/tasks/utils/tree_flattening_utils.dart';
import 'package:granoflow/presentation/tasks/widgets/task_hierarchy_list.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';

void main() {
  testWidgets('TaskHierarchyList returns SizedBox when nodes empty', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TaskHierarchyList(nodes: [])),
      ),
    );

    expect(find.byType(SizedBox), findsWidgets);
  });

  testWidgets('TaskHierarchyList renders entries for nodes', (tester) async {
    final task = Task(
      id: 1,
      taskId: 'task-1',
      title: 'Child Task',
      status: TaskStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final nodes = [FlattenedTaskNode(task, 1)];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          urgencyTagOptionsProvider.overrideWith((ref) async => const []),
          importanceTagOptionsProvider.overrideWith((ref) async => const []),
          executionTagOptionsProvider.overrideWith((ref) async => const []),
          contextTagOptionsProvider.overrideWith((ref) async => const []),
          taskServiceProvider.overrideWith((ref) => throw UnimplementedError()),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TaskHierarchyList(nodes: nodes)),
        ),
      ),
    );

    expect(find.text('Child Task'), findsOneWidget);
  });
}

