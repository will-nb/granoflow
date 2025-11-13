import 'dart:convert' show jsonDecode, utf8;
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../data/models/export_data.dart';
import '../../data/models/milestone.dart';
import '../../data/models/node.dart';
import '../../data/models/project.dart';
import '../../data/models/task.dart';
import '../../data/repositories/milestone_repository.dart';
import '../../data/repositories/node_repository.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/task_repository.dart';
import 'encryption_key_service.dart';
import 'export_encryption_service.dart';

/// 导入结果统计信息
class ImportResult {
  const ImportResult({
    required this.projectsCreated,
    required this.projectsUpdated,
    required this.projectsSkipped,
    required this.milestonesCreated,
    required this.milestonesUpdated,
    required this.milestonesSkipped,
    required this.tasksCreated,
    required this.tasksUpdated,
    required this.tasksSkipped,
    required this.nodesCreated,
    required this.nodesUpdated,
    required this.nodesSkipped,
    required this.errors,
  });

  final int projectsCreated;
  final int projectsUpdated;
  final int projectsSkipped;
  final int milestonesCreated;
  final int milestonesUpdated;
  final int milestonesSkipped;
  final int tasksCreated;
  final int tasksUpdated;
  final int tasksSkipped;
  final int nodesCreated;
  final int nodesUpdated;
  final int nodesSkipped;
  final List<String> errors;

  int get totalProcessed =>
      projectsCreated +
      projectsUpdated +
      projectsSkipped +
      milestonesCreated +
      milestonesUpdated +
      milestonesSkipped +
      tasksCreated +
      tasksUpdated +
      tasksSkipped +
      nodesCreated +
      nodesUpdated +
      nodesSkipped;
}

/// 导入服务
/// 
/// 负责解压ZIP、解析JSON、处理冲突并导入数据
class ImportService {
  ImportService({
    required TaskRepository taskRepository,
    required ProjectRepository projectRepository,
    required MilestoneRepository milestoneRepository,
    required NodeRepository nodeRepository,
    required ExportEncryptionService encryptionService,
    required EncryptionKeyService encryptionKeyService,
  })  : _taskRepository = taskRepository,
        _projectRepository = projectRepository,
        _milestoneRepository = milestoneRepository,
        _nodeRepository = nodeRepository,
        _encryptionService = encryptionService,
        _encryptionKeyService = encryptionKeyService;

  final TaskRepository _taskRepository;
  final ProjectRepository _projectRepository;
  final MilestoneRepository _milestoneRepository;
  final NodeRepository _nodeRepository;
  final ExportEncryptionService _encryptionService;
  final EncryptionKeyService _encryptionKeyService;

  /// 从ZIP文件导入数据
  Future<ImportResult> importFromZip(File zipFile) async {
    final errors = <String>[];

    // 解压ZIP并解析JSON（不解密）
    final rawJson = await _extractAndParseZip(zipFile, errors);
    if (rawJson == null) {
      return ImportResult(
        projectsCreated: 0,
        projectsUpdated: 0,
        projectsSkipped: 0,
        milestonesCreated: 0,
        milestonesUpdated: 0,
        milestonesSkipped: 0,
        tasksCreated: 0,
        tasksUpdated: 0,
        tasksSkipped: 0,
        nodesCreated: 0,
        nodesUpdated: 0,
        nodesSkipped: 0,
        errors: errors,
      );
    }

    // 验证UUID格式（从原始JSON中提取id进行验证）
    if (!_validateUuidsFromJson(rawJson, errors)) {
      return ImportResult(
        projectsCreated: 0,
        projectsUpdated: 0,
        projectsSkipped: 0,
        milestonesCreated: 0,
        milestonesUpdated: 0,
        milestonesSkipped: 0,
        tasksCreated: 0,
        tasksUpdated: 0,
        tasksSkipped: 0,
        nodesCreated: 0,
        nodesUpdated: 0,
        nodesSkipped: 0,
        errors: errors,
      );
    }

    // 导入数据（延迟解密：只解密需要导入的实体）
    return await _importData(rawJson, errors);
  }

  /// 解压ZIP并解析JSON
  /// 
  /// 返回原始 JSON 数据（不解密，延迟解密）
  Future<Map<String, dynamic>?> _extractAndParseZip(
    File zipFile,
    List<String> errors,
  ) async {
    try {
      // 读取ZIP文件
      final zipBytes = await zipFile.readAsBytes();

      // 解压ZIP
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final dataFile = archive.findFile('data.json');
      if (dataFile == null) {
        errors.add('ZIP文件中未找到 data.json');
        return null;
      }

      // 解析JSON（不解密）
      final jsonString = utf8.decode(dataFile.content as List<int>);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      return jsonData;
    } catch (e) {
      errors.add('解析ZIP文件失败: $e');
      return null;
    }
  }

  /// 从原始 JSON 解析单个项目（延迟解密）
  Future<Project?> _parseProjectFromJson(
    Map<String, dynamic> projectMap,
    Uint8List encryptionKey,
    List<String> errors,
  ) async {
    try {
      // 解密 title 和 description
      final decryptedMap = Map<String, dynamic>.from(projectMap);
      decryptedMap['title'] = _decryptField(projectMap['title'], encryptionKey);
      if (projectMap['description'] != null) {
        decryptedMap['description'] = _decryptField(projectMap['description'], encryptionKey);
      }
      
      return ExportData.projectFromJson(decryptedMap);
    } catch (e) {
      errors.add('解析项目失败: $e');
      return null;
    }
  }

  /// 从原始 JSON 解析单个里程碑（延迟解密）
  Future<Milestone?> _parseMilestoneFromJson(
    Map<String, dynamic> milestoneMap,
    Uint8List encryptionKey,
    List<String> errors,
  ) async {
    try {
      // 解密 title 和 description
      final decryptedMap = Map<String, dynamic>.from(milestoneMap);
      decryptedMap['title'] = _decryptField(milestoneMap['title'], encryptionKey);
      if (milestoneMap['description'] != null) {
        decryptedMap['description'] = _decryptField(milestoneMap['description'], encryptionKey);
      }
      
      return ExportData.milestoneFromJson(decryptedMap);
    } catch (e) {
      errors.add('解析里程碑失败: $e');
      return null;
    }
  }

  /// 从原始 JSON 解析单个任务（延迟解密）
  Future<Task?> _parseTaskFromJson(
    Map<String, dynamic> taskMap,
    Uint8List encryptionKey,
    List<String> errors,
  ) async {
    try {
      // 解密 title 和 description
      final decryptedMap = Map<String, dynamic>.from(taskMap);
      decryptedMap['title'] = _decryptField(taskMap['title'], encryptionKey);
      if (taskMap['description'] != null) {
        decryptedMap['description'] = _decryptField(taskMap['description'], encryptionKey);
      }
      
      return ExportData.taskFromJson(decryptedMap);
    } catch (e) {
      errors.add('解析任务失败: $e');
      return null;
    }
  }

  /// 从原始 JSON 解析单个节点（延迟解密）
  Future<Node?> _parseNodeFromJson(
    Map<String, dynamic> nodeMap,
    Uint8List encryptionKey,
    List<String> errors,
  ) async {
    try {
      // 解密 title
      final decryptedMap = Map<String, dynamic>.from(nodeMap);
      decryptedMap['title'] = _decryptField(nodeMap['title'], encryptionKey);
      
      return ExportData.nodeFromJson(decryptedMap);
    } catch (e) {
      errors.add('解析节点失败: $e');
      return null;
    }
  }

  /// 解密单个字段
  /// 
  /// 字段必须是 Map（加密格式），解密后返回字符串
  String? _decryptField(dynamic field, Uint8List encryptionKey) {
    if (field == null) {
      return null;
    }

    // 字段必须是 Map（加密格式）
    if (field is! Map<String, dynamic>) {
      throw Exception('Field must be encrypted format (Map), got: ${field.runtimeType}');
    }

    try {
      final encryptedData = EncryptedData.fromJson(field);
      return _encryptionService.decrypt(encryptedData, encryptionKey);
    } catch (e) {
      throw Exception('Failed to decrypt field: $e');
    }
  }

  /// 验证所有业务ID为有效的UUID v4格式（从原始JSON中提取）
  bool _validateUuidsFromJson(Map<String, dynamic> jsonData, List<String> errors) {
    bool isValid = true;

    final projects = (jsonData['projects'] as List<dynamic>?) ?? [];
    for (final projectJson in projects) {
      final projectMap = projectJson as Map<String, dynamic>;
      final projectId = projectMap['projectId'] as String?;
      if (projectId == null || !_isValidUuid(projectId)) {
        errors.add('项目ID格式无效: $projectId');
        isValid = false;
      }
    }

    final milestones = (jsonData['milestones'] as List<dynamic>?) ?? [];
    for (final milestoneJson in milestones) {
      final milestoneMap = milestoneJson as Map<String, dynamic>;
      final milestoneId = milestoneMap['milestoneId'] as String?;
      final projectId = milestoneMap['projectId'] as String?;
      if (milestoneId == null || !_isValidUuid(milestoneId)) {
        errors.add('里程碑ID格式无效: $milestoneId');
        isValid = false;
      }
      if (projectId == null || !_isValidUuid(projectId)) {
        errors.add('里程碑的项目ID格式无效: $projectId');
        isValid = false;
      }
    }

    final tasks = (jsonData['tasks'] as List<dynamic>?) ?? [];
    for (final taskJson in tasks) {
      final taskMap = taskJson as Map<String, dynamic>;
      final taskId = taskMap['taskId'] as String?;
      final projectId = taskMap['projectId'] as String?;
      final milestoneId = taskMap['milestoneId'] as String?;
      if (taskId == null || !_isValidUuid(taskId)) {
        errors.add('任务ID格式无效: $taskId');
        isValid = false;
      }
      if (projectId != null && !_isValidUuid(projectId)) {
        errors.add('任务的项目ID格式无效: $projectId');
        isValid = false;
      }
      if (milestoneId != null && !_isValidUuid(milestoneId)) {
        errors.add('任务的里程碑ID格式无效: $milestoneId');
        isValid = false;
      }
    }

    final nodes = (jsonData['nodes'] as List<dynamic>?) ?? [];
    for (final nodeJson in nodes) {
      final nodeMap = nodeJson as Map<String, dynamic>;
      final nodeId = nodeMap['nodeId'] as String?;
      final taskId = nodeMap['taskId'] as String?;
      final parentId = nodeMap['parentId'] as String?;
      if (nodeId == null || !_isValidUuid(nodeId)) {
        errors.add('节点ID格式无效: $nodeId');
        isValid = false;
      }
      if (taskId == null || !_isValidUuid(taskId)) {
        errors.add('节点的任务ID格式无效: $taskId');
        isValid = false;
      }
      if (parentId != null && !_isValidUuid(parentId)) {
        errors.add('节点的父节点ID格式无效: $parentId');
        isValid = false;
      }
    }

    return isValid;
  }

  /// 验证UUID v4格式
  bool _isValidUuid(String id) {
    // UUID v4 格式：xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
    // 使用正则表达式验证
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(id);
  }

  /// 导入数据
  /// 
  /// 延迟解密：只解密需要导入的实体（id不存在 或 updatedAt > 数据库中的updatedAt）
  Future<ImportResult> _importData(
    Map<String, dynamic> rawJson,
    List<String> errors,
  ) async {
    // 检查 salt（必须存在）
    final salt = rawJson['salt'] as String?;
    if (salt == null) {
      errors.add('导入失败：导出数据缺少 salt 字段');
      throw Exception('Salt is missing in export data');
    }

    // 获取用户密钥并派生加密密钥
    final userKey = await _encryptionKeyService.loadKey();
    if (userKey == null) {
      errors.add('导入失败：未找到加密密钥，无法解密数据');
      throw Exception('Encryption key is missing');
    }
    final encryptionKey = _encryptionService.deriveKey(userKey, salt);
    // 层级功能已移除，不再需要提取或建立父子关系
    final tasksJson = rawJson['tasks'] as List<dynamic>;

    // 构建 logs 映射（从独立数组按外键分组）
    // 直接从 rawJson 读取，因为 JSON 中包含外键信息
    final projectLogsMap = <String, List<ProjectLogEntry>>{};
    final projectLogsJson = rawJson['projectLogs'] as List<dynamic>? ?? [];
    for (final logJson in projectLogsJson) {
      final logMap = logJson as Map<String, dynamic>;
      final projectId = logMap['projectId'] as String?;
      if (projectId != null) {
        final log = ExportData.projectLogEntryFromJson(logMap);
        projectLogsMap.putIfAbsent(projectId, () => []).add(log);
      }
    }

    final taskLogsMap = <String, List<TaskLogEntry>>{};
    final taskLogsJson = rawJson['taskLogs'] as List<dynamic>? ?? [];
    for (final logJson in taskLogsJson) {
      final logMap = logJson as Map<String, dynamic>;
      final taskId = logMap['taskId'] as String?;
      if (taskId != null) {
        final log = ExportData.taskLogEntryFromJson(logMap);
        taskLogsMap.putIfAbsent(taskId, () => []).add(log);
      }
    }

    final milestoneLogsMap = <String, List<MilestoneLogEntry>>{};
    final milestoneLogsJson = rawJson['milestoneLogs'] as List<dynamic>? ?? [];
    for (final logJson in milestoneLogsJson) {
      final logMap = logJson as Map<String, dynamic>;
      final milestoneId = logMap['milestoneId'] as String?;
      if (milestoneId != null) {
        final log = ExportData.milestoneLogEntryFromJson(logMap);
        milestoneLogsMap.putIfAbsent(milestoneId, () => []).add(log);
      }
    }

    int projectsCreated = 0;
    int projectsUpdated = 0;
    int projectsSkipped = 0;
    int milestonesCreated = 0;
    int milestonesUpdated = 0;
    int milestonesSkipped = 0;
    int tasksCreated = 0;
    int tasksUpdated = 0;
    int tasksSkipped = 0;

    // 记录在导入过程中已存在或新建的实体 ID
    final existingProjectIds = <String>{};
    final existingMilestoneIds = <String>{};

    // 第一轮：导入项目（延迟解密）
    final projectsJson = (rawJson['projects'] as List<dynamic>?) ?? [];
    for (final projectJson in projectsJson) {
      final projectMap = projectJson as Map<String, dynamic>;
      final projectId = projectMap['projectId'] as String;
      final updatedAtStr = projectMap['updatedAt'] as String;
      final updatedAt = DateTime.parse(updatedAtStr);
      
      try {
        // 先判断是否需要导入（不需要解密）
        final existing = await _projectRepository.findById(projectId);
        final needsImport = existing == null || updatedAt.isAfter(existing.updatedAt);
        
        if (!needsImport) {
          // 不需要导入，跳过（不解密）
          existingProjectIds.add(projectId);
          projectsSkipped++;
          continue;
        }
        
        // 需要导入，解密该实体
        final project = await _parseProjectFromJson(projectMap, encryptionKey, errors);
        if (project == null) {
          continue; // 解密失败，错误已记录
        }
        
        // 从独立数组获取该项目的 logs
        final projectLogs = projectLogsMap[projectId] ?? [];
        
        if (existing == null) {
          // 创建新项目
          final created = await _projectRepository.createProjectWithId(
            ProjectDraft(
              title: project.title,
              status: project.status,
              dueAt: project.dueAt,
              startedAt: project.startedAt,
              endedAt: project.endedAt,
              sortIndex: project.sortIndex,
              tags: project.tags,
              templateLockCount: project.templateLockCount,
              seedSlug: project.seedSlug,
              allowInstantComplete: project.allowInstantComplete,
              description: project.description,
              logs: projectLogs,
            ),
            project.id,
            project.createdAt,
            project.updatedAt,
          );
          existingProjectIds.add(created.id);
          projectsCreated++;
        } else {
          // 导入数据更新，更新本地数据
          await _projectRepository.update(
            project.id,
            ProjectUpdate(
              title: project.title,
              status: project.status,
              dueAt: project.dueAt,
              startedAt: project.startedAt,
              endedAt: project.endedAt,
              sortIndex: project.sortIndex,
              tags: project.tags,
              templateLockDelta: project.templateLockCount -
                  existing.templateLockCount,
              allowInstantComplete: project.allowInstantComplete,
              description: project.description,
              logs: projectLogs,
            ),
          );
          existingProjectIds.add(project.id);
          projectsUpdated++;
        }
      } catch (e) {
        errors.add('导入项目失败 $projectId: $e');
      }
    }

    // 第二轮：导入里程碑（延迟解密）
    final milestonesJson = (rawJson['milestones'] as List<dynamic>?) ?? [];
    for (final milestoneJson in milestonesJson) {
      final milestoneMap = milestoneJson as Map<String, dynamic>;
      final milestoneId = milestoneMap['milestoneId'] as String;
      final projectId = milestoneMap['projectId'] as String;
      final updatedAtStr = milestoneMap['updatedAt'] as String;
      final updatedAt = DateTime.parse(updatedAtStr);
      
      try {
        if (!existingProjectIds.contains(projectId)) {
          errors.add(
            '里程碑 $milestoneId 引用的项目 $projectId 不存在',
          );
          continue;
        }

        // 先判断是否需要导入（不需要解密）
        final existing = await _milestoneRepository.findById(milestoneId);
        final needsImport = existing == null || updatedAt.isAfter(existing.updatedAt);
        
        if (!needsImport) {
          // 不需要导入，跳过（不解密）
          existingMilestoneIds.add(milestoneId);
          milestonesSkipped++;
          continue;
        }
        
        // 需要导入，解密该实体
        final milestone = await _parseMilestoneFromJson(milestoneMap, encryptionKey, errors);
        if (milestone == null) {
          continue; // 解密失败，错误已记录
        }
        
        // 从独立数组获取该里程碑的 logs
        final milestoneLogs = milestoneLogsMap[milestoneId] ?? [];
        
        if (existing == null) {
          // 创建新里程碑
          await _milestoneRepository.createMilestoneWithId(
            MilestoneDraft(
              projectId: milestone.projectId,
              title: milestone.title,
              status: milestone.status,
              dueAt: milestone.dueAt,
              startedAt: milestone.startedAt,
              endedAt: milestone.endedAt,
              sortIndex: milestone.sortIndex,
              tags: milestone.tags,
              templateLockCount: milestone.templateLockCount,
              seedSlug: milestone.seedSlug,
              allowInstantComplete: milestone.allowInstantComplete,
              description: milestone.description,
              logs: milestoneLogs,
            ),
            milestone.id,
            milestone.createdAt,
            milestone.updatedAt,
          );
          existingMilestoneIds.add(milestone.id);
          milestonesCreated++;
        } else {
          // 导入数据更新，更新本地数据
          await _milestoneRepository.update(
            milestone.id,
            MilestoneUpdate(
              title: milestone.title,
              status: milestone.status,
              dueAt: milestone.dueAt,
              startedAt: milestone.startedAt,
              endedAt: milestone.endedAt,
              sortIndex: milestone.sortIndex,
              tags: milestone.tags,
              templateLockDelta:
                  milestone.templateLockCount - existing.templateLockCount,
              allowInstantComplete: milestone.allowInstantComplete,
              description: milestone.description,
              logs: milestoneLogs,
            ),
          );
          existingMilestoneIds.add(milestone.id);
          milestonesUpdated++;
        }
      } catch (e) {
        errors.add('导入里程碑失败 $milestoneId: $e');
      }
    }

    // 第三轮：导入任务（延迟解密，不设置父子关系）
    for (final taskJson in tasksJson) {
      final taskMap = taskJson as Map<String, dynamic>;
      final taskId = taskMap['taskId'] as String;
      final updatedAtStr = taskMap['updatedAt'] as String;
      final updatedAt = DateTime.parse(updatedAtStr);
      final projectId = taskMap['projectId'] as String?;
      final milestoneId = taskMap['milestoneId'] as String?;
      
      try {
        final hasProject =
            projectId == null || existingProjectIds.contains(projectId);
        if (!hasProject) {
          errors.add(
            '任务 $taskId 引用的项目 $projectId 不存在',
          );
        }

        final hasMilestone = milestoneId == null ||
            existingMilestoneIds.contains(milestoneId);
        if (!hasMilestone) {
          errors.add(
            '任务 $taskId 引用的里程碑 $milestoneId 不存在',
          );
        }

        final sanitizedProjectId = hasProject ? projectId : null;
        final sanitizedMilestoneId = hasMilestone ? milestoneId : null;

        // 先判断是否需要导入（不需要解密）
        final existing = await _taskRepository.findById(taskId);
        final needsImport = existing == null || updatedAt.isAfter(existing.updatedAt);
        
        if (!needsImport) {
          // 不需要导入，跳过（不解密）
          tasksSkipped++;
          continue;
        }
        
        // 需要导入，解密该实体
        final task = await _parseTaskFromJson(taskMap, encryptionKey, errors);
        if (task == null) {
          continue; // 解密失败，错误已记录
        }
        
        // 从独立数组获取该任务的 logs
        final taskLogs = taskLogsMap[taskId] ?? [];
        
        if (existing == null) {
          // 创建新任务（不设置 parentId，在第四轮处理）
          await _taskRepository.createTaskWithId(
            TaskDraft(
              title: task.title,
              status: task.status,
              dueAt: task.dueAt,
              // 层级功能已移除，不再处理 parentId
              projectId: sanitizedProjectId,
              milestoneId: sanitizedMilestoneId,
              tags: task.tags,
              sortIndex: task.sortIndex,
              seedSlug: task.seedSlug,
              allowInstantComplete: task.allowInstantComplete,
              description: task.description,
              logs: taskLogs,
            ),
            task.id,
            task.createdAt,
            task.updatedAt,
          );
          tasksCreated++;
        } else {
          // 导入数据更新，更新本地数据
          await _taskRepository.updateTask(
            existing.id,
            TaskUpdate(
              title: task.title,
              status: task.status,
              dueAt: task.dueAt,
              startedAt: task.startedAt,
              endedAt: task.endedAt,
              archivedAt: task.archivedAt,
              projectId: sanitizedProjectId,
              milestoneId: sanitizedMilestoneId,
              sortIndex: task.sortIndex,
              tags: task.tags,
              templateLockDelta:
                  task.templateLockCount - existing.templateLockCount,
              allowInstantComplete: task.allowInstantComplete,
              description: task.description,
              logs: taskLogs,
              clearProject: sanitizedProjectId == null &&
                      existing.projectId != null
                  ? true
                  : null,
              clearMilestone: sanitizedMilestoneId == null &&
                      existing.milestoneId != null
                  ? true
                  : null,
            ),
          );
          tasksUpdated++;
        }
      } catch (e) {
        errors.add('导入任务失败 $taskId: $e');
      }
    }

    // 层级功能已移除，不再需要建立任务父子关系

    return ImportResult(
      projectsCreated: projectsCreated,
      projectsUpdated: projectsUpdated,
      projectsSkipped: projectsSkipped,
      milestonesCreated: milestonesCreated,
      milestonesUpdated: milestonesUpdated,
      milestonesSkipped: milestonesSkipped,
      tasksCreated: tasksCreated,
      tasksUpdated: tasksUpdated,
      tasksSkipped: tasksSkipped,
      errors: errors,
    );
  }

}

