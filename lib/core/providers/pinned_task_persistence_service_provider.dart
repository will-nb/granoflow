import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/pinned_task_persistence_service.dart';

/// 置顶任务持久化服务 Provider
final pinnedTaskPersistenceServiceProvider = Provider<PinnedTaskPersistenceService>((ref) {
  return PinnedTaskPersistenceService();
});

