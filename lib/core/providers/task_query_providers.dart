import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/milestone.dart';
import '../../data/models/project.dart';
import '../../data/models/task.dart';
import '../services/tag_service.dart';
import '../utils/project_statistics_utils.dart' show ProgressStatistics, ProjectStatisticsUtils;
import '../utils/task_section_utils.dart';
import 'project_filter_providers.dart';
import 'repository_providers.dart';
import 'service_providers.dart';
import 'task_filter_providers.dart';

final taskSectionsProvider = StreamProvider.family<List<Task>, TaskSection>((
  ref,
  section,
) async* {
  final filter = ref.watch(tasksFilterProvider);
  final repository = await ref.read(taskRepositoryProvider.future);
  
  await for (final tasks in repository.watchSection(section)) {
    // 对于 today section，需要额外查询已完成任务
    List<Task> allTasks = List<Task>.from(tasks);
    if (section == TaskSection.today) {
      // 查询已完成任务（使用 completed section 的查询逻辑，但按 dueAt 筛选）
      try {
        final completed = await repository.listSectionTasks(TaskSection.completed);
        // 筛选出今日的已完成任务
        final now = DateTime.now();
        final todayStart = TaskSectionUtils.getSectionStartTime(TaskSection.today, now: now);
        final todayEnd = TaskSectionUtils.getSectionEndTimeForQuery(TaskSection.today, now: now);
        final todayCompleted = completed.where((task) {
          if (task.dueAt == null) return false;
          final dueDate = DateTime(task.dueAt!.year, task.dueAt!.month, task.dueAt!.day);
          final startDate = DateTime(todayStart.year, todayStart.month, todayStart.day);
          final endDate = DateTime(todayEnd.year, todayEnd.month, todayEnd.day);
          return (dueDate.isAtSameMomentAs(startDate) || dueDate.isAfter(startDate)) &&
              dueDate.isBefore(endDate);
        }).toList();
        // 合并已完成任务，避免重复
        final existingIds = allTasks.map((t) => t.id).toSet();
        final newCompleted = todayCompleted.where((t) => !existingIds.contains(t.id)).toList();
        allTasks = [...allTasks, ...newCompleted];
      } catch (e) {
        // 如果查询失败，继续使用原始任务列表
        debugPrint('Failed to load completed tasks for today: $e');
      }
    }
    
    // 应用筛选逻辑（内存筛选，参考 watchInboxFiltered 的实现）
    final filtered = allTasks.where((task) {
      final tags = task.tags;
      
      // 场景标签筛选
      if (filter.contextTag != null && filter.contextTag!.isNotEmpty) {
        final normalizedContextTag = TagService.normalizeSlug(filter.contextTag!);
        if (!tags.any((tag) => TagService.normalizeSlug(tag) == normalizedContextTag)) {
          return false;
        }
      }
      
      // 紧急度标签筛选
      if (filter.urgencyTag != null && filter.urgencyTag!.isNotEmpty) {
        final normalizedUrgencyTag = TagService.normalizeSlug(filter.urgencyTag!);
        if (!tags.any((tag) => TagService.normalizeSlug(tag) == normalizedUrgencyTag)) {
          return false;
        }
      }
      
      // 重要度标签筛选
      if (filter.importanceTag != null && filter.importanceTag!.isNotEmpty) {
        final normalizedImportanceTag = TagService.normalizeSlug(filter.importanceTag!);
        if (!tags.any((tag) => TagService.normalizeSlug(tag) == normalizedImportanceTag)) {
          return false;
        }
      }
      
      // 项目筛选
      if (filter.showNoProject == true) {
        if (task.projectId != null && task.projectId!.isNotEmpty) {
          return false;
        }
      } else {
        // 项目ID筛选
        if (filter.projectId != null && filter.projectId!.isNotEmpty) {
          if (task.projectId != filter.projectId) {
            return false;
          }
          
          // 里程碑ID筛选（仅在指定项目时有效）
          if (filter.milestoneId != null && filter.milestoneId!.isNotEmpty) {
            if (task.milestoneId != filter.milestoneId) {
              return false;
            }
          }
        } else {
          // 如果没有指定项目，但有指定里程碑ID，应该过滤掉所有任务
          if (filter.milestoneId != null && filter.milestoneId!.isNotEmpty) {
            return false;
          }
        }
      }
      
      return true;
    }).toList();
    
    yield filtered;
  }
});

final inboxTasksProvider = StreamProvider<List<Task>>((ref) async* {
  final filter = ref.watch(inboxFilterProvider);
  final repository = await ref.read(taskRepositoryProvider.future);
  yield* repository.watchInboxFiltered(
        contextTag: filter.contextTag,
        priorityTag: null, // priorityTag 已废弃，不再使用
        urgencyTag: filter.urgencyTag,
        importanceTag: filter.importanceTag,
        projectId: filter.projectId,
        milestoneId: filter.milestoneId,
        showNoProject: filter.showNoProject,
      );
});

final rootTasksProvider = FutureProvider<List<Task>>((ref) async {
  final repository = await ref.read(taskRepositoryProvider.future);
  return repository.listRoots();
});

final projectsDomainProvider = StreamProvider<List<Project>>((ref) async* {
  final projectService = await ref.read(projectServiceProvider.future);
  await for (final projects in projectService.watchActiveProjects()) {
    // 过滤掉没有里程碑的项目
    final filteredProjects = <Project>[];
    for (final project in projects) {
      final milestones = await projectService.listMilestones(project.id);
      if (milestones.isNotEmpty) {
        filteredProjects.add(project);
      }
    }
    yield filteredProjects;
  }
});

/// 根据筛选状态返回项目列表
/// 根据 projectFilterStatusProvider 的值返回对应状态的项目列表
final projectsByStatusProvider = StreamProvider<List<Project>>((ref) async* {
  final filterStatus = ref.watch(projectFilterStatusProvider);
  final repository = await ref.read(projectRepositoryProvider.future);
  final projectService = await ref.read(projectServiceProvider.future);
  await for (final projects in repository.watchProjectsByStatus(filterStatus)) {
    // 过滤掉没有里程碑的项目
    final filteredProjects = <Project>[];
    for (final project in projects) {
      final milestones = await projectService.listMilestones(project.id);
      if (milestones.isNotEmpty) {
        filteredProjects.add(project);
      }
    }
    yield filteredProjects;
  }
});

/// 用于已完成/已归档页面的项目筛选
/// 显示活跃、已完成、已归档项目（排除伪删除和回收站）
final projectsForCompletedArchivedFilterProvider =
    StreamProvider<List<Project>>((ref) async* {
  final repository = await ref.read(projectRepositoryProvider.future);
  yield* repository.watchProjectsByStatuses({
    TaskStatus.pending,
    TaskStatus.doing,
    TaskStatus.completedActive,
    TaskStatus.archived,
  });
});

/// 用于回收站页面的项目筛选
/// 显示所有项目（排除伪删除）
final projectsForTrashFilterProvider = StreamProvider<List<Project>>((ref) async* {
  final repository = await ref.read(projectRepositoryProvider.future);
  yield* repository.watchProjectsByStatuses({
    TaskStatus.inbox,
    TaskStatus.pending,
    TaskStatus.doing,
    TaskStatus.completedActive,
    TaskStatus.archived,
    TaskStatus.trashed,
  });
});

final projectMilestonesDomainProvider =
    StreamProvider.family<List<Milestone>, String>((ref, projectId) async* {
      final projectService = await ref.read(projectServiceProvider.future);
      yield* projectService.watchMilestones(projectId);
    });

final milestoneTasksProvider = StreamProvider.family<List<Task>, String>((
  ref,
  milestoneId,
) async* {
  final repository = await ref.read(taskRepositoryProvider.future);
  yield* repository.watchTasksByMilestoneId(milestoneId);
});

final quickTasksProvider = StreamProvider<List<Task>>((ref) async* {
  final repository = await ref.read(taskRepositoryProvider.future);
  yield* repository.watchQuickTasks();
});

/// 项目任务统计 Provider
///
/// 输入：项目ID
/// 输出：进度统计（已完成数、总数、进度百分比）
final projectTasksStatisticsProvider =
    StreamProvider.family<ProgressStatistics, String>((
  ref,
  projectId,
) async* {
  try {
    final repository = await ref.read(taskRepositoryProvider.future);
    await for (final tasks in repository.watchTasksByProjectId(projectId)) {
      yield ProjectStatisticsUtils.calculateProjectProgress(projectId, tasks);
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      debugPrint(
        '[projectTasksStatisticsProvider] {event: error, projectId: $projectId, error: $e, stackTrace: $stackTrace}',
      );
    }
    // 返回默认值
    yield const ProgressStatistics(
      completedCount: 0,
      totalCount: 0,
      progress: 0.0,
    );
  }
});

/// 里程碑任务统计 Provider
///
/// 输入：里程碑ID
/// 输出：进度统计（已完成数、总数、进度百分比）
final milestoneTasksStatisticsProvider =
    StreamProvider.family<ProgressStatistics, String>((
  ref,
  milestoneId,
) async* {
  try {
    final repository = await ref.read(taskRepositoryProvider.future);
    await for (final tasks in repository.watchTasksByMilestoneId(milestoneId)) {
      yield ProjectStatisticsUtils.calculateMilestoneProgress(milestoneId, tasks);
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      debugPrint(
        '[milestoneTasksStatisticsProvider] {event: error, milestoneId: $milestoneId, error: $e, stackTrace: $stackTrace}',
      );
    }
    // 返回默认值
    yield const ProgressStatistics(
      completedCount: 0,
      totalCount: 0,
      progress: 0.0,
    );
  }
});

