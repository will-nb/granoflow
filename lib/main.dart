import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'package:flutter_foreground_task/flutter_foreground_task';

import 'core/app.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 window_manager（仅桌面平台）
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
  }

  // 初始化前台服务（Android）- 计时器服务
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'grano_timer',
      channelName: 'GranoFlow Timer',
      channelDescription: '计时进行中',
      channelImportance: NotificationChannelImportance.HIGH,
      priority: NotificationPriority.HIGH,
      enableVibration: true,
      playSound: true,
      visibility: NotificationVisibility.VISIBILITY_PUBLIC,
    ),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(1000),
      autoRunOnBoot: false,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );

  // 注意：置顶任务的前台服务使用相同的 FlutterForegroundTask 初始化
  // 但使用不同的通知渠道和处理器（通过 pinnedTaskStartCallback）

  // 初始化通知服务
  final notificationService = NotificationService();
  await notificationService.initialize();

  // 请求通知权限（Android 13+ 和 iOS）
  // 在集成测试环境中跳过权限请求，避免弹出对话框阻塞测试
  // 测试环境可以通过 adb 预先授予权限
  // 检查是否在集成测试环境中（通过环境变量或 kDebugMode）
  final isIntegrationTest = const bool.fromEnvironment('INTEGRATION_TEST', defaultValue: false);
  if (!isIntegrationTest) {
    await notificationService.requestPermission();
  }

  // 根据 DatabaseConfig 初始化数据库（默认使用 Drift）
  // Drift 数据库将在 DriftAdapter 中自动初始化
  // Web 平台使用 IndexedDB，移动端使用 SQLite
  // 注意：不需要检测或迁移历史数据，应用启动时直接使用配置的数据库类型（默认 Drift）
  // 首次使用 Drift 时，数据库为空，种子数据会自动导入
  
  runApp(
    const ProviderScope(
      child: GranoFlowApp(),
    ),
  );
}
