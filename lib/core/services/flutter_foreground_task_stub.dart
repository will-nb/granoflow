/// Stub file for flutter_foreground_task on unsupported platforms
/// 
/// This file provides empty implementations for platforms that don't support
/// flutter_foreground_task (e.g., web, desktop).

// Stub class to prevent compilation errors on unsupported platforms
class FlutterForegroundTask {
  static void init({
    dynamic androidNotificationOptions,
    dynamic iosNotificationOptions,
    dynamic foregroundTaskOptions,
  }) {
    // No-op on unsupported platforms
  }
}

// Stub classes for notification options
class AndroidNotificationOptions {
  final String channelId;
  final String channelName;
  final String channelDescription;
  final dynamic channelImportance;
  final dynamic priority;
  final bool enableVibration;
  final bool playSound;
  final dynamic visibility;

  const AndroidNotificationOptions({
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
    required this.channelImportance,
    required this.priority,
    required this.enableVibration,
    required this.playSound,
    required this.visibility,
  });
}

class IOSNotificationOptions {
  const IOSNotificationOptions();
}

class ForegroundTaskOptions {
  final dynamic eventAction;
  final bool autoRunOnBoot;
  final bool allowWakeLock;
  final bool allowWifiLock;

  const ForegroundTaskOptions({
    required this.eventAction,
    required this.autoRunOnBoot,
    required this.allowWakeLock,
    required this.allowWifiLock,
  });
}

class NotificationChannelImportance {
  static const dynamic HIGH = null;
}

class NotificationPriority {
  static const dynamic HIGH = null;
}

class NotificationVisibility {
  static const dynamic VISIBILITY_PUBLIC = null;
}

class ForegroundTaskEventAction {
  static dynamic repeat(int milliseconds) => null;
}

