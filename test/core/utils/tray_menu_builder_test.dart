import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/constants/tray_constants.dart';
import 'package:granoflow/core/utils/tray_menu_builder.dart';
import 'package:granoflow/data/models/task.dart';

void main() {
  Task _createTask(String id, {TaskStatus status = TaskStatus.pending}) {
    final now = DateTime(2025, 1, 1);
    return Task(
      id: id,
      title: 'Task $id',
      status: status,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('buildMenu without tasks renders quick add, settings, quit', () {
    final menuItems = TrayMenuBuilder.build(
      context: null,
      data: const TrayMenuData(
        hasPinnedTask: false,
        overdueTasks: [],
        todayTasks: [],
      ),
    );

    expect(menuItems.length, 4);
    expect(menuItems[0].key, TrayConstants.quickAddTaskKey);
    expect(menuItems[2].key, TrayConstants.settingsKey);
    expect(menuItems[3].key, TrayConstants.quitKey);
  });

  test('buildMenu enforces overdue limit and adds overflow submenu', () {
    final overdueTasks = List.generate(
      TrayConstants.maxOverdueTasks + 2,
      (index) => _createTask('overdue_$index'),
    );

    final menuItems = TrayMenuBuilder.build(
      context: null,
      data: TrayMenuData(
        hasPinnedTask: false,
        overdueTasks: overdueTasks,
        todayTasks: const [],
        timerStatus: const TrayMenuTimerStatus(
          taskId: 'timer-id',
          taskTitle: 'Timer Task',
          elapsed: Duration(hours: 1, minutes: 30, seconds: 5),
        ),
      ),
    );

    // Timer + separator + quick add + separator + tasks...
    expect(menuItems.first.key, TrayConstants.timerStatusKey);
    expect(menuItems.first.label!.contains('(01:30)'), isTrue);

    final overflowItem = menuItems.firstWhere(
      (item) => item.key == TrayConstants.overdueMoreKey,
    );
    expect(overflowItem.submenu?.items?.length, 2);
  });
}

