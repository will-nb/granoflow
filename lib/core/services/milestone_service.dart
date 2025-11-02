import '../../data/models/milestone.dart';
import '../../data/repositories/milestone_repository.dart';

class MilestoneService {
  MilestoneService({required MilestoneRepository milestoneRepository})
    : _milestones = milestoneRepository;

  final MilestoneRepository _milestones;

  Stream<List<Milestone>> watchByProjectId(String projectId) {
    return _milestones.watchByProjectId(projectId);
  }

  Future<List<Milestone>> listByProjectId(String projectId) {
    return _milestones.listByProjectId(projectId);
  }

  Future<Milestone?> findByIsarId(int isarId) {
    return _milestones.findByIsarId(isarId);
  }

  Future<Milestone?> findByMilestoneId(String milestoneId) {
    return _milestones.findByMilestoneId(milestoneId);
  }

  Future<void> delete(int isarId) {
    return _milestones.delete(isarId);
  }
}
