import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/milestone.dart';
import '../../data/models/project.dart';
import '../../data/models/task.dart';
import '../services/tag_service.dart';
import 'project_filter_providers.dart';
import 'repository_providers.dart';
import 'service_providers.dart';
import 'task_filter_providers.dart';

final taskSectionsProvider = StreamProvider.family<List<Task>, TaskSection>((
  ref,
  section,
) async* {
  final filter = ref.watch(tasksFilterProvider);
  final repository = ref.watch(taskRepositoryProvider);
  
  await for (final tasks in repository.watchSection(section)) {
    // 应用筛选逻辑（内存筛选，参考 watchInboxFiltered 的实现）
    final filtered = tasks.where((task) {
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

final inboxTasksProvider = StreamProvider<List<Task>>((ref) {
  final filter = ref.watch(inboxFilterProvider);
  return ref
      .watch(taskRepositoryProvider)
      .watchInboxFiltered(
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
  return ref.watch(taskRepositoryProvider).listRoots();
});

final projectsDomainProvider = StreamProvider<List<Project>>((ref) {
  return ref.watch(projectServiceProvider).watchActiveProjects();
});

/// 根据筛选状态返回项目列表
/// 根据 projectFilterStatusProvider 的值返回对应状态的项目列表
final projectsByStatusProvider = StreamProvider<List<Project>>((ref) {
  final filterStatus = ref.watch(projectFilterStatusProvider);
  final repository = ref.watch(projectRepositoryProvider);
  return repository.watchProjectsByStatus(filterStatus);
});

final projectMilestonesDomainProvider =
    StreamProvider.family<List<Milestone>, String>((ref, projectId) {
      return ref.watch(projectServiceProvider).watchMilestones(projectId);
    });

final milestoneTasksProvider = StreamProvider.family<List<Task>, String>((
  ref,
  milestoneId,
) {
  return ref.watch(taskRepositoryProvider).watchTasksByMilestoneId(milestoneId);
});

final quickTasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskRepositoryProvider).watchQuickTasks();
});

