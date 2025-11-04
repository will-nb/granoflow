// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: undefined_identifier
// ignore_for_file: undefined_getter
// ignore_for_file: undefined_setter

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../isar/project_entity.dart';
import '../isar/task_entity.dart';
import 'task_table_split_migrator_models.dart';
import 'task_table_split_migrator_stages.dart';

/// 拆分 Task 表为 Project/Milestone/Task 三表的迁移工具。
///
/// **已废弃**：此迁移脚本仅用于历史数据迁移参考。
/// 当前架构采用全新安装方式：更新种子导入逻辑，然后重新安装应用。
/// 由于 TaskKind 枚举已被移除，此脚本无法编译运行。
/// 如需迁移历史数据，请参考此脚本的逻辑，手动编写迁移代码。
///
/// 流程分为：
/// 1. `dryRun`：扫描数据计算影响面；
/// 2. `apply`：在事务中执行实际迁移；
/// 3. `rollback`：将拆分后的数据恢复为旧结构。
class TaskTableSplitMigrator {
  TaskTableSplitMigrator(this._isar, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Isar _isar;
  // ignore: unused_field
  final DateTime Function() _clock; // 保留用于未来可能的日志记录

  /// 执行 dry-run，统计迁移影响并输出校验信息。
  Future<MigrationReport> dryRun({
    ValueChanged<MigrationProgress>? onProgress,
  }) async {
    onProgress?.call(const MigrationProgress(stage: MigrationStage.prepare));

    final tasks = await _isar.taskEntitys.where().findAll();
    // 这个废弃使用是必要的，用于迁移旧数据中的 taskKind
    final projectCandidates = tasks
        .where((task) => task.taskKind == TaskKind.project)
        .toList();
    // 这个废弃使用是必要的，用于迁移旧数据中的 taskKind
    final milestoneCandidates = tasks
        .where((task) => task.taskKind == TaskKind.milestone)
        .toList();
    // 这个废弃使用是必要的，用于迁移旧数据中的 taskKind
    final regularTasks = tasks
        .where((task) => task.taskKind == TaskKind.regular)
        .toList();

    final orphanMilestones = <TaskEntity>[];
    final milestoneProjectMap = <int, TaskEntity?>{};

    for (final milestone in milestoneCandidates) {
      if (milestone.parentId == null) {
        orphanMilestones.add(milestone);
        milestoneProjectMap[milestone.id] = null;
        continue;
      }
      final parent = projectCandidates.firstWhere(
        (p) => p.id == milestone.parentId,
        orElse: () => TaskEntity()..id = Isar.autoIncrement,
      );
      if (parent.id == Isar.autoIncrement) {
        orphanMilestones.add(milestone);
        milestoneProjectMap[milestone.id] = null;
      } else {
        milestoneProjectMap[milestone.id] = parent;
      }
    }

    onProgress?.call(const MigrationProgress(stage: MigrationStage.scan));

    final report = MigrationReport(
      projectCount: projectCandidates.length,
      milestoneCount: milestoneCandidates.length,
      taskCount: regularTasks.length,
    );

    if (orphanMilestones.isNotEmpty) {
      final orphanTitles = orphanMilestones
          .map((m) => m.title)
          .take(5)
          .join(', ');
      onProgress?.call(
        MigrationProgress(
          stage: MigrationStage.scan,
          message: '检测到 $orphanMilestones 个未关联项目的里程碑（示例：$orphanTitles）',
        ),
      );
    }

    onProgress?.call(const MigrationProgress(stage: MigrationStage.complete));
    return report;
  }

  /// 正式执行迁移。
  Future<MigrationReport> apply({
    ValueChanged<MigrationProgress>? onProgress,
  }) async {
    onProgress?.call(const MigrationProgress(stage: MigrationStage.prepare));

    return _isar.writeTxn<MigrationReport>(() async {
      final context = await MigrationContext.build(_isar);

      onProgress?.call(
        MigrationProgress(
          stage: MigrationStage.scan,
          message:
              '扫描完成：projects=${context.projectTasks.length}, milestones=${context.milestoneTasks.length}, tasks=${context.regularTasks.length}',
        ),
      );

      await TaskTableSplitMigratorStages.migrateProjects(
        _isar,
        context,
        onProgress,
      );
      await TaskTableSplitMigratorStages.migrateMilestones(
        _isar,
        context,
        onProgress,
      );
      await TaskTableSplitMigratorStages.migrateTasks(
        _isar,
        context,
        onProgress,
      );
      await TaskTableSplitMigratorStages.cleanup(
        _isar,
        context,
        onProgress,
      );

      onProgress?.call(const MigrationProgress(stage: MigrationStage.complete));

      return MigrationReport(
        projectCount: context.projectTasks.length,
        milestoneCount: context.milestoneTasks.length,
        taskCount: context.regularTasks.length,
      );
    });
  }

  /// 回滚至拆表前结构。
  Future<void> rollback({ValueChanged<MigrationProgress>? onProgress}) async {
    onProgress?.call(const MigrationProgress(stage: MigrationStage.prepare));

    await _isar.writeTxn(() async {
      final projects = await _isar.projectEntitys.where().findAll();
      final milestones = await _isar.milestoneEntitys.where().findAll();

      onProgress?.call(
        MigrationProgress(
          stage: MigrationStage.scan,
          message:
              '准备回滚：projects=${projects.length}, milestones=${milestones.length}',
        ),
      );

      final taskEntities = await _isar.taskEntitys.where().findAll();
      final taskMap = {for (final task in taskEntities) task.id: task};

      // 1. 恢复项目
      for (final project in projects) {
        final task = TaskEntity()
          ..taskId = project.projectId
          ..title = project.title
          ..status = project.status
          ..dueAt = project.dueAt
          ..startedAt = project.startedAt
          ..endedAt = project.endedAt
          ..createdAt = project.createdAt
          ..updatedAt = project.updatedAt
          ..parentId = null
          ..parentTaskId = null
          ..projectIsarId = null
          ..projectId = null
          ..milestoneIsarId = null
          ..milestoneId = null
          ..sortIndex = project.sortIndex
          ..tags = project.tags
          ..templateLockCount = project.templateLockCount
          ..seedSlug = project.seedSlug
          ..allowInstantComplete = project.allowInstantComplete
          ..description = project.description
          ..taskKind = TaskKind.project
          ..logs = project.logs
              .map(
                (log) => TaskLogEntryEntity()
                  ..timestamp = log.timestamp
                  ..action = log.action
                  ..previous = log.previous
                  ..next = log.next
                  ..actor = log.actor,
              )
              .toList();
        final id = await _isar.taskEntitys.put(task);
        task.id = id;
        taskMap[id] = task;
      }

      // 2. 恢复里程碑
      for (final milestone in milestones) {
        final project = projects.firstWhere(
          (p) => p.projectId == milestone.projectId,
          orElse: () => ProjectEntity()..id = Isar.autoIncrement,
        );

        final task = TaskEntity()
          ..taskId = milestone.milestoneId
          ..title = milestone.title
          ..status = milestone.status
          ..dueAt = milestone.dueAt
          ..startedAt = milestone.startedAt
          ..endedAt = milestone.endedAt
          ..createdAt = milestone.createdAt
          ..updatedAt = milestone.updatedAt
          ..parentId = project.id == Isar.autoIncrement ? null : project.id
          ..parentTaskId = null
          ..projectIsarId = null
          ..projectId = null
          ..milestoneIsarId = null
          ..milestoneId = null
          ..sortIndex = milestone.sortIndex
          ..tags = milestone.tags
          ..templateLockCount = milestone.templateLockCount
          ..seedSlug = milestone.seedSlug
          ..allowInstantComplete = milestone.allowInstantComplete
          ..description = milestone.description
          ..taskKind = TaskKind.milestone
          ..logs = milestone.logs
              .map(
                (log) => TaskLogEntryEntity()
                  ..timestamp = log.timestamp
                  ..action = log.action
                  ..previous = log.previous
                  ..next = log.next
                  ..actor = log.actor,
              )
              .toList();
        final id = await _isar.taskEntitys.put(task);
        task.id = id;
        taskMap[id] = task;
      }

      // 3. 清理普通任务的项目、里程碑字段
      for (final task in taskMap.values) {
        task.projectIsarId = null;
        task.projectId = null;
        task.milestoneIsarId = null;
        task.milestoneId = null;
        await _isar.taskEntitys.put(task);
      }

      // 删除拆分表
      await _isar.projectEntitys.clear();
      await _isar.milestoneEntitys.clear();
    });

    onProgress?.call(const MigrationProgress(stage: MigrationStage.complete));
  }
}
