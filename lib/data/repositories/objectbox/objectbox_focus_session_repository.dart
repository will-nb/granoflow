import '../../database/database_adapter.dart';
import '../../models/focus_session.dart';
import '../focus_session_repository.dart';

class ObjectBoxFocusSessionRepository implements FocusSessionRepository {
  const ObjectBoxFocusSessionRepository(this._adapter);

  // ignore: unused_field
  final DatabaseAdapter _adapter;

  @override
  Future<FocusSession?> findById(String sessionId) {
    throw UnimplementedError('ObjectBoxFocusSessionRepository.findById');
  }

  @override
  Future<void> endSession({
    required String sessionId,
    required int actualMinutes,
    String? transferToTaskId,
    String? reflectionNote,
  }) {
    throw UnimplementedError('ObjectBoxFocusSessionRepository.endSession');
  }

  @override
  Future<List<FocusSession>> listRecentSessions({
    required String taskId,
    int limit = 10,
  }) {
    throw UnimplementedError(
      'ObjectBoxFocusSessionRepository.listRecentSessions',
    );
  }

  @override
  Future<FocusSession> startSession({
    required String taskId,
    int? estimateMinutes,
    bool alarmEnabled = false,
  }) {
    throw UnimplementedError('ObjectBoxFocusSessionRepository.startSession');
  }

  @override
  Future<int> totalMinutesForTask(String taskId) {
    throw UnimplementedError(
      'ObjectBoxFocusSessionRepository.totalMinutesForTask',
    );
  }

  @override
  Future<Map<String, int>> totalMinutesForTasks(List<String> taskIds) {
    throw UnimplementedError(
      'ObjectBoxFocusSessionRepository.totalMinutesForTasks',
    );
  }

  @override
  Future<int> totalMinutesOverall() {
    throw UnimplementedError(
      'ObjectBoxFocusSessionRepository.totalMinutesOverall',
    );
  }

  @override
  Stream<FocusSession?> watchActiveSession(String taskId) {
    throw UnimplementedError(
      'ObjectBoxFocusSessionRepository.watchActiveSession',
    );
  }
}
