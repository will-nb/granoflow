/// 系统托盘相关常量
/// 
/// 定义系统托盘菜单项的 key、图标、路径等常量
class TrayConstants {
  const TrayConstants._();

  // ===== 菜单项 key 常量 =====
  
  /// 计时器状态菜单项 key
  static const String timerStatusKey = 'timer_status';
  
  /// 快速添加任务菜单项 key
  static const String quickAddTaskKey = 'quick_add_task';
  
  /// 设置菜单项 key
  static const String settingsKey = 'settings';
  
  /// 退出菜单项 key
  static const String quitKey = 'quit';
  
  /// 任务菜单项 key 前缀
  static const String taskKeyPrefix = 'task_';
  
  /// 任务开始计时子菜单项 key 后缀
  static const String taskStartTimerKeySuffix = '_start_timer';
  
  /// 任务打开子菜单项 key 后缀
  static const String taskOpenKeySuffix = '_open';

  // ===== 图标常量 =====
  
  /// 计时器图标
  static const String timerIcon = '⏱️';
  
  /// 快速添加图标
  static const String quickAddIcon = '➕';
  
  /// 设置图标
  static const String settingsIcon = '⚙️';
  
  /// 退出图标
  static const String quitIcon = '🚪';
  
  /// 活跃状态图标（空框）
  static const String statusIconActive = '☐';
  
  /// 已完成状态图标（勾选）
  static const String statusIconCompleted = '☑';
  
  /// 已删除状态图标（叉号）
  static const String statusIconDeleted = '☒';
  
  /// 警告图标（用于逾期任务）
  static const String warningIcon = '⚠️ ';

  // ===== 图标路径常量 =====
  
  /// Windows 平台图标路径（ICO 格式）
  static const String windowsIconPath = 'assets/logo/app_icon.ico';
  
  /// macOS/Linux 平台图标路径（PNG 格式）
  static const String macosLinuxIconPath = 'assets/logo/granostack-logo-transparent.png';

  // ===== 工具方法 =====
  
  /// 构建任务菜单项 key
  /// 
  /// [taskId] 任务 ID
  /// 返回格式：'task_{taskId}'
  static String buildTaskKey(String taskId) {
    return '${taskKeyPrefix}$taskId';
  }
  
  /// 构建任务开始计时子菜单项 key
  /// 
  /// [taskId] 任务 ID
  /// 返回格式：'task_{taskId}_start_timer'
  static String buildTaskStartTimerKey(String taskId) {
    return '${buildTaskKey(taskId)}$taskStartTimerKeySuffix';
  }
  
  /// 构建任务打开子菜单项 key
  /// 
  /// [taskId] 任务 ID
  /// 返回格式：'task_{taskId}_open'
  static String buildTaskOpenKey(String taskId) {
    return '${buildTaskKey(taskId)}$taskOpenKeySuffix';
  }
  
  /// 从菜单项 key 中解析任务 ID
  /// 
  /// [key] 菜单项 key
  /// 返回任务 ID，如果 key 不是任务相关的 key 则返回 null
  static String? parseTaskIdFromKey(String key) {
    if (!key.startsWith(taskKeyPrefix)) {
      return null;
    }
    
    // 移除前缀
    var taskId = key.substring(taskKeyPrefix.length);
    
    // 如果是子菜单项，移除后缀
    if (taskId.endsWith(taskStartTimerKeySuffix)) {
      taskId = taskId.substring(0, taskId.length - taskStartTimerKeySuffix.length);
    } else if (taskId.endsWith(taskOpenKeySuffix)) {
      taskId = taskId.substring(0, taskId.length - taskOpenKeySuffix.length);
    }
    
    return taskId.isEmpty ? null : taskId;
  }
}

