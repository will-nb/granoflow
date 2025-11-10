import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/widgets/dismissible_task_tile.dart';
import 'package:granoflow/presentation/widgets/swipe_action_type.dart';
import 'package:granoflow/presentation/widgets/swipe_configs.dart';

void main() {
  group('Inbox swipe direction', () {
    test('SwipeConfigs.inboxConfig mapping stays fixed', () {
      expect(SwipeConfigs.inboxConfig.leftAction, SwipeActionType.quickPlan);
      expect(SwipeConfigs.inboxConfig.rightAction, SwipeActionType.delete);
    });

    testWidgets(
      'Right swipe triggers quickPlan, left swipe triggers delete (LTR)',
      (tester) async {
        // Build a minimal Task
        Task buildTask(String id) => Task(
          id: id,

          title: 'Task $id',
          status: TaskStatus.inbox,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        );

        bool leftCalled = false; // quickPlan in our config
        bool rightCalled = false; // delete in our config

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DismissibleTaskTile(
                task: buildTask('1'),
                config: SwipeConfigs.inboxConfig,
                onLeftAction: (_) {
                  if (SwipeConfigs.inboxConfig.leftAction ==
                      SwipeActionType.quickPlan) {
                    leftCalled = true;
                  }
                },
                onRightAction: (_) {
                  if (SwipeConfigs.inboxConfig.rightAction ==
                      SwipeActionType.delete) {
                    rightCalled = true;
                  }
                },
                child: const Text('inbox item'),
              ),
            ),
          ),
        );

        // 使用 confirmDismiss 直接触发，避免手势在测试环境下的不稳定
        final dismissibleWidget = tester.widget<Dismissible>(
          find.byType(Dismissible),
        );
        await dismissibleWidget.confirmDismiss!(DismissDirection.startToEnd);
        await tester.pump();
        expect(leftCalled, isTrue);
        expect(rightCalled, isFalse);

        // Rebuild with a different key (different task id) and perform left swipe
        leftCalled = false;
        rightCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DismissibleTaskTile(
                task: buildTask('2'),
                config: SwipeConfigs.inboxConfig,
                onLeftAction: (_) {
                  if (SwipeConfigs.inboxConfig.leftAction ==
                      SwipeActionType.quickPlan) {
                    leftCalled = true;
                  }
                },
                onRightAction: (_) {
                  if (SwipeConfigs.inboxConfig.rightAction ==
                      SwipeActionType.delete) {
                    rightCalled = true;
                  }
                },
                child: const Text('inbox item 2'),
              ),
            ),
          ),
        );

        // Left swipe (endToStart) 应触发 rightAction (delete)
        final dismissibleWidget2 = tester.widget<Dismissible>(
          find.byType(Dismissible),
        );
        await dismissibleWidget2.confirmDismiss!(DismissDirection.endToStart);
        await tester.pump();
        expect(leftCalled, isFalse);
        expect(rightCalled, isTrue);
      },
    );
  });
}
