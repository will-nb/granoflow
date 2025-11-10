import '../models/task.dart';

abstract class TaskRepository {
  Stream<List<Task>> watchSection(TaskSection section);

  Stream<TaskTreeNode> watchTaskTree(String rootTaskId);

  Stream<List<Task>> watchInbox();

  @Deprecated('使用 ProjectRepository 和 ProjectService 替代')
  Stream<List<Task>> watchProjects();

  Stream<List<Task>> watchQuickTasks();

  @Deprecated('使用 MilestoneRepository 和 MilestoneService 替代')
  Stream<List<Task>> watchMilestones(String projectId);

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

  Future<void> updateTask(String taskId, TaskUpdate payload);

  Future<void> moveTask({
    required String taskId,
    required String? targetParentId,
    required TaskSection targetSection,
    required double sortIndex,
    DateTime? dueAt,
  });

  Future<void> markStatus({required String taskId, required TaskStatus status});

  Future<void> archiveTask(String taskId);

  Future<void> softDelete(String taskId);

  Future<int> purgeObsolete(DateTime olderThan);

  /// 清空回收站：批量永久删除所有回收站任务
  /// 返回删除的任务数量
  Future<int> clearAllTrashedTasks();

  Future<void> adjustTemplateLock({required String taskId, required int delta});

  Future<Task?> findById(String id);

  /// 通过业务ID查询任务
  Future<Task?> findByTaskId(String taskId);

  /// 监听单个任务的变化
  Stream<Task?> watchTaskById(String id);

  Future<Task?> findBySlug(String slug);

  Future<List<Task>> listRoots();

  Future<List<Task>> listChildren(String parentId);

  /// 列出父任务的所有子任务（包括 trashed 状态）
  /// 用于在父任务展开时显示已删除的子任务
  Future<List<Task>> listChildrenIncludingTrashed(String parentId);

  Future<void> upsertTasks(List<Task> tasks);

  Future<List<Task>> listAll();

  Future<List<Task>> searchByTitle(
    String query, {
    TaskStatus? status,
    int limit,
  });

  /// 批量更新：按 id -> TaskUpdate 的映射执行更新
  Future<void> batchUpdate(Map<String, TaskUpdate> updates);

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
