import 'dart:convert' show jsonDecode, utf8;
import 'dart:io';

import 'package:archive/archive.dart';

import '../../data/models/export_data.dart';
import '../../data/models/milestone.dart';
import '../../data/models/project.dart';
import '../../data/models/task.dart';
import '../../data/repositories/milestone_repository.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/task_repository.dart';

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
      tasksSkipped;
}

/// 导入服务
/// 
/// 负责解压ZIP、解析JSON、处理冲突并导入数据
class ImportService {
  ImportService({
    required TaskRepository taskRepository,
    required ProjectRepository projectRepository,
    required MilestoneRepository milestoneRepository,
  })  : _taskRepository = taskRepository,
        _projectRepository = projectRepository,
        _milestoneRepository = milestoneRepository;

  final TaskRepository _taskRepository;
  final ProjectRepository _projectRepository;
  final MilestoneRepository _milestoneRepository;

  /// 从ZIP文件导入数据
  Future<ImportResult> importFromZip(File zipFile) async {
    final errors = <String>[];

    // 解压ZIP并解析JSON
    final result = await _extractAndParseZip(zipFile, errors);
    if (result == null) {
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
        errors: errors,
      );
    }

    final exportData = result.exportData;
    final rawJson = result.rawJson;

    // 验证UUID格式
    if (!_validateUuids(exportData, errors)) {
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
        errors: errors,
      );
    }

    // 导入数据
    return await _importData(exportData, rawJson, errors);
  }

  /// 解压ZIP并解析JSON
  /// 
  /// 返回 ExportData 和原始 JSON 数据（用于读取 parentTaskId）
  Future<({ExportData exportData, Map<String, dynamic> rawJson})?> _extractAndParseZip(
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

      // 解析JSON
      final jsonString = utf8.decode(dataFile.content as List<int>);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final exportData = ExportData.fromJson(jsonData);
      return (exportData: exportData, rawJson: jsonData);
    } catch (e) {
      errors.add('解析ZIP文件失败: $e');
      return null;
    }
  }

  /// 验证所有业务ID为有效的UUID v4格式
  bool _validateUuids(ExportData exportData, List<String> errors) {
    bool isValid = true;

    for (final project in exportData.projects) {
      if (!_isValidUuid(project.id)) {
        errors.add('项目ID格式无效: ${project.id}');
        isValid = false;
      }
    }

    for (final milestone in exportData.milestones) {
      if (!_isValidUuid(milestone.id)) {
        errors.add('里程碑ID格式无效: ${milestone.id}');
        isValid = false;
      }
      if (!_isValidUuid(milestone.projectId)) {
        errors.add('里程碑的项目ID格式无效: ${milestone.projectId}');
        isValid = false;
      }
    }

    for (final task in exportData.tasks) {
      if (!_isValidUuid(task.id)) {
        errors.add('任务ID格式无效: ${task.id}');
        isValid = false;
      }
      if (task.projectId != null && !_isValidUuid(task.projectId!)) {
        errors.add('任务的项目ID格式无效: ${task.projectId}');
        isValid = false;
      }
      if (task.milestoneId != null && !_isValidUuid(task.milestoneId!)) {
        errors.add('任务的里程碑ID格式无效: ${task.milestoneId}');
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
  Future<ImportResult> _importData(
    ExportData exportData,
    Map<String, dynamic> rawJson,
    List<String> errors,
  ) async {
    // 从原始 JSON 中提取任务的 parentTaskId（taskId，String）
    final tasksJson = rawJson['tasks'] as List<dynamic>;
    final taskIdToParentTaskId = <String, String?>{};
    for (final taskJson in tasksJson) {
      final taskMap = taskJson as Map<String, dynamic>;
      final taskId = taskMap['taskId'] as String;
      final parentTaskId = taskMap['parentTaskId'] as String?;
      taskIdToParentTaskId[taskId] = parentTaskId;
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

    // 第一轮：导入项目
      for (final project in exportData.projects) {
      try {
          final existing = await _projectRepository.findById(project.id);
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
              logs: project.logs,
            ),
              project.id,
            project.createdAt,
            project.updatedAt,
          );
            existingProjectIds.add(created.id);
          projectsCreated++;
        } else {
          // 比较时间戳
          if (project.updatedAt.isAfter(existing.updatedAt)) {
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
                logs: project.logs,
              ),
            );
              existingProjectIds.add(project.id);
            projectsUpdated++;
          } else {
            // 本地数据更新或相同，跳过
              existingProjectIds.add(project.id);
            projectsSkipped++;
          }
        }
      } catch (e) {
          errors.add('导入项目失败 ${project.id}: $e');
      }
    }

    // 第二轮：导入里程碑
    for (final milestone in exportData.milestones) {
      try {
        if (!existingProjectIds.contains(milestone.projectId)) {
          errors.add(
            '里程碑 ${milestone.id} 引用的项目 ${milestone.projectId} 不存在',
          );
          continue;
        }

        final existing = await _milestoneRepository.findById(milestone.id);
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
              logs: milestone.logs,
            ),
            milestone.id,
            milestone.createdAt,
            milestone.updatedAt,
          );
          existingMilestoneIds.add(milestone.id);
          milestonesCreated++;
        } else {
          // 比较时间戳
          if (milestone.updatedAt.isAfter(existing.updatedAt)) {
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
                logs: milestone.logs,
              ),
            );
            existingMilestoneIds.add(milestone.id);
            milestonesUpdated++;
          } else {
            // 本地数据更新或相同，跳过
            existingMilestoneIds.add(milestone.id);
            milestonesSkipped++;
          }
        }
      } catch (e) {
        errors.add('导入里程碑失败 ${milestone.id}: $e');
      }
    }

    // 第三轮：导入任务（不设置父子关系）
    for (final task in exportData.tasks) {
      try {
        final hasProject =
            task.projectId == null || existingProjectIds.contains(task.projectId!);
        if (!hasProject && task.projectId != null) {
          errors.add(
            '任务 ${task.id} 引用的项目 ${task.projectId} 不存在',
          );
        }

        final hasMilestone = task.milestoneId == null ||
            existingMilestoneIds.contains(task.milestoneId!);
        if (!hasMilestone && task.milestoneId != null) {
          errors.add(
            '任务 ${task.id} 引用的里程碑 ${task.milestoneId} 不存在',
          );
        }

        final sanitizedProjectId = hasProject ? task.projectId : null;
        final sanitizedMilestoneId = hasMilestone ? task.milestoneId : null;

        final existing = await _taskRepository.findById(task.id);
        if (existing == null) {
          // 创建新任务（不设置 parentId，在第四轮处理）
          await _taskRepository.createTaskWithId(
            TaskDraft(
              title: task.title,
              status: task.status,
              dueAt: task.dueAt,
              parentId: null, // 第四轮处理
              projectId: sanitizedProjectId,
              milestoneId: sanitizedMilestoneId,
              tags: task.tags,
              sortIndex: task.sortIndex,
              seedSlug: task.seedSlug,
              allowInstantComplete: task.allowInstantComplete,
              description: task.description,
              logs: task.logs,
            ),
            task.id,
            task.createdAt,
            task.updatedAt,
          );
          tasksCreated++;
        } else {
          // 比较时间戳
          if (task.updatedAt.isAfter(existing.updatedAt)) {
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
                logs: task.logs,
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
          } else {
            // 本地数据更新或相同，跳过
            tasksSkipped++;
          }
        }
      } catch (e) {
        errors.add('导入任务失败 ${task.id}: $e');
      }
    }

    // 第四轮：建立任务父子关系
    // 使用从原始 JSON 中提取的 parentTaskId（taskId，String）
    for (final task in exportData.tasks) {
      final parentTaskId = taskIdToParentTaskId[task.id];
      if (parentTaskId == null) {
        continue;
      }

      try {
        final parentTask = await _taskRepository.findById(parentTaskId);
        if (parentTask == null) {
          errors.add(
            '任务 ${task.id} 的父任务 $parentTaskId 不存在',
          );
          continue;
        }

        final childTask = await _taskRepository.findById(task.id);
        if (childTask == null) {
          continue; // 已经在第三轮处理过错误
        }

        await _taskRepository.updateTask(
          childTask.id,
          TaskUpdate(parentId: parentTask.id),
        );
      } catch (e) {
        errors.add('设置任务父子关系失败 ${task.id}: $e');
      }
    }

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

