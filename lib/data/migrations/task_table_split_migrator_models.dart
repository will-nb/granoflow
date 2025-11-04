// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: undefined_identifier
// ignore_for_file: undefined_getter
// ignore_for_file: undefined_setter

import 'package:flutter/foundation.dart';

/// 迁移阶段进度。
@immutable
class MigrationProgress {
  const MigrationProgress({required this.stage, this.message});

  final MigrationStage stage;
  final String? message;
}

/// 迁移阶段定义。
enum MigrationStage {
  prepare,
  scan,
  migrateProjects,
  migrateMilestones,
  migrateTasks,
  cleanup,
  complete,
}

/// 迁移执行报告。
@immutable
class MigrationReport {
  const MigrationReport({
    this.projectCount = 0,
    this.milestoneCount = 0,
    this.taskCount = 0,
  });

  final int projectCount;
  final int milestoneCount;
  final int taskCount;
}

