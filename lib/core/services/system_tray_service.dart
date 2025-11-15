import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../data/models/focus_session.dart';
import '../../data/models/task.dart';
import '../constants/tray_constants.dart';
import '../providers/focus_providers.dart';
import '../providers/pinned_task_provider.dart';
import '../providers/task_query_providers.dart';
import '../providers/service_providers.dart';
import '../utils/tray_menu_builder.dart';
import '../../presentation/navigation/app_router.dart';
import '../../presentation/widgets/utils/quick_add_sheet_helper.dart';

/// 系统托盘服务
class SystemTrayService {
  SystemTrayService(this._ref);

  final Ref _ref;
  final TrayManager _trayManager = TrayManager.instance;
  final WindowManager _windowManager = WindowManager.instance;
  final _TrayListener _listener = _TrayListener();

  bool _disposed = false;
  String? _pinnedTaskId;
  Task? _pinnedTask;
  FocusSession? _activeSession;
  List<Task> _overdueTasks = const [];
  List<Task> _todayTasks = const [];
  final Map<String, TaskSection> _taskSectionIndex = {};

  GlobalKey<NavigatorState>? _navigatorKey;
  Timer? _menuUpdateTimer;

  ProviderSubscription<AsyncValue<List<Task>>>? _overdueSubscription;
  ProviderSubscription<AsyncValue<List<Task>>>? _todaySubscription;
  ProviderSubscription<String?>? _pinnedTaskSubscription;
  ProviderSubscription<AsyncValue<Task?>>? _pinnedTaskDataSubscription;
  ProviderSubscription<AsyncValue<FocusSession?>>? _focusSessionSubscription;

  /// 初始化系统托盘服务
  Future<void> init() async {
    if (_disposed) {
      debugPrint('[SystemTrayService] Service already disposed, cannot init');
      return;
    }

    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      debugPrint('[SystemTrayService] Not a desktop platform, skipping tray init');
      return;
    }

    try {
      _navigatorKey = AppRouter.router.routerDelegate.navigatorKey;

      final iconPath = Platform.isWindows
          ? TrayConstants.windowsIconPath
          : TrayConstants.macosLinuxIconPath;
      await _trayManager.setIcon(iconPath);
      await _trayManager.setToolTip('GranoFlow');

      _listener.attach(this);
      _trayManager.addListener(_listener);

      _startDataListening();
      await _updateMenu();

      debugPrint('[SystemTrayService] Initialized successfully');
    } catch (error, stackTrace) {
      debugPrint('[SystemTrayService] Failed to initialize: $error\n$stackTrace');
    }
  }

  void _startDataListening() {
    _overdueSubscription = _ref.listen<AsyncValue<List<Task>>>(
      taskSectionsProvider(TaskSection.overdue),
      (_, next) {
        next.whenData((tasks) {
          _overdueTasks = _filterPinned(tasks);
          _updateTaskSectionIndex(TaskSection.overdue, _overdueTasks);
          _scheduleMenuUpdate();
        });
      },
      fireImmediately: true,
    );

    _todaySubscription = _ref.listen<AsyncValue<List<Task>>>(
      taskSectionsProvider(TaskSection.today),
      (_, next) {
        next.whenData((tasks) {
          _todayTasks = _filterPinned(tasks);
          _updateTaskSectionIndex(TaskSection.today, _todayTasks);
          _scheduleMenuUpdate();
        });
      },
      fireImmediately: true,
    );

    _pinnedTaskSubscription = _ref.listen<String?>(
      pinnedTaskIdProvider,
      (_, taskId) => _handlePinnedTaskChanged(taskId),
      fireImmediately: true,
    );
  }

  void _stopDataListening() {
    _overdueSubscription?.close();
    _overdueSubscription = null;
    _todaySubscription?.close();
    _todaySubscription = null;
    _pinnedTaskSubscription?.close();
    _pinnedTaskSubscription = null;
    _pinnedTaskDataSubscription?.close();
    _pinnedTaskDataSubscription = null;
    _focusSessionSubscription?.close();
    _focusSessionSubscription = null;
  }

  void _handlePinnedTaskChanged(String? taskId) {
    _pinnedTaskId = taskId;
    _pinnedTask = null;
    _activeSession = null;

    _pinnedTaskDataSubscription?.close();
    _focusSessionSubscription?.close();
    _pinnedTaskDataSubscription = null;
    _focusSessionSubscription = null;

    if (taskId != null) {
      _pinnedTaskDataSubscription = _ref.listen<AsyncValue<Task?>>(
        taskByIdProvider(taskId),
        (_, next) {
          next.whenData((task) {
            _pinnedTask = task;
            _scheduleMenuUpdate();
          });
        },
        fireImmediately: true,
      );

      _focusSessionSubscription = _ref.listen<AsyncValue<FocusSession?>>(
        focusSessionProvider(taskId),
        (_, next) {
          _activeSession = next.valueOrNull;
          _scheduleMenuUpdate();
        },
        fireImmediately: true,
      );
    }

    // 重新过滤现有任务列表，确保不会显示置顶任务
    _overdueTasks = _filterPinned(_overdueTasks);
    _todayTasks = _filterPinned(_todayTasks);
    _updateTaskSectionIndex(TaskSection.overdue, _overdueTasks);
    _updateTaskSectionIndex(TaskSection.today, _todayTasks);
    _scheduleMenuUpdate();
  }

  List<Task> _filterPinned(List<Task> tasks) {
    final pinnedId = _pinnedTaskId;
    if (pinnedId == null) {
      return List<Task>.from(tasks);
    }
    return tasks.where((task) => task.id != pinnedId).toList(growable: false);
  }

  void _updateTaskSectionIndex(TaskSection section, List<Task> tasks) {
    _taskSectionIndex.removeWhere((key, value) => value == section);
    for (final task in tasks) {
      _taskSectionIndex[task.id] = section;
    }
  }

  Future<void> _updateMenu() async {
    if (_disposed) return;

    try {
      final data = TrayMenuData(
        hasPinnedTask: _pinnedTaskId != null,
        overdueTasks: _overdueTasks,
        todayTasks: _todayTasks,
        timerStatus: _buildTimerStatus(),
      );
      final context = _currentContext;
      final menuItems = TrayMenuBuilder.build(
        context: context,
        data: data,
      );
      await _trayManager.setContextMenu(Menu(items: menuItems));
    } catch (error, stackTrace) {
      debugPrint('[SystemTrayService] Failed to update menu: $error\n$stackTrace');
    }
  }

  TrayMenuTimerStatus? _buildTimerStatus() {
    final taskId = _pinnedTaskId;
    final task = _pinnedTask;
    final session = _activeSession;
    if (taskId == null || task == null || session == null || !session.isActive) {
      return null;
    }
    final elapsed = DateTime.now().difference(session.startedAt);
    return TrayMenuTimerStatus(
      taskId: taskId,
      taskTitle: task.title,
      elapsed: elapsed,
    );
  }

  Future<void> _scheduleMenuUpdate({bool immediate = false}) async {
    if (_disposed) return;

    if (immediate) {
      _menuUpdateTimer?.cancel();
      _menuUpdateTimer = null;
      await _updateMenu();
      return;
    }

    _menuUpdateTimer?.cancel();
    _menuUpdateTimer = Timer(const Duration(milliseconds: 500), () {
      _menuUpdateTimer = null;
      unawaited(_updateMenu());
    });
  }

  Future<void> _handleMenuItemClick(MenuItem menuItem) async {
    if (_disposed) return;

    final key = menuItem.key ?? '';
    debugPrint('[SystemTrayService] Menu item clicked: $key');

    try {
      if (key == TrayConstants.timerStatusKey) {
        await _handleTimerStatusClick();
        return;
      }

      if (key == TrayConstants.quickAddTaskKey) {
        await _handleQuickAdd();
        return;
      }

      if (key == TrayConstants.settingsKey) {
        await _showWindowAndNavigate('/settings');
        return;
      }

      if (key == TrayConstants.quitKey) {
        await _quitApplication();
        return;
      }

      final taskId = TrayConstants.parseTaskIdFromKey(key);
      if (taskId != null) {
        await _handleOpenTask(taskId);
        return;
      }
    } catch (error, stackTrace) {
      debugPrint('[SystemTrayService] Failed to handle menu click: $error\n$stackTrace');
    }
  }

  Future<void> _handleQuickAdd() async {
    final context = _currentContext;
    if (context == null) {
      debugPrint('[SystemTrayService] Unable to open Quick Add: no context');
      return;
    }
    await QuickAddSheetHelper.showQuickAddSheet(context);
  }

  Future<void> _handleOpenTask(String taskId) async {
    final section = _taskSectionIndex[taskId];
    final params = <String, String>{
      'taskId': taskId,
    };
    if (section != null) {
      params['section'] = section.name;
    }
    final uri = Uri(path: '/tasks', queryParameters: params);
    await _showWindowAndNavigate(uri.toString());
  }

  Future<void> _handleTimerStatusClick() async {
    final session = _activeSession;
    final pinnedTaskId = _pinnedTaskId;
    if (pinnedTaskId == null) {
      return;
    }
    try {
      if (session != null && session.isActive) {
        final focusNotifier = _ref.read(focusActionsNotifierProvider.notifier);
        await focusNotifier.end(
          sessionId: session.id,
          outcome: FocusOutcome.complete,
        );
      } else {
        final taskService = await _ref.read(taskServiceProvider.future);
        await taskService.markCompleted(taskId: pinnedTaskId);
      }
    } catch (error, stackTrace) {
      debugPrint('[SystemTrayService] Failed to complete timer task: $error\n$stackTrace');
    } finally {
      await _ref.read(pinnedTaskIdProvider.notifier).setPinnedTaskId(null);
    }
  }

  Future<void> _showWindowAndNavigate(String route) async {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        await _windowManager.show();
        await _windowManager.focus();
      }
      AppRouter.router.go(route);
    } catch (error, stackTrace) {
      debugPrint('[SystemTrayService] Failed to navigate: $error\n$stackTrace');
    }
  }

  Future<void> _quitApplication() async {
    try {
      await dispose();
    } finally {
      if (Platform.isMacOS) {
        await _windowManager.hide();
      }
      await _windowManager.close();
      exit(0);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    try {
      _stopDataListening();
      _menuUpdateTimer?.cancel();
      _menuUpdateTimer = null;
      _trayManager.removeListener(_listener);
      await _trayManager.destroy();
    } catch (error, stackTrace) {
      debugPrint('[SystemTrayService] Failed to dispose: $error\n$stackTrace');
    } finally {
      _disposed = true;
    }
  }

  Future<void> showMenu() async {
    if (_disposed) return;
    try {
      await _trayManager.popUpContextMenu();
    } catch (error, stackTrace) {
      debugPrint('[SystemTrayService] Failed to show menu: $error\n$stackTrace');
    }
  }

  BuildContext? get _currentContext {
    final key = _navigatorKey ?? AppRouter.router.routerDelegate.navigatorKey;
    return key.currentContext;
  }

  Task? _findTask(String taskId) {
    for (final task in _overdueTasks) {
      if (task.id == taskId) return task;
    }
    for (final task in _todayTasks) {
      if (task.id == taskId) return task;
    }
    if (_pinnedTask?.id == taskId) {
      return _pinnedTask;
    }
    return null;
  }

  Future<void> _handleTrayIconClick() async {
    await _scheduleMenuUpdate(immediate: true);
    if (Platform.isMacOS || Platform.isLinux) {
      await showMenu();
    }
  }

  void _handleTrayMenuSelection(MenuItem menuItem) {
    unawaited(_handleMenuItemClick(menuItem));
  }
}

/// 托盘事件监听器
class _TrayListener extends TrayListener {
  SystemTrayService? _service;

  void attach(SystemTrayService service) {
    _service = service;
  }

  @override
  void onTrayIconMouseDown() {
    final service = _service;
    if (service == null) return;
    unawaited(service._handleTrayIconClick());
  }

  @override
  void onTrayIconRightMouseDown() {
    final service = _service;
    if (service == null) return;
    unawaited(service._handleTrayIconClick());
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    _service?._handleTrayMenuSelection(menuItem);
  }
}
