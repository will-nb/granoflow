import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/task.dart';

final navigationIndexProvider = StateProvider<int>((ref) => 0);

final expandedRootTaskIdProvider = StateProvider<String?>((ref) => null);

/// Provider for managing expanded task ID in task list page
final taskListExpandedTaskIdProvider = StateProvider<String?>((ref) => null);
final inboxExpandedTaskIdProvider =
    StateProvider<Set<String>>((ref) => <String>{});
final projectsExpandedTaskIdProvider = StateProvider<String?>((ref) => null);

/// Provider for managing expanded task IDs in tasks section (按分区管理)
///
/// 每个分区独立管理展开状态，使用 StateProvider.family 按分区分别管理。
///
/// 使用方式：
/// ```dart
/// final expandedTaskIds = ref.watch(tasksSectionExpandedTaskIdProvider(TaskSection.today));
/// ```
final tasksSectionExpandedTaskIdProvider =
    StateProvider.family<Set<String>, TaskSection>(
  (ref, section) => <String>{},
);

/// Provider for managing quick tasks section expanded state
/// true = expanded, false = collapsed, defaults to false
final quickTasksExpandedProvider = StateProvider<bool>((ref) => false);

/// Provider for managing expanded task IDs in completed page
final completedTasksExpandedProvider =
    StateProvider<Set<String>>((ref) => <String>{});

/// Provider for managing expanded task IDs in archived page
final archivedTasksExpandedProvider =
    StateProvider<Set<String>>((ref) => <String>{});

/// Provider for managing expanded task IDs in milestone task list (按里程碑管理)
final milestoneExpandedTaskIdProvider =
    StateProvider.family<Set<String>, String>(
  (ref, milestoneId) => <String>{},
);

