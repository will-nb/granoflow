/// 系统托盘相关常量
/// 
/// 定义系统托盘菜单项的 key、图标路径等常量
class TrayConstants {
  const TrayConstants._();

  // ===== 菜单项 key 常量 =====
  
  /// 调试菜单项 key
  static const String debugMenuKey = 'debug_menu';

  /// 计时器状态菜单项 key
  static const String timerStatusKey = 'timer_status';

  /// 快速添加任务菜单项 key
  static const String quickAddTaskKey = 'quick_add_task';

  /// 设置菜单项 key
  static const String settingsKey = 'settings';

  /// 退出菜单项 key
  static const String quitKey = 'quit';

  /// 逾期“更多任务”菜单项 key
  static const String overdueMoreKey = 'overdue_more';

  /// 今日“更多任务”菜单项 key
  static const String todayMoreKey = 'today_more';

  /// 任务菜单项 key 前缀
  static const String taskKeyPrefix = 'task_';

  // ===== 图标路径常量 =====
  
  /// Windows 平台图标路径（ICO 格式）
  static const String windowsIconPath = 'assets/logo/app_icon.ico';
  
  /// macOS/Linux 平台图标路径（PNG 格式）
  static const String macosLinuxIconPath = 'assets/logo/granostack-logo-transparent.png';

  // ===== 图标常量 =====

  /// 设置图标
  static const String settingsIcon = '⚙️';

  /// 退出图标
  static const String quitIcon = '🚪';

  /// 计时器图标
  static const String timerIcon = '⏱️';

  /// 快速添加图标
  static const String quickAddIcon = '➕';


  /// 警告图标（逾期）
  static const String warningIcon = '⚠️ ';

  // ===== 展示限制 =====

  /// 逾期任务最大展示数量
  static const int maxOverdueTasks = 20;

  /// 今日任务最大展示数量
  static const int maxTodayTasks = 20;

  // ===== 工具方法 =====

  static String buildTaskKey(String taskId) => '$taskKeyPrefix$taskId';

  static String? parseTaskIdFromKey(String key) {
    if (!key.startsWith(taskKeyPrefix)) {
      return null;
    }
    final taskId = key.substring(taskKeyPrefix.length);
    return taskId.isEmpty ? null : taskId;
  }
}
