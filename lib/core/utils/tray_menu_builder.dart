import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';

import '../../data/models/task.dart';
import '../../generated/l10n/app_localizations.dart';
import '../constants/tray_constants.dart';
import 'text_utils.dart';

/// 计时器状态数据
class TrayMenuTimerStatus {
  const TrayMenuTimerStatus({
    required this.taskId,
    required this.taskTitle,
    required this.elapsed,
  });

  final String taskId;
  final String taskTitle;
  final Duration elapsed;
}

/// 构建菜单所需的数据
class TrayMenuData {
  const TrayMenuData({
    required this.hasPinnedTask,
    required this.overdueTasks,
    required this.todayTasks,
    this.timerStatus,
  });

  final bool hasPinnedTask;
  final List<Task> overdueTasks;
  final List<Task> todayTasks;
  final TrayMenuTimerStatus? timerStatus;
}

/// 托盘菜单构建器
class TrayMenuBuilder {
  const TrayMenuBuilder._();

  static List<MenuItem> build({
    required BuildContext? context,
    required TrayMenuData data,
  }) {
    final l10n = context != null ? AppLocalizations.of(context) : null;
    final menuItems = <MenuItem>[];

    if (data.timerStatus != null) {
      menuItems.add(_buildTimerStatusItem(data.timerStatus!, l10n));
    }

    menuItems.add(_buildQuickAddItem(l10n));

    final taskItems = _buildTaskMenuItems(
      l10n: l10n,
      tasks: data.overdueTasks,
      isOverdue: true,
      hasPinnedTask: data.hasPinnedTask,
    );
    final todayItems = _buildTaskMenuItems(
      l10n: l10n,
      tasks: data.todayTasks,
      isOverdue: false,
      hasPinnedTask: data.hasPinnedTask,
    );

    final combinedTasks = <MenuItem>[
      ...taskItems,
      ...todayItems,
    ];

    if (combinedTasks.isNotEmpty) {
      _addSeparator(menuItems);
      menuItems.addAll(combinedTasks);
    }

    _addSeparator(menuItems);
    menuItems
      ..add(_buildSettingsItem(l10n))
      ..add(_buildQuitItem(l10n));

    return menuItems;
  }

  static MenuItem _buildTimerStatusItem(
    TrayMenuTimerStatus status,
    AppLocalizations? l10n,
  ) {
    final formattedElapsed = _formatTimerElapsed(status.elapsed);
    final title = status.taskTitle.isEmpty
        ? (l10n?.taskTitleHint ?? 'Untitled Task')
        : status.taskTitle;
    final label =
        '${TrayConstants.timerIcon} ($formattedElapsed) ${TextUtils.truncate(title, 25)}';
    return MenuItem(
      key: TrayConstants.timerStatusKey,
      label: label,
    );
  }

  static MenuItem _buildQuickAddItem(AppLocalizations? l10n) {
    final label =
        '${TrayConstants.quickAddIcon} ${l10n?.trayAddTask ?? 'Add Task'}';
    return MenuItem(
      key: TrayConstants.quickAddTaskKey,
      label: label,
    );
  }

  static List<MenuItem> _buildTaskMenuItems({
    required AppLocalizations? l10n,
    required List<Task> tasks,
    required bool isOverdue,
    required bool hasPinnedTask,
  }) {
    if (tasks.isEmpty) {
      return const [];
    }

    final visibleLimit = isOverdue
        ? TrayConstants.maxOverdueTasks
        : TrayConstants.maxTodayTasks;
    final visibleItems = <MenuItem>[];
    final overflowItems = <MenuItem>[];

    for (var i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      final item = _buildSingleTaskItem(
        task: task,
        isOverdue: isOverdue,
        hasPinnedTask: hasPinnedTask,
        l10n: l10n,
      );
      if (i < visibleLimit) {
        visibleItems.add(item);
      } else {
        overflowItems.add(item);
      }
    }

    if (overflowItems.isNotEmpty) {
      visibleItems.add(
        MenuItem(
          key: isOverdue
              ? TrayConstants.overdueMoreKey
              : TrayConstants.todayMoreKey,
          label: _buildMoreLabel(
            l10n: l10n,
            count: overflowItems.length,
            isOverdue: isOverdue,
          ),
          submenu: Menu(items: overflowItems),
        ),
      );
    }

    return visibleItems;
  }

  static MenuItem _buildSingleTaskItem({
    required Task task,
    required bool isOverdue,
    required bool hasPinnedTask,
    required AppLocalizations? l10n,
  }) {
    final label = _formatTaskLabel(task, isOverdue, l10n);
    return MenuItem(
      key: TrayConstants.buildTaskKey(task.id),
      label: label,
    );
  }

  static MenuItem _buildSettingsItem(AppLocalizations? l10n) {
    final label =
        '${TrayConstants.settingsIcon} ${l10n?.traySettings ?? 'Settings'}';
    return MenuItem(
      key: TrayConstants.settingsKey,
      label: label,
    );
  }

  static MenuItem _buildQuitItem(AppLocalizations? l10n) {
    final label = '${TrayConstants.quitIcon} ${l10n?.trayQuit ?? 'Quit'}';
    return MenuItem(
      key: TrayConstants.quitKey,
      label: label,
    );
  }

  static void _addSeparator(List<MenuItem> items) {
    if (items.isEmpty) {
      return;
    }
    final last = items.last;
    if (last.key == null && last.label == null) {
      return;
    }
    items.add(MenuItem.separator());
  }

  static String _buildMoreLabel({
    required AppLocalizations? l10n,
    required int count,
    required bool isOverdue,
  }) {
    if (isOverdue) {
      return l10n?.trayMoreOverdueTasks(count) ??
          '+$count overdue tasks';
    }
    return l10n?.trayMoreTodayTasks(count) ??
        '+$count today tasks';
  }

  static String _formatTaskLabel(
    Task task,
    bool isOverdue,
    AppLocalizations? l10n,
  ) {
    final title = task.title.isEmpty
        ? (l10n?.taskTitleHint ?? 'Untitled Task')
        : task.title;
    final truncatedTitle = TextUtils.truncate(title, 25);
    final warning = isOverdue ? '${TrayConstants.warningIcon}' : '';
    return '$warning$truncatedTitle';
  }

  static String _formatTimerElapsed(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}';
  }
}

