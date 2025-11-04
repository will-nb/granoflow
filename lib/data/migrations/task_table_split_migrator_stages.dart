// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: undefined_identifier
// ignore_for_file: undefined_getter
// ignore_for_file: undefined_setter

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../isar/milestone_entity.dart';
import '../isar/project_entity.dart';
import '../isar/task_entity.dart';
import 'task_table_split_migrator_helpers.dart';
import 'task_table_split_migrator_models.dart';

/// 迁移上下文，用于在迁移过程中传递数据
// 注意：虽然是私有类，但需要被主文件访问，所以使用 library 私有而非文件私有
class MigrationContext {
  MigrationContext._(
    this.projectTasks,
    this.milestoneTasks,
    this.regularTasks,
    this.taskCopies,
  );

  final List<TaskEntity> projectTasks;
  final List<TaskEntity> milestoneTasks;
  final List<TaskEntity> regularTasks;
  final Map<int, TaskEntity> taskCopies;

  final Map<int, ProjectEntity> projectMap = <int, ProjectEntity>{};
  final Map<int, MilestoneEntity> milestoneMap = <int, MilestoneEntity>{};

  static Future<MigrationContext> build(Isar isar) async {
    final tasks = await isar.taskEntitys.where().findAll();
    // 这个废弃使用是必要的，用于迁移旧数据中的 taskKind
    final projectTasks = tasks
        .where((task) => task.taskKind == TaskKind.project)
        .toList();
    // 这个废弃使用是必要的，用于迁移旧数据中的 taskKind
    final milestoneTasks = tasks
        .where((task) => task.taskKind == TaskKind.milestone)
        .toList();
    // 这个废弃使用是必要的，用于迁移旧数据中的 taskKind
    final regularTasks = tasks
        .where((task) => task.taskKind == TaskKind.regular)
        .toList();

    final copies = <int, TaskEntity>{};
    for (final task in tasks) {
      final copy = TaskEntity()
        ..id = task.id
        ..taskId = task.taskId
        ..title = task.title
        ..status = task.status
        ..dueAt = task.dueAt
        ..startedAt = task.startedAt
        ..endedAt = task.endedAt
        ..createdAt = task.createdAt
        ..updatedAt = task.updatedAt
        ..parentId = task.parentId
        ..parentTaskId = task.parentTaskId
        ..projectIsarId = task.projectIsarId
        ..projectId = task.projectId
        ..milestoneIsarId = task.milestoneIsarId
        ..milestoneId = task.milestoneId
        ..sortIndex = task.sortIndex
        ..tags = List<String>.from(task.tags)
        ..templateLockCount = task.templateLockCount
        ..seedSlug = task.seedSlug
        ..allowInstantComplete = task.allowInstantComplete
        ..description = task.description
        ..taskKind = task.taskKind
        ..logs = task.logs
            .map(
              (log) => TaskLogEntryEntity()
                ..timestamp = log.timestamp
                ..action = log.action
                ..previous = log.previous
                ..next = log.next
                ..actor = log.actor,
            )
            .toList();
      copies[task.id] = copy;
    }

    return MigrationContext._(
      projectTasks,
      milestoneTasks,
      regularTasks,
      copies,
    );
  }

  ProjectEntity? _findOwningProject(TaskEntity task) {
    var parentId = task.parentId;
    while (parentId != null) {
      if (projectMap.containsKey(parentId)) {
        return projectMap[parentId];
      }
      if (milestoneMap.containsKey(parentId)) {
        final milestone = milestoneMap[parentId]!;
        return projectMap.values.firstWhere(
          (project) => project.projectId == milestone.projectId,
          orElse: () => ProjectEntity()..id = Isar.autoIncrement,
        );
      }
      final parent = taskCopies[parentId];
      parentId = parent?.parentId;
    }
    return null;
  }

  MilestoneEntity? _findOwningMilestone(TaskEntity task) {
    var parentId = task.parentId;
    while (parentId != null) {
      if (milestoneMap.containsKey(parentId)) {
        return milestoneMap[parentId];
      }
      final parent = taskCopies[parentId];
      parentId = parent?.parentId;
    }
    return null;
  }
}

/// 迁移阶段方法
class TaskTableSplitMigratorStages {
  /// 迁移项目
  static Future<void> migrateProjects(
    Isar isar,
    MigrationContext context,
    ValueChanged<MigrationProgress>? onProgress,
  ) async {
    onProgress?.call(
      const MigrationProgress(stage: MigrationStage.migrateProjects),
    );

    for (final projectTask in context.projectTasks) {
      final entity = ProjectEntity()
        ..projectId = projectTask.taskId
        ..title = projectTask.title
        ..status = projectTask.status
        ..dueAt = projectTask.dueAt
        ..startedAt = projectTask.startedAt
        ..endedAt = projectTask.endedAt
        ..createdAt = projectTask.createdAt
        ..updatedAt = projectTask.updatedAt
        ..sortIndex = projectTask.sortIndex
        ..tags = projectTask.tags
        ..templateLockCount = projectTask.templateLockCount
        ..seedSlug = projectTask.seedSlug
        ..allowInstantComplete = projectTask.allowInstantComplete
        ..description = projectTask.description
        ..logs = projectTask.logs
            .map(TaskTableSplitMigratorHelpers.convertToProjectLog)
            .toList();

      final id = await isar.projectEntitys.put(entity);
      entity.id = id;
      context.projectMap[projectTask.id] = entity;
    }
  }

  /// 迁移里程碑
  static Future<void> migrateMilestones(
    Isar isar,
    MigrationContext context,
    ValueChanged<MigrationProgress>? onProgress,
  ) async {
    onProgress?.call(
      const MigrationProgress(stage: MigrationStage.migrateMilestones),
    );

    for (final milestoneTask in context.milestoneTasks) {
      final parentProject = context.projectMap[milestoneTask.parentId];
      final entity = MilestoneEntity()
        ..milestoneId = milestoneTask.taskId
        ..projectId = parentProject?.projectId ?? ''
        ..projectIsarId = parentProject?.id
        ..title = milestoneTask.title
        ..status = milestoneTask.status
        ..dueAt = milestoneTask.dueAt
        ..startedAt = milestoneTask.startedAt
        ..endedAt = milestoneTask.endedAt
        ..createdAt = milestoneTask.createdAt
        ..updatedAt = milestoneTask.updatedAt
        ..sortIndex = milestoneTask.sortIndex
        ..tags = milestoneTask.tags
        ..templateLockCount = milestoneTask.templateLockCount
        ..seedSlug = milestoneTask.seedSlug
        ..allowInstantComplete = milestoneTask.allowInstantComplete
        ..description = milestoneTask.description
        ..logs = milestoneTask.logs
            .map(TaskTableSplitMigratorHelpers.convertToMilestoneLog)
            .toList();

      final id = await isar.milestoneEntitys.put(entity);
      entity.id = id;
      context.milestoneMap[milestoneTask.id] = entity;
    }
  }

  /// 迁移任务
  static Future<void> migrateTasks(
    Isar isar,
    MigrationContext context,
    ValueChanged<MigrationProgress>? onProgress,
  ) async {
    onProgress?.call(
      const MigrationProgress(stage: MigrationStage.migrateTasks),
    );

    for (final task in context.regularTasks) {
      final updated = context.taskCopies[task.id]!;
      final parent = context.taskCopies[task.parentId];

      if (parent == null) {
        updated.parentTaskId = null;
      } else if (context.projectMap.containsKey(parent.id) ||
          context.milestoneMap.containsKey(parent.id)) {
        updated.parentTaskId = null;
      } else {
        updated.parentTaskId = parent.id;
      }

      final parentProject = context._findOwningProject(task);
      final parentMilestone = context._findOwningMilestone(task);

      if (parentProject != null) {
        updated.projectIsarId = parentProject.id;
        updated.projectId = parentProject.projectId;
      } else {
        updated.projectIsarId = null;
        updated.projectId = null;
      }

      if (parentMilestone != null) {
        updated.milestoneIsarId = parentMilestone.id;
        updated.milestoneId = parentMilestone.milestoneId;
      } else {
        updated.milestoneIsarId = null;
        updated.milestoneId = null;
      }

      await isar.taskEntitys.put(updated);
    }
  }

  /// 清理
  static Future<void> cleanup(
    Isar isar,
    MigrationContext context,
    ValueChanged<MigrationProgress>? onProgress,
  ) async {
    onProgress?.call(const MigrationProgress(stage: MigrationStage.cleanup));

    for (final projectTask in context.projectTasks) {
      await isar.taskEntitys.delete(projectTask.id);
    }
    for (final milestoneTask in context.milestoneTasks) {
      await isar.taskEntitys.delete(milestoneTask.id);
    }
  }
}

