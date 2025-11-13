import 'dart:convert' show jsonEncode, utf8;
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/export_data.dart';
import '../../data/models/milestone.dart';
import '../../data/models/project.dart';
import '../../data/models/task.dart';
import '../../data/repositories/milestone_repository.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/task_repository.dart';
import 'encryption_key_service.dart';
import 'export_encryption_service.dart';

/// 导出服务
/// 
/// 负责收集数据、序列化为JSON并打包为ZIP文件
class ExportService {
  ExportService({
    required TaskRepository taskRepository,
    required ProjectRepository projectRepository,
    required MilestoneRepository milestoneRepository,
    required ExportEncryptionService encryptionService,
    required EncryptionKeyService encryptionKeyService,
    DateTime Function()? clock,
  })  : _taskRepository = taskRepository,
        _projectRepository = projectRepository,
        _milestoneRepository = milestoneRepository,
        _encryptionService = encryptionService,
        _encryptionKeyService = encryptionKeyService,
        _clock = clock ?? DateTime.now;

  final TaskRepository _taskRepository;
  final ProjectRepository _projectRepository;
  final MilestoneRepository _milestoneRepository;
  final ExportEncryptionService _encryptionService;
  final EncryptionKeyService _encryptionKeyService;
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

    // 提取所有 logs 为独立数组（记录式格式）
    final projectLogs = <ProjectLogEntry>[];
    final taskLogs = <TaskLogEntry>[];
    final milestoneLogs = <MilestoneLogEntry>[];

    for (final project in projects) {
      for (final log in project.logs) {
        projectLogs.add(log);
      }
    }
    for (final task in tasks) {
      for (final log in task.logs) {
        taskLogs.add(log);
      }
    }
    for (final milestone in milestones) {
      for (final log in milestone.logs) {
        milestoneLogs.add(log);
      }
    }

    // 生成 salt
    final salt = _encryptionService.generateSalt();

    return ExportData(
      version: '1.0',
      salt: salt,
      exportedAt: _clock(),
      projects: projects,
      milestones: milestones,
      tasks: tasks,
      projectLogs: projectLogs,
      taskLogs: taskLogs,
      milestoneLogs: milestoneLogs,
    );
  }

  /// 导出数据为ZIP文件
  /// 
  /// 返回生成的ZIP文件路径
  /// 文件名格式：yymmddhhmm.flow.grano
  Future<File> exportToZip() async {
    // 收集数据
    final exportData = await collectExportData();

    // 序列化为JSON（手动处理 parentTaskId 转换，加密 title 和 description）
    final jsonData = await _exportDataToJson(exportData);
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

  /// 将 ExportData 转换为 JSON
  /// 
  /// logs 作为独立数组导出，每个 log 记录包含外键（projectId/taskId/milestoneId）
  /// title 和 description 字段会被加密
  Future<Map<String, dynamic>> _exportDataToJson(ExportData exportData) async {
    // 获取用户密钥
    final userKey = await _encryptionKeyService.loadKey();
    if (userKey == null) {
      throw Exception('Encryption key is missing');
    }

    // 派生加密密钥
    final encryptionKey = _encryptionService.deriveKey(userKey, exportData.salt);
    // 构建 projectId -> logs 映射
    final projectLogsMap = <String, List<ProjectLogEntry>>{};
    for (final project in exportData.projects) {
      if (project.logs.isNotEmpty) {
        projectLogsMap[project.id] = project.logs;
      }
    }

    // 构建 taskId -> logs 映射
    final taskLogsMap = <String, List<TaskLogEntry>>{};
    for (final task in exportData.tasks) {
      if (task.logs.isNotEmpty) {
        taskLogsMap[task.id] = task.logs;
      }
    }

    // 构建 milestoneId -> logs 映射
    final milestoneLogsMap = <String, List<MilestoneLogEntry>>{};
    for (final milestone in exportData.milestones) {
      if (milestone.logs.isNotEmpty) {
        milestoneLogsMap[milestone.id] = milestone.logs;
      }
    }

    // 序列化 logs，包含外键
    final projectLogsJson = <Map<String, dynamic>>[];
    for (final entry in projectLogsMap.entries) {
      for (final log in entry.value) {
        projectLogsJson.add(_projectLogEntryToJson(log, projectId: entry.key));
      }
    }

    final taskLogsJson = <Map<String, dynamic>>[];
    for (final entry in taskLogsMap.entries) {
      for (final log in entry.value) {
        taskLogsJson.add(_taskLogEntryToJson(log, taskId: entry.key));
      }
    }

    final milestoneLogsJson = <Map<String, dynamic>>[];
    for (final entry in milestoneLogsMap.entries) {
      for (final log in entry.value) {
        milestoneLogsJson.add(_milestoneLogEntryToJson(log, milestoneId: entry.key));
      }
    }

    return {
      'version': exportData.version,
      'salt': exportData.salt,
      'exportedAt': exportData.exportedAt.toIso8601String(),
      'projects': await Future.wait(
        exportData.projects.map((p) => _projectToJson(p, encryptionKey)),
      ),
      'milestones': await Future.wait(
        exportData.milestones.map((m) => _milestoneToJson(m, encryptionKey)),
      ),
      'tasks': await Future.wait(
        exportData.tasks.map((t) => _taskToJson(t, encryptionKey)),
      ),
      'projectLogs': projectLogsJson,
      'taskLogs': taskLogsJson,
      'milestoneLogs': milestoneLogsJson,
    };
  }

  /// 序列化项目（不包含 logs，logs 单独导出）
  /// title 和 description 会被加密
  Future<Map<String, dynamic>> _projectToJson(Project project, Uint8List encryptionKey) async {
    // 加密 title 和 description
    final encryptedTitle = _encryptionService.encrypt(
      project.title,
      encryptionKey,
    );
    final encryptedDescription = project.description != null
        ? _encryptionService.encrypt(
            project.description!,
            encryptionKey,
          )
        : null;

    return {
      'projectId': project.id,
      'title': encryptedTitle.toJson(),
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
      if (encryptedDescription != null) 'description': encryptedDescription.toJson(),
    };
  }

  /// 序列化里程碑（不包含 logs，logs 单独导出）
  /// title 和 description 会被加密
  Future<Map<String, dynamic>> _milestoneToJson(Milestone milestone, Uint8List encryptionKey) async {
    // 加密 title 和 description
    final encryptedTitle = _encryptionService.encrypt(
      milestone.title,
      encryptionKey,
    );
    final encryptedDescription = milestone.description != null
        ? _encryptionService.encrypt(
            milestone.description!,
            encryptionKey,
          )
        : null;

    return {
      'milestoneId': milestone.id,
      'projectId': milestone.projectId,
      'title': encryptedTitle.toJson(),
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
      if (encryptedDescription != null) 'description': encryptedDescription.toJson(),
    };
  }

  /// 序列化任务（不包含 logs，logs 单独导出）
  /// title 和 description 会被加密
  Future<Map<String, dynamic>> _taskToJson(Task task, Uint8List encryptionKey) async {
    // 加密 title 和 description
    final encryptedTitle = _encryptionService.encrypt(
      task.title,
      encryptionKey,
    );
    final encryptedDescription = task.description != null
        ? _encryptionService.encrypt(
            task.description!,
            encryptionKey,
          )
        : null;

    return {
      'taskId': task.id,
      'title': encryptedTitle.toJson(),
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
      if (encryptedDescription != null) 'description': encryptedDescription.toJson(),
    };
  }

  /// 序列化项目日志条目（包含 projectId 外键）
  Map<String, dynamic> _projectLogEntryToJson(ProjectLogEntry entry, {required String projectId}) {
    return {
      'projectId': projectId,
      'timestamp': entry.timestamp.toIso8601String(),
      'action': entry.action,
      'previous': entry.previous,
      'next': entry.next,
      'actor': entry.actor,
    };
  }

  /// 序列化里程碑日志条目（包含 milestoneId 外键）
  Map<String, dynamic> _milestoneLogEntryToJson(MilestoneLogEntry entry, {required String milestoneId}) {
    return {
      'milestoneId': milestoneId,
      'timestamp': entry.timestamp.toIso8601String(),
      'action': entry.action,
      'previous': entry.previous,
      'next': entry.next,
      'actor': entry.actor,
    };
  }

  /// 序列化任务日志条目（包含 taskId 外键）
  Map<String, dynamic> _taskLogEntryToJson(TaskLogEntry entry, {required String taskId}) {
    return {
      'taskId': taskId,
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

