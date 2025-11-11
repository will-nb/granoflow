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

  /// 按日期范围查询每日的专注时长（分钟）
  /// 
  /// [start] 开始日期（包含）
  /// [end] 结束日期（包含）
  /// [taskIds] 可选的任务ID列表，用于筛选
  /// 返回 Map<日期, 专注时长（分钟）>，日期只包含年月日
  Future<Map<DateTime, int>> getFocusMinutesByDateRange({
    required DateTime start,
    required DateTime end,
    List<String>? taskIds,
  });

  /// 按日期范围查询焦点会话列表
  /// 
  /// [start] 开始日期（包含）
  /// [end] 结束日期（包含）
  /// [taskIds] 可选的任务ID列表，用于筛选
  /// 返回已结束的会话列表，按开始时间降序排列
  Future<List<FocusSession>> listSessionsByDateRange({
    required DateTime start,
    required DateTime end,
    List<String>? taskIds,
  });
}
