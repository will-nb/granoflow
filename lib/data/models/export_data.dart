import 'package:flutter/foundation.dart';

import 'milestone.dart';
import 'project.dart';
import 'task.dart';

/// 导出数据模型
/// 
/// 用于导出和导入项目、里程碑和任务数据
/// 所有业务ID（projectId、milestoneId、taskId）使用UUID v4格式
@immutable
class ExportData {
  const ExportData({
    required this.version,
    required this.exportedAt,
    required this.projects,
    required this.milestones,
    required this.tasks,
  });

  /// 导出格式版本
  final String version;

  /// 导出时间（ISO 8601格式）
  final DateTime exportedAt;

  /// 项目列表
  final List<Project> projects;

  /// 里程碑列表
  final List<Milestone> milestones;

  /// 任务列表
  final List<Task> tasks;

  /// 序列化为JSON
  /// 
  /// 排除所有Isar内部ID字段（id、projectIsarId、milestoneIsarId）
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'exportedAt': exportedAt.toIso8601String(),
      'projects': projects.map(_projectToJson).toList(),
      'milestones': milestones.map(_milestoneToJson).toList(),
      'tasks': tasks.map(_taskToJson).toList(),
    };
  }

  /// 从JSON反序列化
  factory ExportData.fromJson(Map<String, dynamic> json) {
    return ExportData(
      version: json['version'] as String,
      exportedAt: DateTime.parse(json['exportedAt'] as String),
      projects: (json['projects'] as List<dynamic>)
          .map((e) => ExportData._projectFromJson(e as Map<String, dynamic>))
          .toList(),
      milestones: (json['milestones'] as List<dynamic>)
          .map((e) => ExportData._milestoneFromJson(e as Map<String, dynamic>))
          .toList(),
      tasks: (json['tasks'] as List<dynamic>)
          .map((e) => ExportData._taskFromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 序列化项目（排除 id 字段）
  Map<String, dynamic> _projectToJson(Project project) {
    return {
      'projectId': project.projectId,
      'title': project.title,
      'status': project.status.name,
      'dueAt': project.dueAt?.toIso8601String(),
      'startedAt': project.startedAt?.toIso8601String(),
      'endedAt': project.endedAt?.toIso8601String(),
      'createdAt': project.createdAt.toIso8601String(),
      'updatedAt': project.updatedAt.toIso8601String(),
      'sortIndex': project.sortIndex,
      'tags': project.tags,
      'templateLockCount': project.templateLockCount,
      'seedSlug': project.seedSlug,
      'allowInstantComplete': project.allowInstantComplete,
      'description': project.description,
      'logs': project.logs.map(_projectLogEntryToJson).toList(),
    };
  }

  /// 反序列化项目
  static Project _projectFromJson(Map<String, dynamic> json) {
    return Project(
      id: 0, // 导入时会重新分配Isar ID
      projectId: json['projectId'] as String,
      title: json['title'] as String,
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'] as String,
      ),
      dueAt: json['dueAt'] != null
          ? DateTime.parse(json['dueAt'] as String)
          : null,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      sortIndex: (json['sortIndex'] as num).toDouble(),
      tags: List<String>.from(json['tags'] as List<dynamic>),
      templateLockCount: json['templateLockCount'] as int,
      seedSlug: json['seedSlug'] as String?,
      allowInstantComplete: json['allowInstantComplete'] as bool? ?? false,
      description: json['description'] as String?,
      logs: (json['logs'] as List<dynamic>)
          .map((e) => _projectLogEntryFromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 序列化里程碑（排除 id 字段）
  Map<String, dynamic> _milestoneToJson(Milestone milestone) {
    return {
      'milestoneId': milestone.milestoneId,
      'projectId': milestone.projectId,
      'title': milestone.title,
      'status': milestone.status.name,
      'dueAt': milestone.dueAt?.toIso8601String(),
      'startedAt': milestone.startedAt?.toIso8601String(),
      'endedAt': milestone.endedAt?.toIso8601String(),
      'createdAt': milestone.createdAt.toIso8601String(),
      'updatedAt': milestone.updatedAt.toIso8601String(),
      'sortIndex': milestone.sortIndex,
      'tags': milestone.tags,
      'templateLockCount': milestone.templateLockCount,
      'seedSlug': milestone.seedSlug,
      'allowInstantComplete': milestone.allowInstantComplete,
      'description': milestone.description,
      'logs': milestone.logs.map(_milestoneLogEntryToJson).toList(),
    };
  }

  /// 反序列化里程碑
  static Milestone _milestoneFromJson(Map<String, dynamic> json) {
    return Milestone(
      id: 0, // 导入时会重新分配Isar ID
      milestoneId: json['milestoneId'] as String,
      projectId: json['projectId'] as String,
      title: json['title'] as String,
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'] as String,
      ),
      dueAt: json['dueAt'] != null
          ? DateTime.parse(json['dueAt'] as String)
          : null,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      sortIndex: (json['sortIndex'] as num).toDouble(),
      tags: List<String>.from(json['tags'] as List<dynamic>),
      templateLockCount: json['templateLockCount'] as int,
      seedSlug: json['seedSlug'] as String?,
      allowInstantComplete: json['allowInstantComplete'] as bool? ?? false,
      description: json['description'] as String?,
      logs: (json['logs'] as List<dynamic>)
          .map((e) => _milestoneLogEntryFromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 序列化任务（排除 id、projectIsarId、milestoneIsarId 字段）
  /// 
  /// 注意：parentTaskId 需要转换为父任务的 taskId（业务ID），而不是 Isar ID
  /// 但由于我们无法在这里访问 repository，所以需要在 ExportService 中处理
  Map<String, dynamic> _taskToJson(Task task) {
    return {
      'taskId': task.taskId,
      'title': task.title,
      'status': task.status.name,
      'dueAt': task.dueAt?.toIso8601String(),
      'startedAt': task.startedAt?.toIso8601String(),
      'endedAt': task.endedAt?.toIso8601String(),
      'archivedAt': task.archivedAt?.toIso8601String(),
      'createdAt': task.createdAt.toIso8601String(),
      'updatedAt': task.updatedAt.toIso8601String(),
      // parentTaskId 将在 ExportService 中转换为父任务的 taskId
      'parentTaskId': null, // 占位符，将在 ExportService 中设置
      'projectId': task.projectId,
      'milestoneId': task.milestoneId,
      'sortIndex': task.sortIndex,
      'tags': task.tags,
      'templateLockCount': task.templateLockCount,
      'seedSlug': task.seedSlug,
      'allowInstantComplete': task.allowInstantComplete,
      'description': task.description,
      'logs': task.logs.map(_taskLogEntryToJson).toList(),
    };
  }

  /// 反序列化任务
  static Task _taskFromJson(Map<String, dynamic> json) {
    return Task(
      id: 0, // 导入时会重新分配Isar ID
      taskId: json['taskId'] as String,
      title: json['title'] as String,
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'] as String,
      ),
      dueAt: json['dueAt'] != null
          ? DateTime.parse(json['dueAt'] as String)
          : null,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      archivedAt: json['archivedAt'] != null
          ? DateTime.parse(json['archivedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      parentId: null, // 导入时通过parentTaskId查找
      parentTaskId: null, // 导入时通过parentTaskId（taskId，String）查找并设置
      projectId: json['projectId'] as String?,
      milestoneId: json['milestoneId'] as String?,
      sortIndex: (json['sortIndex'] as num).toDouble(),
      tags: List<String>.from(json['tags'] as List<dynamic>),
      templateLockCount: json['templateLockCount'] as int,
      seedSlug: json['seedSlug'] as String?,
      allowInstantComplete: json['allowInstantComplete'] as bool? ?? false,
      description: json['description'] as String?,
      logs: (json['logs'] as List<dynamic>)
          .map((e) => _taskLogEntryFromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 序列化项目日志条目
  Map<String, dynamic> _projectLogEntryToJson(ProjectLogEntry entry) {
    return {
      'timestamp': entry.timestamp.toIso8601String(),
      'action': entry.action,
      'previous': entry.previous,
      'next': entry.next,
      'actor': entry.actor,
    };
  }

  /// 反序列化项目日志条目
  static ProjectLogEntry _projectLogEntryFromJson(Map<String, dynamic> json) {
    return ProjectLogEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      action: json['action'] as String,
      previous: json['previous'] as String?,
      next: json['next'] as String?,
      actor: json['actor'] as String?,
    );
  }

  /// 序列化里程碑日志条目
  Map<String, dynamic> _milestoneLogEntryToJson(MilestoneLogEntry entry) {
    return {
      'timestamp': entry.timestamp.toIso8601String(),
      'action': entry.action,
      'previous': entry.previous,
      'next': entry.next,
      'actor': entry.actor,
    };
  }

  /// 反序列化里程碑日志条目
  static MilestoneLogEntry _milestoneLogEntryFromJson(Map<String, dynamic> json) {
    return MilestoneLogEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      action: json['action'] as String,
      previous: json['previous'] as String?,
      next: json['next'] as String?,
      actor: json['actor'] as String?,
    );
  }

  /// 序列化任务日志条目
  Map<String, dynamic> _taskLogEntryToJson(TaskLogEntry entry) {
    return {
      'timestamp': entry.timestamp.toIso8601String(),
      'action': entry.action,
      'previous': entry.previous,
      'next': entry.next,
      'actor': entry.actor,
    };
  }

  /// 反序列化任务日志条目
  static TaskLogEntry _taskLogEntryFromJson(Map<String, dynamic> json) {
    return TaskLogEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      action: json['action'] as String,
      previous: json['previous'] as String?,
      next: json['next'] as String?,
      actor: json['actor'] as String?,
    );
  }
}

