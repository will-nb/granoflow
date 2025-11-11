import '../../data/models/task.dart';
import '../../data/models/tag.dart';
import '../../data/repositories/focus_session_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/tag_repository.dart';
import 'clock_audio_service.dart';
import 'metric_orchestrator.dart';
import 'preference_service.dart';
import 'sort_index_service.dart';
import 'task_crud_service.dart';
import 'task_drag_service.dart';
import 'task_promotion_service.dart';
import 'task_query_service.dart';
import 'task_status_service.dart';
import 'task_hierarchy_service.dart';

/// TaskService - 任务服务组合类（Facade 模式）
///
/// 将所有任务相关操作委托给专门的服务类：
/// - TaskCrudService: CRUD 操作
/// - TaskStatusService: 状态管理
/// - TaskDragService: 拖拽操作
/// - TaskPromotionService: 任务提升
/// - TaskQueryService: 查询操作
///
/// 保持向后兼容的 API，所有现有代码无需修改
class TaskService {
  TaskService({
    required TaskRepository taskRepository,
    required TagRepository tagRepository,
    required MetricOrchestrator metricOrchestrator,
    FocusSessionRepository? focusSessionRepository,
    SortIndexService? sortIndexService,
    ClockAudioService? clockAudioService,
    PreferenceService? preferenceService,
    DateTime Function()? clock,
  })  : _crudService = TaskCrudService(
          taskRepository: taskRepository,
          metricOrchestrator: metricOrchestrator,
          sortIndexService: sortIndexService,
          clock: clock,
        ),
        _statusService = TaskStatusService(
          taskRepository: taskRepository,
          metricOrchestrator: metricOrchestrator,
          focusSessionRepository: focusSessionRepository,
          clockAudioService: clockAudioService,
          preferenceService: preferenceService,
          clock: clock,
        ),
        _dragService = TaskDragService(
          taskRepository: taskRepository,
          metricOrchestrator: metricOrchestrator,
          sortIndexService: sortIndexService,
          clock: clock,
        ),
        _promotionService = TaskPromotionService(
          taskRepository: taskRepository,
          metricOrchestrator: metricOrchestrator,
          sortIndexService: sortIndexService,
          clock: clock,
        ),
        _queryService = TaskQueryService(
          taskRepository: taskRepository,
          tagRepository: tagRepository,
        );

  final TaskCrudService _crudService;
  final TaskStatusService _statusService;
  final TaskDragService _dragService;
  final TaskPromotionService _promotionService;
  final TaskQueryService _queryService;

  // ===== CRUD 操作 =====

  /// 在 Inbox 中创建任务
  Future<Task> captureInboxTask({
    required String title,
    List<String> tags = const <String>[],
  }) =>
      _crudService.captureInboxTask(title: title, tags: tags);

  /// 规划任务（设置截止日期和区域）
  Future<void> planTask({
    required String taskId,
    required DateTime dueDateLocal,
    required TaskSection section,
  }) =>
      _crudService.planTask(
        taskId: taskId,
        dueDateLocal: dueDateLocal,
        section: section,
      );

  /// 更新任务详情
  Future<void> updateDetails({
    required String taskId,
    required TaskUpdate payload,
  }) =>
      _crudService.updateDetails(taskId: taskId, payload: payload);

  /// 更新任务标签
  Future<void> updateTags({
    required String taskId,
    String? contextTag,
    String? priorityTag,
  }) =>
      _crudService.updateTags(
        taskId: taskId,
        contextTag: contextTag,
        priorityTag: priorityTag,
      );

  /// 清空回收站：批量永久删除所有回收站任务
  /// 返回删除的任务数量
  Future<int> clearTrash() => _crudService.clearTrash();

  // ===== 状态管理操作 =====

  /// 标记任务为进行中
  Future<void> markInProgress(String taskId) =>
      _statusService.markInProgress(taskId);

  /// 标记任务为已暂停
  Future<void> markPaused(String taskId) =>
      _statusService.markPaused(taskId);

  /// 标记任务为恢复（从暂停状态恢复为进行中）
  Future<void> markResumed(String taskId) =>
      _statusService.markResumed(taskId);

  /// 标记任务为已完成
  Future<void> markCompleted({
    required String taskId,
    bool autoCompleteParent = true,
  }) =>
      _statusService.markCompleted(
        taskId: taskId,
        autoCompleteParent: autoCompleteParent,
      );

  /// 归档任务
  Future<void> archive(String taskId) => _statusService.archive(taskId);

  /// 软删除任务（移到回收站）
  Future<void> softDelete(String taskId) =>
      _statusService.softDelete(taskId);

  // ===== 拖拽操作 =====

  /// 处理拖拽到任务间（调整sortIndex，支持跨区域）
  Future<void> handleDragBetweenTasks(
    String draggedTaskId,
    String beforeTaskId,
    String afterTaskId,
  ) =>
      _dragService.handleDragBetweenTasks(
        draggedTaskId,
        beforeTaskId,
        afterTaskId,
      );

  /// 处理拖拽到区域首位
  Future<void> handleDragToSectionFirst(
    String draggedTaskId,
    TaskSection section,
  ) =>
      _dragService.handleDragToSectionFirst(draggedTaskId, section);

  /// 处理拖拽到区域末位
  Future<void> handleDragToSectionLast(
    String draggedTaskId,
    TaskSection section,
  ) =>
      _dragService.handleDragToSectionLast(draggedTaskId, section);

  /// 处理 Inbox 任务在两个任务之间拖拽
  Future<void> handleInboxDragBetween(
    String draggedId,
    String beforeId,
    String afterId,
  ) =>
      _dragService.handleInboxDragBetween(draggedId, beforeId, afterId);

  /// 处理 Inbox 任务拖拽到列表开头
  Future<void> handleInboxDragToFirst(String draggedId) =>
      _dragService.handleInboxDragToFirst(draggedId);

  /// 处理 Inbox 任务拖拽到列表结尾
  Future<void> handleInboxDragToLast(String draggedId) =>
      _dragService.handleInboxDragToLast(draggedId);

  // ===== 任务提升操作 =====

  /// 处理子任务向左拖拽升级为根任务
  Future<bool> handlePromoteToIndependent(
    String taskId,
    TaskHierarchyService taskHierarchyService, {
    required double? horizontalOffset,
    required double? verticalOffset,
    double leftDragThreshold = -30.0,
    double verticalThreshold = 50.0,
  }) =>
      _promotionService.handlePromoteToIndependent(
        taskId,
        taskHierarchyService,
        horizontalOffset: horizontalOffset,
        verticalOffset: verticalOffset,
        leftDragThreshold: leftDragThreshold,
        verticalThreshold: verticalThreshold,
      );

  /// 将子任务提升为根任务（用于滑动动作）
  Future<bool> promoteSubtaskToRoot(String taskId, {int? taskLevel}) =>
      _promotionService.promoteSubtaskToRoot(taskId, taskLevel: taskLevel);

  // ===== 查询操作 =====

  /// 按标签类型列出标签
  Future<List<Tag>> listTagsByKind(TagKind kind) =>
      _queryService.listTagsByKind(kind);

  /// 监听快速任务列表变化
  Stream<List<Task>> watchQuickTasks() => _queryService.watchQuickTasks();

  /// 按标题搜索任务
  Future<List<Task>> searchTasksByTitle(
    String query, {
    TaskStatus? status,
    int limit = 20,
  }) =>
      _queryService.searchTasksByTitle(
        query,
        status: status,
        limit: limit,
      );
}
