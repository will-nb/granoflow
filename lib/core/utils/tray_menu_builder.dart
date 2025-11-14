import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/tray_manager.dart';

import '../../data/models/focus_session.dart';
import '../../data/models/task.dart';
import '../../presentation/navigation/app_router.dart';
import '../constants/tray_constants.dart';
import '../providers/focus_providers.dart';
import '../providers/pinned_task_provider.dart';
import '../providers/repository_providers.dart';
import '../providers/task_query_providers.dart';
import '../../presentation/clock/utils/clock_timer_utils.dart';
import '../utils/text_utils.dart';

/// 系统托盘菜单构建器
/// 
/// 负责构建系统托盘菜单项列表，处理菜单项格式化（图标、文本、状态）
class TrayMenuBuilder {
  const TrayMenuBuilder._();

  /// 构建完整的系统托盘菜单
  /// 
  /// [ref] Riverpod 引用，用于访问 providers
  /// [navigatorKey] 用于获取 BuildContext 的 GlobalKey
  /// 
  /// 返回菜单项列表
  static Future<List<MenuItem>> buildTrayMenu({
    required Ref ref,
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    final menuItems = <MenuItem>[];

    // 获取 BuildContext（用于本地化）
    // 优先使用提供的 navigatorKey，否则使用 AppRouter 的 navigatorKey
    final context = navigatorKey?.currentContext ?? 
        AppRouter.router.routerDelegate.navigatorKey.currentContext;

    // 获取置顶任务 ID
    final pinnedTaskId = ref.read(pinnedTaskIdProvider);

    // 获取计时器状态
    FocusSession? activeSession;
    if (pinnedTaskId != null) {
      try {
        final sessionAsync = await ref.read(focusSessionProvider(pinnedTaskId).future);
        activeSession = sessionAsync;
      } catch (e) {
        // 忽略错误，继续构建菜单
      }
    }

    // 1. 计时器状态（如果有活跃计时器）
    if (pinnedTaskId != null && activeSession != null) {
      final taskRepository = await ref.read(taskRepositoryProvider.future);
      final task = await taskRepository.findById(pinnedTaskId);
      if (task != null) {
        final elapsed = DateTime.now().difference(activeSession.startedAt);
        menuItems.add(
          buildTimerStatusItem(
            taskId: pinnedTaskId,
            taskTitle: task.title,
            elapsed: elapsed,
            context: context,
          ),
        );
        menuItems.add(buildSeparator());
      }
    }

    // 2. 快速添加任务
    menuItems.add(buildQuickAddItem(context));

    // 如果有计时器，在快速添加后添加分隔线
    if (pinnedTaskId != null && activeSession != null) {
      menuItems.add(buildSeparator());
    }

    // 3. 任务列表
    final overdueTasks = await ref.read(taskSectionsProvider(TaskSection.overdue).future);
    final todayTasks = await ref.read(taskSectionsProvider(TaskSection.today).future);

    final taskItems = buildTaskItems(
      overdueTasks: overdueTasks,
      todayTasks: todayTasks,
      pinnedTaskId: pinnedTaskId,
      context: context,
    );

    if (taskItems.isNotEmpty) {
      menuItems.addAll(taskItems);
      menuItems.add(buildSeparator());
    }

    // 4. 设置
    menuItems.add(buildSettingsItem(context));

    // 5. 退出
    menuItems.add(buildQuitItem(context));

    return menuItems;
  }

  /// 构建计时器状态菜单项
  /// 
  /// 格式：⏱️ (00:15:30) 任务标题
  static MenuItem buildTimerStatusItem({
    required String taskId,
    required String taskTitle,
    required Duration elapsed,
    BuildContext? context,
  }) {
    final timeStr = ClockTimerUtils.formatElapsedTimeCompact(elapsed);
    final title = formatTaskTitle(taskTitle, maxLength: 40);
    final label = '${TrayConstants.timerIcon} ($timeStr) $title';

    return MenuItem(
      key: TrayConstants.timerStatusKey,
      label: label,
    );
  }

  /// 构建快速添加任务菜单项
  /// 
  /// 格式：➕ 添加任务
  static MenuItem buildQuickAddItem(BuildContext? context) {
    final label = '${TrayConstants.quickAddIcon} Add Task'; // TODO: 添加本地化

    return MenuItem(
      key: TrayConstants.quickAddTaskKey,
      label: label,
    );
  }

  /// 构建任务列表菜单项
  /// 
  /// 返回任务菜单项列表（逾期任务在前，今日任务在后）
  static List<MenuItem> buildTaskItems({
    required List<Task> overdueTasks,
    required List<Task> todayTasks,
    String? pinnedTaskId,
    BuildContext? context,
  }) {
    final menuItems = <MenuItem>[];

    // 合并任务列表（逾期在前，今日在后），排除置顶任务
    final allTasks = <Task>[];
    for (final task in overdueTasks) {
      if (task.id != pinnedTaskId) {
        allTasks.add(task);
      }
    }
    for (final task in todayTasks) {
      if (task.id != pinnedTaskId) {
        allTasks.add(task);
      }
    }

    // 限制任务数量（最多10个）
    final limitedTasks = limitTasks(allTasks, maxCount: 10);
    final overflowCount = allTasks.length - limitedTasks.length;

    // 构建任务菜单项
    for (final task in limitedTasks) {
      menuItems.add(
        buildTaskItem(
          task: task,
          pinnedTaskId: pinnedTaskId,
          context: context,
        ),
      );
    }

    // 如果有溢出，添加溢出提示
    if (overflowCount > 0) {
      final overflowLabel = 'More $overflowCount tasks...'; // TODO: 添加本地化
      menuItems.add(
        MenuItem(
          key: 'overflow',
          label: overflowLabel,
        ),
      );
    }

    return menuItems;
  }

  /// 构建单个任务菜单项（带子菜单）
  /// 
  /// 格式：☐ ⚠️ 任务标题（带子菜单）
  static MenuItem buildTaskItem({
    required Task task,
    String? pinnedTaskId,
    BuildContext? context,
  }) {
    final statusIcon = getStatusIcon(task.status);
    final warningIcon = _isOverdue(task) ? TrayConstants.warningIcon : '';
    final title = formatTaskTitle(task.title, maxLength: 50);
    final label = '$statusIcon $warningIcon$title';

    // 注意：tray_manager 的 MenuItem 可能不支持 submenu 参数
    // 如果支持，使用 Menu(items: submenu)
    // 如果不支持，需要将子菜单项作为主菜单项显示
    // 暂时不添加子菜单，直接点击任务项切换状态

    return MenuItem(
      key: TrayConstants.buildTaskKey(task.id),
      label: label,
    );
  }

  /// 构建任务子菜单
  /// 
  /// 包含'开始计时'和'打开'选项
  static List<MenuItem> buildTaskSubmenu({
    required String taskId,
    String? pinnedTaskId,
    BuildContext? context,
  }) {
    final menuItems = <MenuItem>[];

    // 开始计时（只有在没有置顶任务时才启用）
    final startTimerLabel = 'Start Timer'; // TODO: 添加本地化
    // 注意：tray_manager 的 MenuItem 可能不支持 enabled 参数
    // 如果不支持，可以通过 label 前缀或后缀来标识禁用状态
    menuItems.add(
      MenuItem(
        key: TrayConstants.buildTaskStartTimerKey(taskId),
        label: pinnedTaskId == null ? startTimerLabel : '$startTimerLabel (disabled)',
      ),
    );

    // 打开
    final openLabel = 'Open'; // TODO: 添加本地化
    menuItems.add(
      MenuItem(
        key: TrayConstants.buildTaskOpenKey(taskId),
        label: openLabel,
      ),
    );

    return menuItems;
  }

  /// 构建设置菜单项
  /// 
  /// 格式：⚙️ 设置
  static MenuItem buildSettingsItem(BuildContext? context) {
    final label = '${TrayConstants.settingsIcon} Settings'; // TODO: 添加本地化

    return MenuItem(
      key: TrayConstants.settingsKey,
      label: label,
    );
  }

  /// 构建退出菜单项
  /// 
  /// 格式：🚪 退出
  static MenuItem buildQuitItem(BuildContext? context) {
    final label = '${TrayConstants.quitIcon} Quit'; // TODO: 添加本地化

    return MenuItem(
      key: TrayConstants.quitKey,
      label: label,
    );
  }

  /// 构建分隔线
  static MenuItem buildSeparator() {
    return MenuItem.separator();
  }

  /// 获取任务状态图标
  /// 
  /// - pending/doing/paused/inbox → '☐'
  /// - completedActive → '☑'
  /// - trashed → '☒'
  static String getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
      case TaskStatus.doing:
      case TaskStatus.paused:
      case TaskStatus.inbox:
        return TrayConstants.statusIconActive;
      case TaskStatus.completedActive:
        return TrayConstants.statusIconCompleted;
      case TaskStatus.trashed:
        return TrayConstants.statusIconDeleted;
      default:
        return TrayConstants.statusIconActive;
    }
  }

  /// 格式化任务标题（截断过长标题）
  /// 
  /// [title] 任务标题
  /// [maxLength] 最大长度
  /// 
  /// 返回格式化后的标题
  static String formatTaskTitle(String title, {int maxLength = 50}) {
    return TextUtils.truncate(title, maxLength);
  }

  /// 限制任务数量
  /// 
  /// [tasks] 任务列表
  /// [maxCount] 最大数量
  /// 
  /// 返回限制后的任务列表
  static List<Task> limitTasks(List<Task> tasks, {int maxCount = 10}) {
    if (tasks.length <= maxCount) {
      return tasks;
    }
    return tasks.take(maxCount).toList();
  }

  /// 判断任务是否逾期
  /// 
  /// [task] 任务
  /// 
  /// 返回 true 表示任务逾期
  static bool _isOverdue(Task task) {
    if (task.dueAt == null) {
      return false;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(task.dueAt!.year, task.dueAt!.month, task.dueAt!.day);
    return dueDate.isBefore(today);
  }
}

