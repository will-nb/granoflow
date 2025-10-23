import '../../data/models/focus_session.dart';
import '../../data/models/task.dart';
import '../../data/repositories/focus_session_repository.dart';
import '../../data/repositories/task_repository.dart';
import 'metric_orchestrator.dart';
import 'task_service.dart';

enum FocusOutcome {
  complete,
  completeWithoutTimer,
  addSubtask,
  logMultiple,
  markWasted,
}

class FocusFlowService {
  FocusFlowService({
    required FocusSessionRepository focusRepository,
    required TaskRepository taskRepository,
    required TaskService taskService,
    required MetricOrchestrator metricOrchestrator,
  }) : _focusRepository = focusRepository,
       _taskRepository = taskRepository,
       _taskService = taskService,
       _metricOrchestrator = metricOrchestrator;

  final FocusSessionRepository _focusRepository;
  final TaskRepository _taskRepository;
  final TaskService _taskService;
  final MetricOrchestrator _metricOrchestrator;

  Future<FocusSession> startFocus({
    required int taskId,
    int? estimateMinutes,
    bool alarmEnabled = false,
  }) {
    return _focusRepository.startSession(
      taskId: taskId,
      estimateMinutes: estimateMinutes,
      alarmEnabled: alarmEnabled,
    );
  }

  Future<void> pauseFocus(int sessionId) async {
    // Placeholder for pause support; in-memory repository keeps session active.
  }

  Future<void> endFocus({
    required int sessionId,
    required FocusOutcome outcome,
    int? transferToTaskId,
    String? reflectionNote,
  }) async {
    final session = await _focusRepository.findById(sessionId);
    if (session == null) {
      return;
    }
    final duration = DateTime.now().difference(session.startedAt);
    final actualMinutes = duration.inMinutes.clamp(0, 24 * 60);
    await _focusRepository.endSession(
      sessionId: sessionId,
      actualMinutes: actualMinutes,
      transferToTaskId: transferToTaskId,
      reflectionNote: reflectionNote,
    );

    final effectiveTaskId = transferToTaskId ?? session.taskId;
    if (effectiveTaskId <= 0) {
      return;
    }

    switch (outcome) {
      case FocusOutcome.complete:
      case FocusOutcome.completeWithoutTimer:
        await _taskService.markCompleted(taskId: effectiveTaskId);
        break;
      case FocusOutcome.addSubtask:
        break;
      case FocusOutcome.logMultiple:
        break;
      case FocusOutcome.markWasted:
        final task = await _taskRepository.findById(effectiveTaskId);
        if (task != null && !task.tags.contains('wasted')) {
          await _taskRepository.updateTask(
            effectiveTaskId,
            TaskUpdate(tags: [...task.tags, 'wasted']),
          );
        }
        break;
    }
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.session);
  }

  Future<Task> quickSubtask({
    required int parentTaskId,
    required String title,
  }) async {
    final draft = TaskDraft(
      title: title,
      status: TaskStatus.pending,
      parentId: parentTaskId,
      allowInstantComplete: false,
    );
    final task = await _taskRepository.createTask(draft);
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
    return task;
  }

  Stream<FocusSession?> watchActive(int taskId) =>
      _focusRepository.watchActiveSession(taskId);
}
