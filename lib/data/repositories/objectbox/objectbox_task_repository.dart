import '../../database/database_adapter.dart';
import '../../models/task.dart';
import '../task_repository.dart';

class ObjectBoxTaskRepository implements TaskRepository {
  const ObjectBoxTaskRepository(this._adapter);

  final DatabaseAdapter _adapter;

  @override
  Future<void> upsertTasks(List<Task> tasks) {
    throw UnimplementedError('ObjectBoxTaskRepository.upsertTasks');
  }

  @override
  Future<void> adjustTemplateLock({required String taskId, required int delta}) {
    throw UnimplementedError('ObjectBoxTaskRepository.adjustTemplateLock');
  }

  @override
  Future<void> archiveTask(String taskId) {
    throw UnimplementedError('ObjectBoxTaskRepository.archiveTask');
  }

  @override
  Future<void> batchUpdate(Map<String, TaskUpdate> updates) {
    throw UnimplementedError('ObjectBoxTaskRepository.batchUpdate');
  }

  @override
  Future<int> clearAllTrashedTasks() {
    throw UnimplementedError('ObjectBoxTaskRepository.clearAllTrashedTasks');
  }

  @override
  Future<int> countArchivedTasks() {
    throw UnimplementedError('ObjectBoxTaskRepository.countArchivedTasks');
  }

  @override
  Future<int> countCompletedTasks() {
    throw UnimplementedError('ObjectBoxTaskRepository.countCompletedTasks');
  }

  @override
  Future<int> countTrashedTasks() {
    throw UnimplementedError('ObjectBoxTaskRepository.countTrashedTasks');
  }

  @override
  Future<Task> createTask(TaskDraft draft) {
    throw UnimplementedError('ObjectBoxTaskRepository.createTask');
  }

  @override
  Future<Task> createTaskWithId(
    TaskDraft draft,
    String taskId,
    DateTime createdAt,
    DateTime updatedAt,
  ) {
    throw UnimplementedError('ObjectBoxTaskRepository.createTaskWithId');
  }

  @override
  Future<void> markStatus({
    required String taskId,
    required TaskStatus status,
  }) {
    throw UnimplementedError('ObjectBoxTaskRepository.markStatus');
  }

  @override
  Future<void> moveTask({
    required String taskId,
    required String? targetParentId,
    required TaskSection targetSection,
    required double sortIndex,
    DateTime? dueAt,
  }) {
    throw UnimplementedError('ObjectBoxTaskRepository.moveTask');
  }

  @override
  Future<int> purgeObsolete(DateTime olderThan) {
    throw UnimplementedError('ObjectBoxTaskRepository.purgeObsolete');
  }

  @override
  Future<void> softDelete(String taskId) {
    throw UnimplementedError('ObjectBoxTaskRepository.softDelete');
  }

  @override
  Future<List<Task>> listAll() {
    throw UnimplementedError('ObjectBoxTaskRepository.listAll');
  }

  @override
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
  }) {
    throw UnimplementedError('ObjectBoxTaskRepository.listArchivedTasks');
  }

  @override
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
  }) {
    throw UnimplementedError('ObjectBoxTaskRepository.listTrashedTasks');
  }

  @override
  Future<List<Task>> listChildren(String parentId) {
    throw UnimplementedError('ObjectBoxTaskRepository.listChildren');
  }

  @override
  Future<List<Task>> listChildrenIncludingTrashed(String parentId) {
    throw UnimplementedError(
      'ObjectBoxTaskRepository.listChildrenIncludingTrashed',
    );
  }

  @override
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
  }) {
    throw UnimplementedError('ObjectBoxTaskRepository.listCompletedTasks');
  }

  @override
  Future<List<Task>> listRoots() {
    throw UnimplementedError('ObjectBoxTaskRepository.listRoots');
  }

  @override
  Future<List<Task>> listSectionTasks(TaskSection section) {
    throw UnimplementedError('ObjectBoxTaskRepository.listSectionTasks');
  }

  @override
  Future<List<Task>> listTasksByMilestoneId(String milestoneId) {
    throw UnimplementedError('ObjectBoxTaskRepository.listTasksByMilestoneId');
  }

  @override
  Future<List<Task>> searchByTitle(
    String query, {
    TaskStatus? status,
    int limit = 50,
  }) {
    throw UnimplementedError('ObjectBoxTaskRepository.searchByTitle');
  }

  @override
  Future<void> updateTask(String taskId, TaskUpdate payload) {
    throw UnimplementedError('ObjectBoxTaskRepository.updateTask');
  }

  @override
  Future<Task?> findById(String id) {
    throw UnimplementedError('ObjectBoxTaskRepository.findById');
  }

  @override
  Future<Task?> findBySlug(String slug) {
    throw UnimplementedError('ObjectBoxTaskRepository.findBySlug');
  }

  @override
  Future<Task?> findByTaskId(String taskId) {
    throw UnimplementedError('ObjectBoxTaskRepository.findByTaskId');
  }

  @override
  Stream<List<Task>> watchInbox() {
    throw UnimplementedError('ObjectBoxTaskRepository.watchInbox');
  }

  @override
  Stream<List<Task>> watchInboxFiltered({
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  }) {
    throw UnimplementedError('ObjectBoxTaskRepository.watchInboxFiltered');
  }

  @override
  Stream<List<Task>> watchMilestones(String projectId) {
    throw UnimplementedError('ObjectBoxTaskRepository.watchMilestones');
  }

  @override
  Stream<List<Task>> watchProjects() {
    throw UnimplementedError('ObjectBoxTaskRepository.watchProjects');
  }

  @override
  Stream<List<Task>> watchQuickTasks() {
    throw UnimplementedError('ObjectBoxTaskRepository.watchQuickTasks');
  }

  @override
  Stream<List<Task>> watchSection(TaskSection section) {
    throw UnimplementedError('ObjectBoxTaskRepository.watchSection');
  }

  @override
  Stream<List<Task>> watchTasksByMilestoneId(String milestoneId) {
    throw UnimplementedError('ObjectBoxTaskRepository.watchTasksByMilestoneId');
  }

  @override
  Stream<List<Task>> watchTasksByProjectId(String projectId) {
    throw UnimplementedError('ObjectBoxTaskRepository.watchTasksByProjectId');
  }

  @override
  Stream<Task?> watchTaskById(String id) {
    throw UnimplementedError('ObjectBoxTaskRepository.watchTaskById');
  }

  @override
  Stream<TaskTreeNode> watchTaskTree(String rootTaskId) {
    throw UnimplementedError('ObjectBoxTaskRepository.watchTaskTree');
  }
}
