import 'dart:convert' show jsonEncode, utf8;
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/export_data.dart';
import '../../data/models/milestone.dart';
import '../../data/models/project.dart';
import '../../data/models/task.dart';
import '../../data/repositories/milestone_repository.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/task_repository.dart';

/// 导出服务
/// 
/// 负责收集数据、序列化为JSON并打包为ZIP文件
class ExportService {
  ExportService({
    required TaskRepository taskRepository,
    required ProjectRepository projectRepository,
    required MilestoneRepository milestoneRepository,
    DateTime Function()? clock,
  })  : _taskRepository = taskRepository,
        _projectRepository = projectRepository,
        _milestoneRepository = milestoneRepository,
        _clock = clock ?? DateTime.now;

  final TaskRepository _taskRepository;
  final ProjectRepository _projectRepository;
  final MilestoneRepository _milestoneRepository;
  final DateTime Function() _clock;

  /// 收集所有需要导出的数据
  /// 
  /// 过滤规则：
  /// - 项目：排除 status == pseudoDeleted
  /// - 里程碑：排除 status == pseudoDeleted
  /// - 任务：包含 status == trashed，排除 status == pseudoDeleted
  Future<ExportData> collectExportData() async {
    // 收集项目（排除 pseudoDeleted）
    final allProjects = await _projectRepository.listAll();
    final projects = allProjects
        .where((project) => project.status != TaskStatus.pseudoDeleted)
        .toList();

    // 收集里程碑（排除 pseudoDeleted）
    final allMilestones = await _milestoneRepository.listAll();
    final milestones = allMilestones
        .where((milestone) => milestone.status != TaskStatus.pseudoDeleted)
        .toList();

    // 收集任务（包含 trashed，排除 pseudoDeleted）
    final allTasks = await _taskRepository.listAll();
    final tasks = allTasks
        .where((task) => task.status != TaskStatus.pseudoDeleted)
        .toList();

    return ExportData(
      version: '1.0',
      exportedAt: _clock(),
      projects: projects,
      milestones: milestones,
      tasks: tasks,
    );
  }

  /// 导出数据为ZIP文件
  /// 
  /// 返回生成的ZIP文件路径
  /// 文件名格式：yymmddhhmm.flow.grano
  Future<File> exportToZip() async {
    // 收集数据
    final exportData = await collectExportData();

    // 序列化为JSON（手动处理 parentTaskId 转换）
    final jsonData = _exportDataToJson(exportData);
    final jsonString = _jsonEncode(jsonData);
    final jsonBytes = utf8.encode(jsonString);

    // 创建ZIP文件
    final archive = Archive();
    archive.addFile(
      ArchiveFile('data.json', jsonBytes.length, jsonBytes),
    );

    // 压缩为ZIP
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);
    if (zipBytes == null) {
      throw Exception('Failed to create ZIP file');
    }

    // 生成文件名：yymmddhhmm.flow.grano
    final now = _clock();
    final fileName = _generateFileName(now);

    // 获取临时目录
    final tempDir = await getTemporaryDirectory();
    final zipFile = File('${tempDir.path}/$fileName');

    // 写入文件
    await zipFile.writeAsBytes(zipBytes);

    return zipFile;
  }

  /// 生成文件名：yymmddhhmm.flow.grano
  String _generateFileName(DateTime now) {
    final year = now.year.toString().substring(2); // 取后两位年份
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$year$month$day$hour$minute.flow.grano';
  }

  /// 将 ExportData 转换为 JSON（手动处理 parentTaskId 转换）
  Map<String, dynamic> _exportDataToJson(ExportData exportData) {
    return {
      'version': exportData.version,
      'exportedAt': exportData.exportedAt.toIso8601String(),
      'projects': exportData.projects.map(_projectToJson).toList(),
      'milestones': exportData.milestones.map(_milestoneToJson).toList(),
      'tasks': exportData.tasks.map(_taskToJson).toList(),
    };
  }

  /// 序列化项目
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
      'logs': project.logs.map(_projectLogEntryToJson).toList(),
    };
  }

  /// 序列化里程碑
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
      'logs': milestone.logs.map(_milestoneLogEntryToJson).toList(),
    };
  }

    /// 序列化任务
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
      'parentTaskId': task.parentId,
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

  /// JSON编码（使用dart:convert的jsonEncode）
  String _jsonEncode(Map<String, dynamic> json) {
    return jsonEncode(json);
  }
}

