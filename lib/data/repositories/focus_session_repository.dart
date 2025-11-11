import '../models/focus_session.dart';

abstract class FocusSessionRepository {
  Future<FocusSession> startSession({
    required String taskId,
    int? estimateMinutes,
    bool alarmEnabled,
  });

  Future<void> endSession({
    required String sessionId,
    required int actualMinutes,
    String? transferToTaskId,
    String? reflectionNote,
  });

  /// 更新session的已用时间（不结束session）
  Future<void> updateSessionActualMinutes({
    required String sessionId,
    required int actualMinutes,
  });

  Stream<FocusSession?> watchActiveSession(String taskId);

  Future<List<FocusSession>> listRecentSessions({
    required String taskId,
    int limit,
  });

  Future<int> totalMinutesForTask(String taskId);

  /// 批量查询多个任务的总时间
  /// 返回 Map<taskId, totalMinutes>，避免 N+1 查询问题
  Future<Map<String, int>> totalMinutesForTasks(List<String> taskIds);

  Future<int> totalMinutesOverall();

  Future<FocusSession?> findById(String sessionId);
}
