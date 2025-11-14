/// 系统托盘相关常量
/// 
/// 定义系统托盘菜单项的 key、图标路径等常量
class TrayConstants {
  const TrayConstants._();

  // ===== 菜单项 key 常量 =====
  
  /// 调试菜单项 key
  static const String debugMenuKey = 'debug_menu';

  /// 设置菜单项 key
  static const String settingsKey = 'settings';

  /// 退出菜单项 key
  static const String quitKey = 'quit';

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
}
