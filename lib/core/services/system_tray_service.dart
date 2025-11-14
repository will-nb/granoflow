import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../constants/tray_constants.dart';
import '../../presentation/navigation/app_router.dart';

/// 系统托盘服务（最简版本）
///
/// 只显示一个"菜单调试"菜单项，用于排查菜单显示问题
class SystemTrayService {
  SystemTrayService();

  final TrayManager _trayManager = TrayManager.instance;
  final TrayListener _listener = _TrayListener();
  bool _disposed = false;

  /// 初始化系统托盘服务
  Future<void> init() async {
    debugPrint('[SystemTrayService] Starting initialization...');
    if (_disposed) {
      debugPrint('[SystemTrayService] Service already disposed, cannot init');
      return;
    }

    try {
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
      (_listener as _TrayListener).attach(this);
      _trayManager.addListener(_listener);
      debugPrint('[SystemTrayService] Event listener registered');

      debugPrint('[SystemTrayService] Initialized successfully');
    } catch (error, stackTrace) {
      debugPrint('[SystemTrayService] Failed to initialize: $error\n$stackTrace');
    }
  }

  /// 构建菜单（最简版本：只有一个"菜单调试"项）
  Future<void> _buildMenu() async {
    if (_disposed) {
      debugPrint('[SystemTrayService] Service disposed, skipping menu build');
      return;
    }

    try {
      debugPrint('[SystemTrayService] Building menu items...');
      final menuItems = [
        MenuItem(
          key: TrayConstants.debugMenuKey,
          label: '🐞 菜单调试',
        ),
        MenuItem.separator(),
        MenuItem(
          key: TrayConstants.settingsKey,
          label: '${TrayConstants.settingsIcon} 设置',
        ),
        MenuItem(
          key: TrayConstants.quitKey,
          label: '${TrayConstants.quitIcon} 退出',
        ),
      ];
      debugPrint('[SystemTrayService] Menu items built: ${menuItems.length} items');

      debugPrint('[SystemTrayService] Setting context menu with ${menuItems.length} items...');
      final menu = Menu(items: menuItems);
      final items = menu.items;
      if (items != null) {
        debugPrint('[SystemTrayService] Menu object created: ${items.length} items');
        for (var i = 0; i < items.length; i++) {
          final item = items[i];
          debugPrint('[SystemTrayService] Menu item $i: key="${item.key}", label="${item.label}"');
        }
      } else {
        debugPrint('[SystemTrayService] Menu object created but items is null');
      }
      await _trayManager.setContextMenu(menu);
      debugPrint('[SystemTrayService] Context menu set successfully');
      
      // 在 macOS 上，菜单应该自动显示，但可能需要验证
      if (Platform.isMacOS) {
        debugPrint('[SystemTrayService] macOS: Menu should be shown automatically on click');
        debugPrint('[SystemTrayService] macOS: If menu does not show, this may be a tray_manager issue');
      }
    } catch (error, stackTrace) {
      debugPrint('[SystemTrayService] Failed to build menu: $error\n$stackTrace');
    }
  }

  /// 处理菜单项点击事件
  Future<void> _handleMenuItemClick(MenuItem menuItem) async {
    if (_disposed) {
      return;
    }

    try {
      final key = menuItem.key ?? '';
      debugPrint('[SystemTrayService] Menu item clicked: key="$key", label="${menuItem.label}"');

      if (key == TrayConstants.debugMenuKey) {
        debugPrint('[SystemTrayService] Debug menu item clicked - doing nothing');
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
    } catch (error, stackTrace) {
      debugPrint('[SystemTrayService] Failed to handle menu item click: $error\n$stackTrace');
    }
  }

  Future<void> _showWindowAndNavigate(String route) async {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        await windowManager.show();
        await windowManager.focus();
      }
      AppRouter.router.go(route);
    } catch (error, stackTrace) {
      debugPrint('[SystemTrayService] Failed to navigate: $error\n$stackTrace');
    }
  }

  Future<void> _quitApplication() async {
    try {
      await dispose();
    } catch (error, stackTrace) {
      debugPrint('[SystemTrayService] Error during dispose: $error\n$stackTrace');
    } finally {
      if (Platform.isMacOS) {
        await windowManager.hide();
      }
      await windowManager.close();
      exit(0);
    }
  }

  /// 清理资源
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    try {
      _disposed = true;

      // 移除事件监听器
      _trayManager.removeListener(_listener);

      // 移除托盘图标
      await _trayManager.destroy();

      debugPrint('[SystemTrayService] Disposed successfully');
    } catch (error, stackTrace) {
      debugPrint('[SystemTrayService] Failed to dispose: $error\n$stackTrace');
    }
  }

  /// 主动弹出菜单（主要用于 macOS/Linux 调试）
  Future<void> showMenu() async {
    if (_disposed) {
      return;
    }
    try {
      await _trayManager.popUpContextMenu();
    } catch (error, stackTrace) {
      debugPrint('[SystemTrayService] Failed to show menu: $error\n$stackTrace');
    }
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
    debugPrint('[SystemTrayService] Tray icon clicked (left button)');
    _ensureMenuVisible();
  }

  @override
  void onTrayIconRightMouseDown() {
    debugPrint('[SystemTrayService] Tray icon clicked (right button)');
    _ensureMenuVisible();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    debugPrint('[SystemTrayService] Menu item clicked: ${menuItem.key} - ${menuItem.label}');
    final service = _service;
    if (service == null) {
      return;
    }
    unawaited(service._handleMenuItemClick(menuItem));
  }

  void _ensureMenuVisible() {
    final service = _service;
    if (service == null) {
      return;
    }
    if (Platform.isMacOS || Platform.isLinux) {
      service.showMenu();
    }
  }
}
