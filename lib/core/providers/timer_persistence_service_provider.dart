import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/timer_persistence_service.dart';

/// 计时器状态持久化服务 Provider
final timerPersistenceServiceProvider = Provider<TimerPersistenceService>((ref) {
  return TimerPersistenceService();
});

