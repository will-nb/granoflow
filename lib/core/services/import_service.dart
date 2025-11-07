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
      if (!_isValidUuid(project.projectId)) {
        errors.add('项目ID格式无效: ${project.projectId}');
        isValid = false;
      }
    }

    for (final milestone in exportData.milestones) {
      if (!_isValidUuid(milestone.milestoneId)) {
        errors.add('里程碑ID格式无效: ${milestone.milestoneId}');
        isValid = false;
      }
      if (!_isValidUuid(milestone.projectId)) {
        errors.add('里程碑的项目ID格式无效: ${milestone.projectId}');
        isValid = false;
      }
    }

    for (final task in exportData.tasks) {
      if (!_isValidUuid(task.taskId)) {
        errors.add('任务ID格式无效: ${task.taskId}');
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

    // 建立业务ID到Isar ID的映射
    final projectIdToIsarId = <String, int>{};
    final milestoneIdToIsarId = <String, int>{};
    final taskIdToIsarId = <String, int>{};

    // 第一轮：导入项目
    for (final project in exportData.projects) {
      try {
        final existing = await _projectRepository.findByProjectId(
          project.projectId,
        );
        if (existing == null) {
          // 创建新项目
          final created = await _projectRepository.createProjectWithId(
            ProjectDraft(
              projectId: project.projectId,
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
            project.projectId,
            project.createdAt,
            project.updatedAt,
          );
          projectIdToIsarId[project.projectId] = created.id;
          projectsCreated++;
        } else {
          // 比较时间戳
          if (project.updatedAt.isAfter(existing.updatedAt)) {
            // 导入数据更新，更新本地数据
            await _projectRepository.update(
              existing.id,
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
            projectIdToIsarId[project.projectId] = existing.id;
            projectsUpdated++;
          } else {
            // 本地数据更新或相同，跳过
            projectIdToIsarId[project.projectId] = existing.id;
            projectsSkipped++;
          }
        }
      } catch (e) {
        errors.add('导入项目失败 ${project.projectId}: $e');
      }
    }

    // 第二轮：导入里程碑
    for (final milestone in exportData.milestones) {
      try {
        // 查找关联项目的Isar ID
        final projectIsarId = projectIdToIsarId[milestone.projectId];
        if (projectIsarId == null) {
          errors.add(
            '里程碑 ${milestone.milestoneId} 引用的项目 ${milestone.projectId} 不存在',
          );
          continue;
        }

        final existing = await _milestoneRepository.findByMilestoneId(
          milestone.milestoneId,
        );
        if (existing == null) {
          // 创建新里程碑
          final created = await _milestoneRepository.createMilestoneWithId(
            MilestoneDraft(
              milestoneId: milestone.milestoneId,
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
            milestone.milestoneId,
            milestone.createdAt,
            milestone.updatedAt,
          );
          milestoneIdToIsarId[milestone.milestoneId] = created.id;

          // 设置 projectIsarId
          // 注意：createMilestoneWithId 不会设置 projectIsarId，需要手动更新
          await _setMilestoneProjectIsarId(created.id, projectIsarId);
          milestonesCreated++;
        } else {
          // 比较时间戳
          if (milestone.updatedAt.isAfter(existing.updatedAt)) {
            // 导入数据更新，更新本地数据
            await _milestoneRepository.update(
              existing.id,
              MilestoneUpdate(
                title: milestone.title,
                status: milestone.status,
                dueAt: milestone.dueAt,
                startedAt: milestone.startedAt,
                endedAt: milestone.endedAt,
                sortIndex: milestone.sortIndex,
                tags: milestone.tags,
                templateLockDelta: milestone.templateLockCount -
                    existing.templateLockCount,
                allowInstantComplete: milestone.allowInstantComplete,
                description: milestone.description,
                logs: milestone.logs,
              ),
            );
            milestoneIdToIsarId[milestone.milestoneId] = existing.id;
            // 重新设置 projectIsarId（因为 update 方法不会自动设置）
            await _setMilestoneProjectIsarId(existing.id, projectIsarId);
            milestonesUpdated++;
          } else {
            // 本地数据更新或相同，跳过
            milestoneIdToIsarId[milestone.milestoneId] = existing.id;
            milestonesSkipped++;
          }
        }
      } catch (e) {
        errors.add('导入里程碑失败 ${milestone.milestoneId}: $e');
      }
    }

    // 第三轮：导入任务（不设置父子关系）
    for (final task in exportData.tasks) {
      try {
        // 查找关联项目和里程碑的Isar ID
        int? projectIsarId;
        if (task.projectId != null) {
          projectIsarId = projectIdToIsarId[task.projectId];
          if (projectIsarId == null) {
            errors.add(
              '任务 ${task.taskId} 引用的项目 ${task.projectId} 不存在',
            );
            // 继续处理，但不设置项目关联
          }
        }

        int? milestoneIsarId;
        if (task.milestoneId != null) {
          milestoneIsarId = milestoneIdToIsarId[task.milestoneId];
          if (milestoneIsarId == null) {
            errors.add(
              '任务 ${task.taskId} 引用的里程碑 ${task.milestoneId} 不存在',
            );
            // 继续处理，但不设置里程碑关联
          }
        }

        final existing = await _taskRepository.findByTaskId(task.taskId);
        if (existing == null) {
          // 创建新任务（不设置 parentTaskId，在第四轮处理）
          final created = await _taskRepository.createTaskWithId(
            TaskDraft(
              title: task.title,
              status: task.status,
              dueAt: task.dueAt,
              parentId: null, // 第四轮处理
              parentTaskId: null, // 第四轮处理
              projectId: task.projectId,
              milestoneId: task.milestoneId,
              tags: task.tags,
              sortIndex: task.sortIndex,
              seedSlug: task.seedSlug,
              allowInstantComplete: task.allowInstantComplete,
              description: task.description,
              logs: task.logs,
            ),
            task.taskId,
            task.createdAt,
            task.updatedAt,
          );
          taskIdToIsarId[task.taskId] = created.id;
          tasksCreated++;

          // 设置 projectIsarId 和 milestoneIsarId
          // 注意：createTaskWithId 不会设置 projectIsarId 和 milestoneIsarId
          // 需要手动设置
          await _setTaskProjectAndMilestoneIsarId(
            created.id,
            projectIsarId,
            milestoneIsarId,
          );
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
                projectId: task.projectId,
                milestoneId: task.milestoneId,
                sortIndex: task.sortIndex,
                tags: task.tags,
                templateLockDelta: task.templateLockCount -
                    existing.templateLockCount,
                allowInstantComplete: task.allowInstantComplete,
                description: task.description,
                logs: task.logs,
              ),
            );
            taskIdToIsarId[task.taskId] = existing.id;
            // 重新设置 projectIsarId 和 milestoneIsarId（因为 update 方法不会自动设置）
            await _setTaskProjectAndMilestoneIsarId(
              existing.id,
              projectIsarId,
              milestoneIsarId,
            );
            tasksUpdated++;
          } else {
            // 本地数据更新或相同，跳过
            taskIdToIsarId[task.taskId] = existing.id;
            tasksSkipped++;
          }
        }
      } catch (e) {
        errors.add('导入任务失败 ${task.taskId}: $e');
      }
    }

    // 第四轮：建立任务父子关系
    // 使用从原始 JSON 中提取的 parentTaskId（taskId，String）
    for (final task in exportData.tasks) {
      final parentTaskId = taskIdToParentTaskId[task.taskId];
      if (parentTaskId == null) {
        continue;
      }

      try {
        // 查找父任务的Isar ID（通过 taskId）
        final parentTask = await _taskRepository.findByTaskId(parentTaskId);
        if (parentTask == null) {
          errors.add(
            '任务 ${task.taskId} 的父任务 $parentTaskId 不存在',
          );
          continue;
        }

        final childTask = await _taskRepository.findByTaskId(task.taskId);
        if (childTask == null) {
          continue; // 已经在第三轮处理过错误
        }

        // 更新父任务关系
        await _taskRepository.updateTask(
          childTask.id,
          TaskUpdate(
            parentId: parentTask.id,
            parentTaskId: parentTask.id,
          ),
        );
      } catch (e) {
        errors.add('设置任务父子关系失败 ${task.taskId}: $e');
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

  /// 设置里程碑的 projectIsarId
  Future<void> _setMilestoneProjectIsarId(
    int milestoneIsarId,
    int? projectIsarId,
  ) async {
    if (projectIsarId == null) {
      return;
    }
    await _milestoneRepository.setMilestoneProjectIsarId(
      milestoneIsarId,
      projectIsarId,
    );
  }

  /// 设置任务的 projectIsarId 和 milestoneIsarId
  Future<void> _setTaskProjectAndMilestoneIsarId(
    int taskIsarId,
    int? projectIsarId,
    int? milestoneIsarId,
  ) async {
    await _taskRepository.setTaskProjectAndMilestoneIsarId(
      taskIsarId,
      projectIsarId,
      milestoneIsarId,
    );
  }
}

