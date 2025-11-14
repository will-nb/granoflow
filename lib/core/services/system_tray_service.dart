import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../constants/tray_constants.dart';
import '../providers/focus_providers.dart';
import '../providers/pinned_task_provider.dart';
import '../providers/repository_providers.dart';
import '../providers/service_providers.dart';
import '../utils/debounce_util.dart';
import '../utils/tray_menu_builder.dart';
import '../../presentation/navigation/app_router.dart';
import '../../presentation/widgets/utils/quick_add_sheet_helper.dart';
import '../../presentation/widgets/utils/task_status_toggle_helper.dart';

/// 系统托盘服务
/// 
/// 管理系统托盘图标和菜单，提供跨平台的系统托盘功能
/// 支持 Windows、macOS 和 Linux
class SystemTrayService {
  SystemTrayService(this._ref);

  final Ref _ref;
  final TrayManager _trayManager = TrayManager.instance;
  final WindowManager _windowManager = WindowManager.instance;
  
  GlobalKey<NavigatorState>? _navigatorKey;
  Timer? _updateTimer;
  VoidCallback? _debouncedUpdateMenu;
  bool _disposed = false;

  /// 初始化系统托盘服务
  /// 
  /// [navigatorKey] 用于获取 BuildContext 的 GlobalKey（可选，如果不提供则使用 AppRouter 的 navigatorKey）
  Future<void> init([GlobalKey<NavigatorState>? navigatorKey]) async {
    debugPrint('[SystemTrayService] Starting initialization...');
    if (_disposed) {
      debugPrint('[SystemTrayService] Service already disposed, cannot init');
      return;
    }

    try {
      // 使用提供的 navigatorKey，如果没有提供则稍后通过 AppRouter 获取
      _navigatorKey = navigatorKey;

      // 检测运行平台
      if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
        debugPrint('[SystemTrayService] Not a desktop platform, skipping initialization');
        return;
      }

      debugPrint('[SystemTrayService] Platform detected: ${Platform.operatingSystem}');

      // 根据平台选择图标路径
      final iconPath = Platform.isWindows
          ? TrayConstants.windowsIconPath
          : TrayConstants.macosLinuxIconPath;

      debugPrint('[SystemTrayService] Setting icon: $iconPath');
      // 设置托盘图标
      await _trayManager.setIcon(iconPath);
      debugPrint('[SystemTrayService] Icon set successfully');

      // 设置工具提示
      debugPrint('[SystemTrayService] Setting tooltip...');
      await _trayManager.setToolTip('GranoFlow');
      debugPrint('[SystemTrayService] Tooltip set successfully');

      // 创建初始菜单
      debugPrint('[SystemTrayService] Building initial menu...');
      await _buildMenu();
      debugPrint('[SystemTrayService] Menu built successfully');

      // 注册事件监听器
      debugPrint('[SystemTrayService] Registering event listener...');
      _trayManager.addListener(_TrayListener(this));
      debugPrint('[SystemTrayService] Event listener registered');

      // 启动数据监听
      debugPrint('[SystemTrayService] Starting data listening...');
      _startDataListening();
      debugPrint('[SystemTrayService] Data listening started');

      debugPrint('[SystemTrayService] Initialized successfully');
    } catch (error, stackTrace) {
      debugPrint('[SystemTrayService] Failed to initialize: $error\n$stackTrace');
    }
  }

  /// 构建菜单
  Future<void> _buildMenu() async {
    if (_disposed) {
      debugPrint('[SystemTrayService] Service disposed, skipping menu build');
      return;
    }

    try {
      debugPrint('[SystemTrayService] Building menu items...');
      final menuItems = await TrayMenuBuilder.buildTrayMenu(
        ref: _ref,
        navigatorKey: _navigatorKey,
      );
      debugPrint('[SystemTrayService] Menu items built: ${menuItems.length} items');

      debugPrint('[SystemTrayService] Setting context menu...');
      await _trayManager.setContextMenu(Menu(items: menuItems));
      debugPrint('[SystemTrayService] Context menu set successfully');
    } catch (error, stackTrace) {
      debugPrint('[SystemTrayService] Failed to build menu: $error\n$stackTrace');
    }
  }

  /// 更新菜单（带防抖）
  void _updateMenu() {
    if (_disposed) {
      return;
    }

    // 使用防抖机制，避免过于频繁的更新
    _debouncedUpdateMenu ??= DebounceUtil.debounce(
      const Duration(milliseconds: 500),
      () async {
        if (_disposed) {
          return;
        }
        await _buildMenu();
      },
    );

    _debouncedUpdateMenu?.call();
  }

  /// 启动数据监听
  void _startDataListening() {
    // 监听计时器状态变化
    _ref.listen<String?>(
      pinnedTaskIdProvider,
      (previous, next) {
        _updateMenu();
        _updateTimerDisplay();
      },
    );

    // 注意：taskSectionsProvider 是 StreamProvider，不能直接使用 ref.listen
    // 菜单构建时会直接读取最新数据，所以不需要额外监听
    // 如果需要实时更新，可以在菜单构建时使用 ref.watch 或 ref.read

    // 启动定时器更新计时器时间显示（每1秒）
    _updateTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTimerDisplay(),
    );
  }

  /// 更新计时器时间显示
  void _updateTimerDisplay() {
    if (_disposed) {
      return;
    }

    // 检查是否有活跃的计时器
    final pinnedTaskId = _ref.read(pinnedTaskIdProvider);
    if (pinnedTaskId == null) {
      return;
    }

    // 更新菜单以刷新计时器时间
    _updateMenu();
  }

  /// 处理菜单项点击事件
  Future<void> _handleMenuItemClick(MenuItem menuItem) async {
    if (_disposed) {
      return;
    }

    try {
      final key = menuItem.key ?? '';

      // 根据 key 分发到具体处理方法
      if (key == TrayConstants.timerStatusKey) {
        await _handleTimerStatusClick();
      } else if (key == TrayConstants.quickAddTaskKey) {
        await _handleQuickAddClick();
      } else if (key == TrayConstants.settingsKey) {
        await _handleSettingsClick();
      } else if (key == TrayConstants.quitKey) {
        await _handleQuitClick();
      } else if (key.startsWith(TrayConstants.taskKeyPrefix)) {
        // 任务相关菜单项
        final taskId = TrayConstants.parseTaskIdFromKey(key);
        if (taskId != null) {
          if (key.endsWith(TrayConstants.taskStartTimerKeySuffix)) {
            await _handleTaskSubmenuClick(taskId, 'start_timer');
          } else if (key.endsWith(TrayConstants.taskOpenKeySuffix)) {
            await _handleTaskSubmenuClick(taskId, 'open_task');
          } else {
            await _handleTaskClick(taskId);
          }
        }
      }
    } catch (error, stackTrace) {
      debugPrint('[SystemTrayService] Failed to handle menu item click: $error\n$stackTrace');
    }
  }

  /// 处理计时器状态点击（完成任务并取消置顶）
  Future<void> _handleTimerStatusClick() async {
    try {
      final pinnedTaskId = _ref.read(pinnedTaskIdProvider);
      if (pinnedTaskId == null) {
        return;
      }

      final taskService = await _ref.read(taskServiceProvider.future);
      final focusActionsNotifier = _ref.read(focusActionsNotifierProvider.notifier);

      // 获取当前 session ID
      String? sessionId;
      try {
        final sessionAsync = await _ref.read(focusSessionProvider(pinnedTaskId).future);
        sessionId = sessionAsync?.id;
      } catch (e) {
        debugPrint('[SystemTrayService] Failed to get session ID: $e');
      }

      // 完成任务
      await taskService.markCompleted(taskId: pinnedTaskId);

      // 停止计时器（如果有 session ID）
      if (sessionId != null) {
        await focusActionsNotifier.end(
          sessionId: sessionId,
          outcome: FocusOutcome.complete,
        );
      }

      // 取消置顶
      final pinnedTaskIdNotifier = _ref.read(pinnedTaskIdProvider.notifier);
      pinnedTaskIdNotifier.setPinnedTaskId(null);

      // 更新菜单
      _updateMenu();
    } catch (error, stackTrace) {
      debugPrint('[SystemTrayService] Failed to handle timer status click: $error\n$stackTrace');
    }
  }

  /// 处理任务项点击（切换任务状态：☐→☑→☒→☐）
  Future<void> _handleTaskClick(String taskId) async {
    try {
      // 获取 context（优先使用 navigatorKey，否则使用 AppRouter）
      final context = _navigatorKey?.currentContext ?? 
          AppRouter.router.routerDelegate.navigatorKey.currentContext;
      if (context == null) {
        debugPrint('[SystemTrayService] Context is null, cannot handle task click');
        return;
      }

      // 获取任务数据
      final taskRepository = await _ref.read(taskRepositoryProvider.future);
      final task = await taskRepository.findById(taskId);
      if (task == null) {
        debugPrint('[SystemTrayService] Task not found: $taskId');
        return;
      }

      // 调用三态切换方法
      // 注意：WidgetRef 是 Ref 的子类，所以可以安全地将 _ref 作为 WidgetRef 传递
      // 使用类型转换以确保类型安全
      final success = await TaskStatusToggleHelper.toggleTaskStatusThreeState(
        context,
        _ref as WidgetRef,
        task,
      );

      if (success) {
        // 更新菜单
        _updateMenu();
      }
    } catch (error, stackTrace) {
      debugPrint('[SystemTrayService] Failed to handle task click: $error\n$stackTrace');
    }
  }

  /// 处理任务子菜单点击（开始计时、打开任务）
  Future<void> _handleTaskSubmenuClick(String taskId, String action) async {
    try {
      if (action == 'start_timer') {
        // 开始计时
        final taskService = await _ref.read(taskServiceProvider.future);
        final focusActionsNotifier = _ref.read(focusActionsNotifierProvider.notifier);
        final pinnedTaskIdNotifier = _ref.read(pinnedTaskIdProvider.notifier);

        // 标记为进行中
        await taskService.markInProgress(taskId);

        // 置顶
        pinnedTaskIdNotifier.setPinnedTaskId(taskId);

        // 开始计时
        await focusActionsNotifier.start(taskId);

        // 更新菜单
        _updateMenu();
      } else if (action == 'open_task') {
        // 打开任务
        await _showWindow();
        // 获取任务以确定 section
        final taskRepository = await _ref.read(taskRepositoryProvider.future);
        final task = await taskRepository.findById(taskId);
        String? section;
        if (task?.dueAt != null) {
          // 根据任务的 dueAt 确定 section
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final dueDate = DateTime(task!.dueAt!.year, task.dueAt!.month, task.dueAt!.day);
          if (dueDate.isBefore(today)) {
            section = 'overdue';
          } else if (dueDate.isAtSameMomentAs(today)) {
            section = 'today';
          }
        }
        await _navigateToTaskPage(section, taskId);
        // 注意：任务详情会在 TaskListPage 中自动显示（通过 initialTaskId 参数）
      }
    } catch (error, stackTrace) {
      debugPrint('[SystemTrayService] Failed to handle task submenu click: $error\n$stackTrace');
    }
  }

  /// 处理快速添加任务点击
  Future<void> _handleQuickAddClick() async {
    try {
      await _showWindow();

      // 获取 context（优先使用 navigatorKey，否则使用 AppRouter）
      final context = _navigatorKey?.currentContext ?? 
          AppRouter.router.routerDelegate.navigatorKey.currentContext;
      if (context == null) {
        debugPrint('[SystemTrayService] Context is null, cannot show quick add sheet');
        return;
      }

      await QuickAddSheetHelper.showQuickAddSheet(context);
    } catch (error, stackTrace) {
      debugPrint('[SystemTrayService] Failed to handle quick add click: $error\n$stackTrace');
    }
  }

  /// 处理设置点击
  Future<void> _handleSettingsClick() async {
    try {
      await _showWindow();
      AppRouter.router.go('/settings');
    } catch (error, stackTrace) {
      debugPrint('[SystemTrayService] Failed to handle settings click: $error\n$stackTrace');
    }
  }

  /// 处理退出点击
  Future<void> _handleQuitClick() async {
    try {
      // 清理资源
      await dispose();

      // 根据平台调用退出方法
      if (Platform.isMacOS) {
        // macOS: 使用 exit(0)
        exit(0);
      } else {
        // Windows/Linux: 使用 exit(0)
        exit(0);
      }
    } catch (error, stackTrace) {
      debugPrint('[SystemTrayService] Failed to handle quit click: $error\n$stackTrace');
      // 即使出错也退出
      exit(0);
    }
  }

  /// 显示/恢复窗口
  Future<void> _showWindow() async {
    try {
      final isVisible = await _windowManager.isVisible();
      if (!isVisible) {
        await _windowManager.show();
        await _windowManager.focus();
      }
    } catch (error, stackTrace) {
      debugPrint('[SystemTrayService] Failed to show window: $error\n$stackTrace');
    }
  }

  /// 导航到任务页面
  Future<void> _navigateToTaskPage(String? section, String? taskId) async {
    try {
      // 构建 URL，包含 section 和 taskId 参数
      final queryParams = <String, String>{};
      if (section != null) {
        queryParams['section'] = section;
      }
      if (taskId != null) {
        queryParams['taskId'] = taskId;
      }
      
      final uri = Uri(path: '/tasks', queryParameters: queryParams.isEmpty ? null : queryParams);
      AppRouter.router.go(uri.toString());
    } catch (error, stackTrace) {
      debugPrint('[SystemTrayService] Failed to navigate to task page: $error\n$stackTrace');
    }
  }


  /// 清理资源
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    try {
      _disposed = true;

      // 取消定时器
      _updateTimer?.cancel();
      _updateTimer = null;

      // 移除事件监听器
      _trayManager.removeListener(_TrayListener(this));

      // 移除托盘图标
      await _trayManager.destroy();

      debugPrint('[SystemTrayService] Disposed successfully');
    } catch (error, stackTrace) {
      debugPrint('[SystemTrayService] Failed to dispose: $error\n$stackTrace');
    }
  }
}

/// 托盘事件监听器
class _TrayListener extends TrayListener {
  _TrayListener(this._service);

  final SystemTrayService _service;

  @override
  void onTrayIconMouseDown() {
    debugPrint('[SystemTrayService] Tray icon clicked (left button)');
    // 点击托盘图标时显示窗口
    _service._showWindow();
  }

  @override
  void onTrayIconRightMouseDown() {
    debugPrint('[SystemTrayService] Tray icon clicked (right button)');
    // 右键点击托盘图标时显示菜单（由系统自动处理）
    // 在 macOS 上，右键点击会自动显示菜单
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    debugPrint('[SystemTrayService] Menu item clicked: ${menuItem.key} - ${menuItem.label}');
    // 处理菜单项点击
    _service._handleMenuItemClick(menuItem);
  }
}

