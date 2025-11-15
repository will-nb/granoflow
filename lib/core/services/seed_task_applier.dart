import 'package:flutter/foundation.dart';

import '../../data/models/milestone.dart';
import '../../data/models/project.dart';
import '../../data/models/task.dart';
import '../../data/repositories/milestone_repository.dart';
import '../../data/repositories/seed_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../utils/id_generator.dart';
import 'project_models.dart';
import 'project_service.dart';
import 'seed_import_utils.dart';
import 'seed_node_applier.dart';

/// 种子任务应用器
/// 负责将种子数据中的任务（项目、里程碑、普通任务）导入到数据库
class SeedTaskApplier {
  SeedTaskApplier({
    required ProjectService projectService,
    required TaskRepository taskRepository,
    required MilestoneRepository milestoneRepository,
    required SeedNodeApplier nodeApplier,
  }) : _projectService = projectService,
       _tasks = taskRepository,
       _milestones = milestoneRepository,
       _nodeApplier = nodeApplier;

  final ProjectService _projectService;
  final TaskRepository _tasks;
  final MilestoneRepository _milestones;
  final SeedNodeApplier _nodeApplier;

  /// 应用任务列表，返回 slug -> id 映射
  Future<Map<String, String>> applyTasks(List<SeedTask> tasks) async {
    // slug -> id 映射，支持项目、里程碑和任务的混合映射
    final Map<String, String> slugToId = <String, String>{};
    // slug -> projectId 映射（字符串 ID）
    final Map<String, String> slugToProjectId = <String, String>{};
    // slug -> milestoneId 映射（字符串 ID）
    final Map<String, String> slugToMilestoneId = <String, String>{};

    // 第一遍：处理所有项目（project 类型）
    final projectTasks = tasks.where((t) => t.taskKind?.toLowerCase() == 'project').toList();

    // 先检查已存在的项目（通过 seedSlug）
    final allProjects = await _projectService.listAll();
    final existingProjectsBySlug = <String, Project>{};
    for (final project in allProjects) {
      if (project.seedSlug != null) {
        existingProjectsBySlug[project.seedSlug!] = project;
      }
    }

    debugPrint('SeedTaskApplier: Processing ${projectTasks.length} project seeds');
    int createdProjects = 0;
    int skippedProjects = 0;
    for (final seed in projectTasks) {
      // 检查是否已存在相同 seedSlug 的项目
      if (existingProjectsBySlug.containsKey(seed.slug)) {
        debugPrint(
          'SeedTaskApplier: Project with seedSlug "${seed.slug}" already exists, skipping',
        );
        final existingProject = existingProjectsBySlug[seed.slug]!;
        slugToProjectId[seed.slug] = existingProject.id;
        slugToId[seed.slug] = existingProject.id;
        skippedProjects++;
        continue;
      }

      // 创建新项目
      final dueAt = SeedImportUtils.parseDueAt(seed.dueAt) ?? DateTime.now();
      debugPrint(
        'SeedTaskApplier: Creating project with seedSlug "${seed.slug}", title: "${seed.title}", dueAt: $dueAt',
      );

      final project = await _projectService.createProject(
        ProjectBlueprint(
          title: seed.title,
          dueDate: dueAt,
          description: null,
          tags: seed.tags,
          milestones: const <ProjectMilestoneBlueprint>[],
        ),
      );
      debugPrint('SeedTaskApplier: Project created - id: ${project.id}, title: ${project.title}');

      // 更新项目的 seedSlug（createProject 不会设置 seedSlug，需要手动更新）
      debugPrint('SeedTaskApplier: Updating project ${project.id} with seedSlug: ${seed.slug}');
      await _projectService.updateProject(project.id, ProjectUpdate(seedSlug: seed.slug));
      debugPrint('SeedTaskApplier: Project seedSlug updated successfully');

      slugToProjectId[seed.slug] = project.id;
      slugToId[seed.slug] = project.id;
      createdProjects++;
    }
    debugPrint(
      'SeedTaskApplier: Projects processing complete - Created: $createdProjects, Skipped: $skippedProjects, Total: ${projectTasks.length}',
    );

    // 第二遍：处理所有里程碑（milestone 类型）
    final milestoneTasks = tasks.where((t) => t.taskKind?.toLowerCase() == 'milestone').toList();
    debugPrint('SeedTaskApplier: Processing ${milestoneTasks.length} milestone seeds');
    int createdMilestones = 0;
    int skippedMilestones = 0;
    for (final seed in milestoneTasks) {
      // 里程碑必须有父项目
      if (seed.parentSlug == null || !slugToProjectId.containsKey(seed.parentSlug)) {
        debugPrint(
          'SeedTaskApplier: Milestone ${seed.slug} has no valid parent project (parentSlug: ${seed.parentSlug}), skipping',
        );
        skippedMilestones++;
        continue;
      }

      final projectId = slugToProjectId[seed.parentSlug]!;
      final dueAt = SeedImportUtils.parseDueAt(seed.dueAt);
      debugPrint(
        'SeedTaskApplier: Creating milestone with seedSlug "${seed.slug}", title: "${seed.title}", projectId: $projectId',
      );

      // 生成 milestoneId（使用 UUID v4）
      final milestoneId = IdGenerator.generateId();

      await _milestones.createMilestoneWithId(
        MilestoneDraft(
          projectId: projectId,
          title: seed.title,
          status: seed.status,
          dueAt: dueAt,
          startedAt: null,
          endedAt: null,
          sortIndex: seed.sortIndex,
          tags: seed.tags,
          templateLockCount: 0,
          seedSlug: seed.slug,
          allowInstantComplete: seed.allowInstantComplete,
          description: seed.description,
          logs: const <MilestoneLogEntry>[],
        ),
        milestoneId,
        DateTime.now(),
        DateTime.now(),
      );

      slugToMilestoneId[seed.slug] = milestoneId;
      slugToId[seed.slug] = milestoneId;
      createdMilestones++;
      debugPrint(
        'SeedTaskApplier: Milestone created successfully - id: $milestoneId, slug: ${seed.slug}',
      );
    }
    debugPrint(
      'SeedTaskApplier: Milestones processing complete - Created: $createdMilestones, Skipped: $skippedMilestones, Total: ${milestoneTasks.length}',
    );

    // 第三遍：处理所有普通任务（regular 类型或未指定类型）
    final regularTasks = tasks
        .where(
          (t) =>
              t.taskKind == null ||
              t.taskKind?.toLowerCase() == 'regular' ||
              t.taskKind?.toLowerCase() != 'project' && t.taskKind?.toLowerCase() != 'milestone',
        )
        .toList();

    // 先检查已存在的任务（通过 seedSlug）
    final allTasks = await _tasks.listAll();
    final existingTasksBySlug = <String, Task>{};
    for (final task in allTasks) {
      if (task.seedSlug != null) {
        existingTasksBySlug[task.seedSlug!] = task;
      }
    }

    debugPrint('SeedTaskApplier: Processing ${regularTasks.length} regular task seeds');
    int createdTasks = 0;
    int skippedTasks = 0;
    for (final seed in regularTasks) {
      // 检查是否已存在相同 seedSlug 的任务
      if (existingTasksBySlug.containsKey(seed.slug)) {
        debugPrint('SeedTaskApplier: Task with seedSlug "${seed.slug}" already exists, skipping');
        final existingTask = existingTasksBySlug[seed.slug]!;
        slugToId[seed.slug] = existingTask.id;
        skippedTasks++;
        continue;
      }

      // 创建新任务
      final dueAt = SeedImportUtils.parseDueAt(seed.dueAt);
      debugPrint(
        'SeedTaskApplier: Creating task with seedSlug "${seed.slug}", title: "${seed.title}", projectId: ${seed.parentSlug != null && slugToProjectId.containsKey(seed.parentSlug) ? slugToProjectId[seed.parentSlug] : "null"}, milestoneId: ${seed.parentSlug != null && slugToMilestoneId.containsKey(seed.parentSlug) ? slugToMilestoneId[seed.parentSlug] : "null"}',
      );

      // 确定任务的 projectId 和 milestoneId
      String? projectId;
      String? milestoneId;

      // 如果 parentSlug 指向里程碑，则设置 milestoneId
      if (seed.parentSlug != null && slugToMilestoneId.containsKey(seed.parentSlug)) {
        milestoneId = slugToMilestoneId[seed.parentSlug];
        // 里程碑必须属于某个项目，通过里程碑找到项目
        final milestoneSlug = seed.parentSlug!;
        final parentMilestoneMatches = milestoneTasks.where((t) => t.slug == milestoneSlug);
        if (parentMilestoneMatches.isNotEmpty) {
          final parentMilestoneTask = parentMilestoneMatches.first;
          if (parentMilestoneTask.parentSlug != null) {
            projectId = slugToProjectId[parentMilestoneTask.parentSlug];
          }
        }
      } else if (seed.parentSlug != null && slugToProjectId.containsKey(seed.parentSlug)) {
        // 如果 parentSlug 指向项目，则设置 projectId
        projectId = slugToProjectId[seed.parentSlug];
      }

      final draft = TaskDraft(
        title: seed.title,
        status: seed.status,
        dueAt: dueAt,
        projectId: projectId,
        milestoneId: milestoneId,
        tags: seed.tags,
        allowInstantComplete: seed.allowInstantComplete,
        seedSlug: seed.slug,
        sortIndex: seed.sortIndex,
        description: seed.description,
      );
      final task = await _tasks.createTask(draft);
      slugToId[seed.slug] = task.id;
      createdTasks++;
      debugPrint('SeedTaskApplier: Task created successfully - id: ${task.id}, slug: ${seed.slug}');

      // 导入节点（如果有）
      if (seed.nodes.isNotEmpty) {
        await _nodeApplier.applyNodesForTask(task.id, seed.nodes, seed.slug);
      }
    }
    debugPrint(
      'SeedTaskApplier: Regular tasks processing complete - Created: $createdTasks, Skipped: $skippedTasks, Total: ${regularTasks.length}',
    );

    return slugToId;
  }
}
