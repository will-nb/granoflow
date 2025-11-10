import 'package:objectbox/objectbox.dart';

import '../../database/database_adapter.dart';
import '../../database/objectbox_adapter.dart';
import '../../models/focus_session.dart';
import '../../objectbox/focus_session_entity.dart';
import '../focus_session_repository.dart';

class ObjectBoxFocusSessionRepository implements FocusSessionRepository {
  const ObjectBoxFocusSessionRepository(this._adapter);

  final DatabaseAdapter _adapter;

  ObjectBoxAdapter get _objectBoxAdapter {
    final adapter = _adapter;
    if (adapter is! ObjectBoxAdapter) {
      throw StateError(
        'ObjectBoxFocusSessionRepository requires ObjectBoxAdapter',
      );
    }
    return adapter;
  }

  Box<FocusSessionEntity> get _focusSessionBox =>
      _objectBoxAdapter.store.box<FocusSessionEntity>();

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
  Future<int> totalMinutesOverall() async {
    return await _adapter.readTransaction(() async {
      final box = _focusSessionBox;
      final allSessions = box.getAll();
      
      // 计算所有会话的 actualMinutes 总和
      int total = 0;
      for (final session in allSessions) {
        total += session.actualMinutes;
      }
      
      return total;
    });
  }

  @override
  Stream<FocusSession?> watchActiveSession(String taskId) {
    throw UnimplementedError(
      'ObjectBoxFocusSessionRepository.watchActiveSession',
    );
  }
}
