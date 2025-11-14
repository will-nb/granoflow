import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/system_tray_service.dart';

/// 系统托盘服务 Provider
/// 
/// 提供 SystemTrayService 实例的全局访问
final systemTrayServiceProvider = FutureProvider<SystemTrayService>((ref) async {
  return SystemTrayService(ref);
});

/// 系统托盘初始化状态 Provider
/// 
/// 跟踪系统托盘是否已初始化
final systemTrayInitializedProvider = StateProvider<bool>((ref) => false);

