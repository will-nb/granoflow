import 'dart:io' show Platform;

// 条件导入：只在移动平台导入真实的 flutter_foreground_task
// 在桌面和 web 平台使用 stub
import 'package:flutter_foreground_task/flutter_foreground_task.dart'
    if (dart.library.html) 'flutter_foreground_task_stub.dart';

// 重新导出所有需要的类和函数
export 'package:flutter_foreground_task/flutter_foreground_task.dart'
    if (dart.library.html) 'flutter_foreground_task_stub.dart';

/// 包装 FlutterForegroundTask.init，只在移动平台执行
void initFlutterForegroundTask({
  required dynamic androidNotificationOptions,
  required dynamic iosNotificationOptions,
  required dynamic foregroundTaskOptions,
}) {
  // 只在移动平台初始化
  if (Platform.isAndroid || Platform.isIOS) {
    FlutterForegroundTask.init(
      androidNotificationOptions: androidNotificationOptions,
      iosNotificationOptions: iosNotificationOptions,
      foregroundTaskOptions: foregroundTaskOptions,
    );
  }
  // 在桌面和 web 平台，什么都不做
}

