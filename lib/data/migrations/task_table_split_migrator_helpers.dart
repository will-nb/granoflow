// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: undefined_identifier
// ignore_for_file: undefined_getter
// ignore_for_file: undefined_setter

import '../isar/milestone_entity.dart';
import '../isar/project_entity.dart';
import '../isar/task_entity.dart';

/// 迁移辅助方法
class TaskTableSplitMigratorHelpers {
  /// 将 TaskLogEntryEntity 转换为 ProjectLogEntryEntity
  static ProjectLogEntryEntity convertToProjectLog(
    TaskLogEntryEntity taskLog,
  ) {
    return ProjectLogEntryEntity()
      ..timestamp = taskLog.timestamp
      ..action = taskLog.action
      ..previous = taskLog.previous
      ..next = taskLog.next
      ..actor = taskLog.actor;
  }

  /// 将 TaskLogEntryEntity 转换为 MilestoneLogEntryEntity
  static MilestoneLogEntryEntity convertToMilestoneLog(
    TaskLogEntryEntity taskLog,
  ) {
    return MilestoneLogEntryEntity()
      ..timestamp = taskLog.timestamp
      ..action = taskLog.action
      ..previous = taskLog.previous
      ..next = taskLog.next
      ..actor = taskLog.actor;
  }
}

