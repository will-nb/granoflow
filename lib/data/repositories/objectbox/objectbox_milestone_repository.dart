import '../../database/database_adapter.dart';
import '../../models/milestone.dart';
import '../../models/task.dart';
import '../milestone_repository.dart';

class ObjectBoxMilestoneRepository implements MilestoneRepository {
  const ObjectBoxMilestoneRepository(this._adapter);

  final DatabaseAdapter _adapter;

  @override
  Future<Milestone> create(MilestoneDraft draft) {
    throw UnimplementedError('ObjectBoxMilestoneRepository.create');
  }

  @override
  Future<Milestone> createMilestoneWithId(
    MilestoneDraft draft,
    String milestoneId,
    DateTime createdAt,
    DateTime updatedAt,
  ) {
    throw UnimplementedError(
      'ObjectBoxMilestoneRepository.createMilestoneWithId',
    );
  }

  @override
  Future<void> delete(String id) {
    throw UnimplementedError('ObjectBoxMilestoneRepository.delete');
  }

  @override
  Future<Milestone?> findById(String id) {
    throw UnimplementedError('ObjectBoxMilestoneRepository.findById');
  }

  @override
  Future<List<Milestone>> listAll() {
    throw UnimplementedError('ObjectBoxMilestoneRepository.listAll');
  }

  @override
  Future<List<Milestone>> listByProjectId(String projectId) {
    throw UnimplementedError('ObjectBoxMilestoneRepository.listByProjectId');
  }

  @override
  Future<void> update(String id, MilestoneUpdate update) {
    throw UnimplementedError('ObjectBoxMilestoneRepository.update');
  }

  @override
  Stream<List<Milestone>> watchByProjectId(String projectId) {
    throw UnimplementedError(
      'ObjectBoxMilestoneRepository.watchByProjectId',
    );
  }
}
