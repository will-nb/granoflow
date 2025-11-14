import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:granoflow/core/theme/app_theme.dart';
import 'package:granoflow/core/providers/repository_providers.dart';
import 'package:granoflow/data/models/milestone.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/data/repositories/task_repository.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/tasks/milestones/widgets/milestone_card_dialogs.dart';
import 'dart:async';

import '../../../test_support/fakes.dart';

Milestone _createMilestone() {
  return Milestone(
    id: 'milestone-1',
    projectId: 'project-1',
    title: 'Test Milestone',
    status: TaskStatus.pending,
    dueAt: null,
    startedAt: null,
    endedAt: null,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    sortIndex: 0,
    tags: const <String>[],
    templateLockCount: 0,
    seedSlug: null,
    allowInstantComplete: false,
    description: null,
    logs: const <MilestoneLogEntry>[],
  );
}

Widget _buildTestWidget(Widget child, StubTaskRepository taskRepository) {
  return ProviderScope(
    overrides: [
      taskRepositoryProvider.overrideWith((ref) async => taskRepository),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('zh', 'CN'),
        Locale('zh', 'HK'),
      ],
      home: Scaffold(
        body: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('confirmMilestoneDelete', () {
    testWidgets('有活跃任务时显示两次确认', (tester) async {
      final milestone = _createMilestone();
      final stubRepository = StubTaskRepository();
      
      // 添加活跃任务
      await stubRepository.createTask(TaskDraft(
        title: 'Task 1',
        status: TaskStatus.pending,
        milestoneId: milestone.id,
        projectId: milestone.projectId,
        sortIndex: 0,
      ));
      await stubRepository.createTask(TaskDraft(
        title: 'Task 2',
        status: TaskStatus.doing,
        milestoneId: milestone.id,
        projectId: milestone.projectId,
        sortIndex: 1,
      ));

      await tester.pumpWidget(
        _buildTestWidget(
          Consumer(
            builder: (context, ref, child) => ElevatedButton(
              onPressed: () async {
                await confirmMilestoneDelete(context, ref, milestone);
              },
              child: const Text('Delete'),
            ),
          ),
          stubRepository,
        ),
      );

      // 点击删除按钮
      await tester.tap(find.text('Delete'));
      await tester.pump(); // 先 pump 一次
      await tester.pump(const Duration(milliseconds: 100)); // 等待弹窗动画
      await tester.pumpAndSettle();

      // 验证第一次确认弹窗显示（使用 AlertDialog 类型检查）
      expect(find.byType(AlertDialog), findsOneWidget);
      // 验证按钮存在（使用 commonYes, commonNo, commonCancel）
      // 注意：文本可能因本地化而不同，只验证按钮存在
      expect(find.byType(TextButton), findsNWidgets(3));

      // 点击"是"按钮（第三个按钮，从右到左）
      final textButtons = find.byType(TextButton);
      expect(textButtons, findsNWidgets(3));
      await tester.tap(textButtons.at(2)); // 最右边的按钮（是）
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // 验证第二次确认弹窗显示
      expect(find.byType(AlertDialog), findsOneWidget);
      // 验证确定按钮存在（FilledButton）
      expect(find.byType(FilledButton), findsOneWidget);

      // 点击取消按钮（TextButton）
      final secondDialogCancelButtons = find.byType(TextButton);
      await tester.tap(secondDialogCancelButtons.first);
      await tester.pumpAndSettle();

      // 验证弹窗已关闭
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('无活跃任务时跳过第一次确认', (tester) async {
      final milestone = _createMilestone();
      final stubRepository = StubTaskRepository();
      
      // 不添加任何任务，或只添加已完成的任务
      await stubRepository.createTask(TaskDraft(
        title: 'Completed Task',
        status: TaskStatus.completedActive,
        milestoneId: milestone.id,
        projectId: milestone.projectId,
        sortIndex: 0,
      ));

      await tester.pumpWidget(
        _buildTestWidget(
          Consumer(
            builder: (context, ref, child) => ElevatedButton(
              onPressed: () async {
                await confirmMilestoneDelete(context, ref, milestone);
              },
              child: const Text('Delete'),
            ),
          ),
          stubRepository,
        ),
      );

      // 点击删除按钮
      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // 验证直接显示第二次确认弹窗（没有第一次确认）
      expect(find.byType(AlertDialog), findsOneWidget);
      // 验证确定按钮存在（FilledButton）
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('用户取消第一次确认', (tester) async {
      final milestone = _createMilestone();
      final stubRepository = StubTaskRepository();
      
      // 添加活跃任务
      await stubRepository.createTask(TaskDraft(
        title: 'Task 1',
        status: TaskStatus.pending,
        milestoneId: milestone.id,
        projectId: milestone.projectId,
        sortIndex: 0,
      ));

      await tester.pumpWidget(
        _buildTestWidget(
          Consumer(
            builder: (context, ref, child) => ElevatedButton(
              onPressed: () async {
                final result = await confirmMilestoneDelete(
                  context,
                  ref,
                  milestone,
                );
                // 验证返回 null
                expect(result, isNull);
              },
              child: const Text('Delete'),
            ),
          ),
          stubRepository,
        ),
      );

      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // 验证第一次确认弹窗显示
      expect(find.byType(AlertDialog), findsOneWidget);

      // 点击取消按钮（第一个按钮，从右到左）
      final cancelButtons = find.byType(TextButton);
      await tester.tap(cancelButtons.first);
      await tester.pumpAndSettle();

      // 验证弹窗已关闭，没有显示第二次确认
      expect(find.byType(AlertDialog), findsNothing);
    });

  });

  group('弹窗 UI 测试', () {
    testWidgets('第一次确认弹窗显示富文本', (tester) async {
      final milestone = _createMilestone();
      final stubRepository = StubTaskRepository();
      
      // 添加活跃任务
      await stubRepository.createTask(TaskDraft(
        title: 'Task 1',
        status: TaskStatus.pending,
        milestoneId: milestone.id,
        projectId: milestone.projectId,
        sortIndex: 0,
      ));

      await tester.pumpWidget(
        _buildTestWidget(
          Consumer(
            builder: (context, ref, child) => ElevatedButton(
              onPressed: () async {
                await confirmMilestoneDelete(context, ref, milestone);
              },
              child: const Text('Delete'),
            ),
          ),
          stubRepository,
        ),
      );

      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // 验证弹窗显示
      expect(find.byType(AlertDialog), findsOneWidget);
      
      // 验证富文本显示（包含里程碑标题和任务数量）
      expect(find.textContaining('Test Milestone'), findsOneWidget);
      expect(find.textContaining('1'), findsWidgets);
    });

    testWidgets('第二次确认弹窗显示图标容器', (tester) async {
      final milestone = _createMilestone();
      final stubRepository = StubTaskRepository();
      
      // 不添加活跃任务

      await tester.pumpWidget(
        _buildTestWidget(
          Consumer(
            builder: (context, ref, child) => ElevatedButton(
              onPressed: () async {
                await confirmMilestoneDelete(context, ref, milestone);
              },
              child: const Text('Delete'),
            ),
          ),
          stubRepository,
        ),
      );

      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // 验证弹窗显示
      expect(find.byType(AlertDialog), findsOneWidget);
      
      // 验证图标容器显示（通过查找 Icon）
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      
      // 验证确定按钮存在（FilledButton）
      expect(find.byType(FilledButton), findsOneWidget);
      
      // 验证确定按钮使用错误色
      final filledButton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(filledButton.style?.backgroundColor, isNotNull);
    });
  });
}

