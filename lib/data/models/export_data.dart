import 'package:flutter/foundation.dart';

import 'milestone.dart';
import 'node.dart';
import 'project.dart';
import 'task.dart';

/// 导出数据模型
/// 
/// 用于导出和导入项目、里程碑和任务数据
/// 所有业务ID（projectId、milestoneId、taskId）使用UUID v4格式
/// 
/// 格式说明：
/// - logs 作为独立数组（记录式格式，符合关系型数据库结构）
@immutable
class ExportData {
  const ExportData({
    required this.version,
    required this.salt,
    required this.exportedAt,
    required this.projects,
    required this.milestones,
    required this.tasks,
    this.projectLogs = const [],
    this.taskLogs = const [],
    this.milestoneLogs = const [],
    this.nodes = const [],
  });

  /// 导出格式版本
  final String version;

  /// 加密 salt（128-bit，16个字符，从62个字符集中选择）
  /// 用于与用户密钥一起派生加密密钥
  final String salt;

  /// 导出时间（ISO 8601格式）
  final DateTime exportedAt;

  /// 项目列表
  final List<Project> projects;

  /// 里程碑列表
  final List<Milestone> milestones;

  /// 任务列表
  final List<Task> tasks;

  /// 项目日志列表（独立数组，记录式格式）
  final List<ProjectLogEntry> projectLogs;

  /// 任务日志列表（独立数组，记录式格式）
  final List<TaskLogEntry> taskLogs;

  /// 里程碑日志列表（独立数组，记录式格式）
  final List<MilestoneLogEntry> milestoneLogs;

  /// 节点列表
  final List<Node> nodes;

  /// 序列化为JSON
  /// 
  /// logs 作为独立数组导出（记录式格式）
  /// 注意：此方法通过匹配实体的 logs 来获取外键，实际导出应使用 ExportService._exportDataToJson
  Map<String, dynamic> toJson() {
    // 构建外键映射：通过匹配实体的 logs 来获取外键
    // 由于 projectLogs/taskLogs/milestoneLogs 是从实体的 logs 中提取的，我们通过遍历实体来建立映射
    final projectLogsJson = <Map<String, dynamic>>[];
    for (final project in projects) {
      for (final log in project.logs) {
        // 检查 log 是否在独立的 projectLogs 数组中
        if (projectLogs.contains(log)) {
          projectLogsJson.add(_projectLogEntryToJson(log, projectId: project.id));
        }
      }
    }

    final taskLogsJson = <Map<String, dynamic>>[];
    for (final task in tasks) {
      for (final log in task.logs) {
        if (taskLogs.contains(log)) {
          taskLogsJson.add(_taskLogEntryToJson(log, taskId: task.id));
        }
      }
    }

    final milestoneLogsJson = <Map<String, dynamic>>[];
    for (final milestone in milestones) {
      for (final log in milestone.logs) {
        if (milestoneLogs.contains(log)) {
          milestoneLogsJson.add(_milestoneLogEntryToJson(log, milestoneId: milestone.id));
        }
      }
    }

    return {
      'version': version,
      'salt': salt,
      'exportedAt': exportedAt.toIso8601String(),
      'projects': projects.map((p) => _projectToJson(p)).toList(),
      'milestones': milestones.map((m) => _milestoneToJson(m)).toList(),
      'tasks': tasks.map((t) => _taskToJson(t)).toList(),
      'projectLogs': projectLogsJson,
      'taskLogs': taskLogsJson,
      'milestoneLogs': milestoneLogsJson,
    };
  }

  /// 从JSON反序列化
  /// 
  /// logs 从独立数组读取（记录式格式）
  factory ExportData.fromJson(Map<String, dynamic> json) {
    final projects = (json['projects'] as List<dynamic>)
        .map((e) => ExportData.projectFromJson(e as Map<String, dynamic>))
        .toList();
    final milestones = (json['milestones'] as List<dynamic>)
        .map((e) => ExportData.milestoneFromJson(e as Map<String, dynamic>))
        .toList();
    final tasks = (json['tasks'] as List<dynamic>)
        .map((e) => ExportData.taskFromJson(e as Map<String, dynamic>))
        .toList();

      final projectLogs = (json['projectLogs'] as List<dynamic>?)
              ?.map((e) => projectLogEntryFromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final taskLogs = (json['taskLogs'] as List<dynamic>?)
              ?.map((e) => taskLogEntryFromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final milestoneLogs = (json['milestoneLogs'] as List<dynamic>?)
              ?.map((e) => milestoneLogEntryFromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final nodes = (json['nodes'] as List<dynamic>?)
              ?.map((e) => nodeFromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

    return ExportData(
      version: json['version'] as String,
      salt: json['salt'] as String,
      exportedAt: DateTime.parse(json['exportedAt'] as String),
      projects: projects,
      milestones: milestones,
      tasks: tasks,
      projectLogs: projectLogs,
      taskLogs: taskLogs,
      milestoneLogs: milestoneLogs,
      nodes: nodes,
    );
  }

  /// 序列化项目（不包含 logs，logs 单独导出）
  Map<String, dynamic> _projectToJson(Project project) {
    return {
      'projectId': project.id,
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
    };
  }

  /// 反序列化项目
  static Project projectFromJson(Map<String, dynamic> json) {
    return Project(
      id: json['projectId'] as String,
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
      logs: (json['logs'] as List<dynamic>?)
              ?.map((e) => projectLogEntryFromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// 序列化里程碑（不包含 logs，logs 单独导出）
  Map<String, dynamic> _milestoneToJson(Milestone milestone) {
    return {
      'milestoneId': milestone.id,
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
    };
  }

  /// 反序列化里程碑
  static Milestone milestoneFromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['milestoneId'] as String,
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
      logs: (json['logs'] as List<dynamic>?)
              ?.map((e) => milestoneLogEntryFromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// 序列化任务（不包含 logs，logs 单独导出）
  Map<String, dynamic> _taskToJson(Task task) {
    return {
      'taskId': task.id,
      'title': task.title,
      'status': task.status.name,
      'dueAt': task.dueAt?.toIso8601String(),
      'startedAt': task.startedAt?.toIso8601String(),
      'endedAt': task.endedAt?.toIso8601String(),
      'archivedAt': task.archivedAt?.toIso8601String(),
      'createdAt': task.createdAt.toIso8601String(),
      'updatedAt': task.updatedAt.toIso8601String(),
      // 层级功能已移除，不再导出 parentTaskId
      'projectId': task.projectId,
      'milestoneId': task.milestoneId,
      'sortIndex': task.sortIndex,
      'tags': task.tags,
      'templateLockCount': task.templateLockCount,
      'seedSlug': task.seedSlug,
      'allowInstantComplete': task.allowInstantComplete,
      'description': task.description,
    };
  }

  /// 反序列化任务
  static Task taskFromJson(Map<String, dynamic> json) {
    return Task(
      id: json['taskId'] as String,
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
      // 层级功能已移除，不再导入 parentTaskId（parentId 字段已从 Task 模型中移除）
      projectId: json['projectId'] as String?,
      milestoneId: json['milestoneId'] as String?,
      sortIndex: (json['sortIndex'] as num).toDouble(),
      tags: List<String>.from(json['tags'] as List<dynamic>),
      templateLockCount: json['templateLockCount'] as int,
      seedSlug: json['seedSlug'] as String?,
      allowInstantComplete: json['allowInstantComplete'] as bool? ?? false,
      description: json['description'] as String?,
      logs: (json['logs'] as List<dynamic>?)
              ?.map((e) => taskLogEntryFromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// 序列化项目日志条目（包含 projectId 外键）
  Map<String, dynamic> _projectLogEntryToJson(ProjectLogEntry entry, {String? projectId}) {
    final result = <String, dynamic>{
      'timestamp': entry.timestamp.toIso8601String(),
      'action': entry.action,
      'previous': entry.previous,
      'next': entry.next,
      'actor': entry.actor,
    };
    if (projectId != null) {
      result['projectId'] = projectId;
    }
    return result;
  }

  /// 反序列化项目日志条目
  static ProjectLogEntry projectLogEntryFromJson(Map<String, dynamic> json) {
    return ProjectLogEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      action: json['action'] as String,
      previous: json['previous'] as String?,
      next: json['next'] as String?,
      actor: json['actor'] as String?,
    );
  }

  /// 序列化里程碑日志条目（包含 milestoneId 外键）
  Map<String, dynamic> _milestoneLogEntryToJson(MilestoneLogEntry entry, {String? milestoneId}) {
    final result = <String, dynamic>{
      'timestamp': entry.timestamp.toIso8601String(),
      'action': entry.action,
      'previous': entry.previous,
      'next': entry.next,
      'actor': entry.actor,
    };
    if (milestoneId != null) {
      result['milestoneId'] = milestoneId;
    }
    return result;
  }

  /// 反序列化里程碑日志条目
  static MilestoneLogEntry milestoneLogEntryFromJson(Map<String, dynamic> json) {
    return MilestoneLogEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      action: json['action'] as String,
      previous: json['previous'] as String?,
      next: json['next'] as String?,
      actor: json['actor'] as String?,
    );
  }

  /// 序列化任务日志条目（包含 taskId 外键）
  Map<String, dynamic> _taskLogEntryToJson(TaskLogEntry entry, {String? taskId}) {
    final result = <String, dynamic>{
      'timestamp': entry.timestamp.toIso8601String(),
      'action': entry.action,
      'previous': entry.previous,
      'next': entry.next,
      'actor': entry.actor,
    };
    if (taskId != null) {
      result['taskId'] = taskId;
    }
    return result;
  }

  /// 反序列化任务日志条目
  static TaskLogEntry taskLogEntryFromJson(Map<String, dynamic> json) {
    return TaskLogEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      action: json['action'] as String,
      previous: json['previous'] as String?,
      next: json['next'] as String?,
      actor: json['actor'] as String?,
    );
  }

  /// 反序列化节点
  static Node nodeFromJson(Map<String, dynamic> json) {
    return Node(
      id: json['nodeId'] as String,
      taskId: json['taskId'] as String,
      parentId: json['parentId'] as String?,
      title: json['title'] as String,
      status: NodeStatus.values.firstWhere(
        (e) => e.name == json['status'] as String,
      ),
      sortIndex: (json['sortIndex'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

