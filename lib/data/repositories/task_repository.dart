import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../../core/services/tag_service.dart';
import '../../core/utils/id_generator.dart';
import '../../core/utils/task_section_utils.dart';
import '../isar/task_entity.dart';
import '../models/task.dart';

// Part 文件：包含各个功能模块的 mixin
part 'task_repository_helpers.dart';
part 'task_repository_streams.dart';
part 'task_repository_queries.dart';
part 'task_repository_paged_queries.dart';
part 'task_repository_mutations_core.dart';
part 'task_repository_mutations_status.dart';
part 'task_repository_mutations_move.dart';
part 'task_repository_mutations_batch.dart';
part 'task_repository_section_queries.dart';
part 'task_repository_task_hierarchy.dart';

abstract class TaskRepository {
  Stream<List<Task>> watchSection(TaskSection section);

  Stream<TaskTreeNode> watchTaskTree(int rootTaskId);

  Stream<List<Task>> watchInbox();

  @Deprecated('使用 ProjectRepository 和 ProjectService 替代')
  Stream<List<Task>> watchProjects();

  Stream<List<Task>> watchQuickTasks();

  @Deprecated('使用 MilestoneRepository 和 MilestoneService 替代')
  Stream<List<Task>> watchMilestones(int projectId);

  Stream<List<Task>> watchTasksByProjectId(String projectId);

  Stream<List<Task>> watchTasksByMilestoneId(String milestoneId);

  Future<List<Task>> listTasksByMilestoneId(String milestoneId);

  Stream<List<Task>> watchInboxFiltered({
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  });

  Future<Task> createTask(TaskDraft draft);

  /// 使用指定的 taskId 创建任务（用于导入）
  /// 
  /// [draft] 任务草稿
  /// [taskId] 要使用的业务ID
  /// [createdAt] 创建时间（从导入数据中获取）
  /// [updatedAt] 更新时间（从导入数据中获取）
  Future<Task> createTaskWithId(
    TaskDraft draft,
    String taskId,
    DateTime createdAt,
    DateTime updatedAt,
  );

  Future<void> updateTask(int taskId, TaskUpdate payload);

  /// 设置任务的 projectIsarId 和 milestoneIsarId（用于导入）
  /// 
  /// [taskId] 任务的 Isar ID
  /// [projectIsarId] 项目的 Isar ID（可为 null）
  /// [milestoneIsarId] 里程碑的 Isar ID（可为 null）
  Future<void> setTaskProjectAndMilestoneIsarId(
    int taskId,
    int? projectIsarId,
    int? milestoneIsarId,
  );

  Future<void> moveTask({
    required int taskId,
    required int? targetParentId,
    required TaskSection targetSection,
    required double sortIndex,
    DateTime? dueAt,
  });

  Future<void> markStatus({required int taskId, required TaskStatus status});

  Future<void> archiveTask(int taskId);

  Future<void> softDelete(int taskId);

  Future<int> purgeObsolete(DateTime olderThan);

  /// 清空回收站：批量永久删除所有回收站任务
  /// 返回删除的任务数量
  Future<int> clearAllTrashedTasks();

  Future<void> adjustTemplateLock({required int taskId, required int delta});

  Future<Task?> findById(int id);

  /// 通过业务ID（taskId）查询任务
  Future<Task?> findByTaskId(String taskId);

  /// 监听单个任务的变化
  Stream<Task?> watchTaskById(int id);

  Future<Task?> findBySlug(String slug);

  Future<List<Task>> listRoots();

  Future<List<Task>> listChildren(int parentId);

  /// 列出父任务的所有子任务（包括 trashed 状态）
  /// 用于在父任务展开时显示已删除的子任务
  Future<List<Task>> listChildrenIncludingTrashed(int parentId);

  Future<void> upsertTasks(List<Task> tasks);

  Future<List<Task>> listAll();

  Future<List<Task>> searchByTitle(
    String query, {
    TaskStatus? status,
    int limit,
  });

  /// 批量更新：按 id -> TaskUpdate 的映射执行更新
  Future<void> batchUpdate(Map<int, TaskUpdate> updates);

  /// 列出某个区域内用于排序的任务（与 UI 一致，已排序的叶任务）
  Future<List<Task>> listSectionTasks(TaskSection section);

  /// 分页查询已完成任务（按完成时间降序）
  Future<List<Task>> listCompletedTasks({
    required int limit,
    required int offset,
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  });

  /// 分页查询已归档任务（按归档时间降序）
  Future<List<Task>> listArchivedTasks({
    required int limit,
    required int offset,
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  });

  /// 获取已完成任务总数
  Future<int> countCompletedTasks();

  /// 获取已归档任务总数
  Future<int> countArchivedTasks();

  /// 分页查询已删除任务（按删除时间降序，使用 updatedAt 作为删除时间）
  Future<List<Task>> listTrashedTasks({
    required int limit,
    required int offset,
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  });

  /// 获取已删除任务总数
  Future<int> countTrashedTasks();
}

/// Isar 实现的 TaskRepository
/// 
/// 使用 mixin 组合各个功能模块，保持代码组织清晰
/// 
/// Mixin 顺序很重要，必须按照依赖关系排序：
/// 1. TaskRepositoryHelpers - 基础辅助方法（不依赖其他 mixin）
/// 2. TaskRepositorySectionQueries - 区域查询（依赖 Helpers）
/// 3. TaskRepositoryQueries - 基础查询方法（依赖 Helpers, SectionQueries）
/// 4. TaskRepositoryPagedQueries - 分页查询方法（依赖 Helpers）
/// 5. TaskRepositoryTaskHierarchy - 任务层级（依赖 Helpers）
/// 6. TaskRepositoryMutationsCore - 变更方法核心（依赖 Helpers, SectionQueries, TaskHierarchy）
/// 7. TaskRepositoryMutationsStatus - 状态相关操作（依赖 Core）
/// 8. TaskRepositoryMutationsMove - 移动操作（依赖 Status）
/// 9. TaskRepositoryMutationsBatch - 批量操作（依赖 Core）
/// 10. TaskRepositoryStreams - Stream 方法（依赖 Helpers, SectionQueries, TaskHierarchy）
class IsarTaskRepository
    with TaskRepositoryHelpers,
         TaskRepositorySectionQueries,
         TaskRepositoryQueries,
         TaskRepositoryPagedQueries,
         TaskRepositoryTaskHierarchy,
         TaskRepositoryMutationsCore,
         TaskRepositoryMutationsStatus,
         TaskRepositoryMutationsMove,
         TaskRepositoryMutationsBatch,
         TaskRepositoryStreams
    implements TaskRepository {
  IsarTaskRepository(this._isar, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final Isar _isar;
  final DateTime Function() _clock;
}
