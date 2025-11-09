import '../../database/database_adapter.dart';
import '../../models/project.dart';
import '../../models/task.dart';
import '../project_repository.dart';

class ObjectBoxProjectRepository implements ProjectRepository {
  const ObjectBoxProjectRepository(this._adapter);

  final DatabaseAdapter _adapter;

  @override
  Future<Project> create(ProjectDraft draft) {
    throw UnimplementedError('ObjectBoxProjectRepository.create');
  }

  @override
  Future<Project> createProjectWithId(
    ProjectDraft draft,
    String projectId,
    DateTime createdAt,
    DateTime updatedAt,
  ) {
    throw UnimplementedError('ObjectBoxProjectRepository.createProjectWithId');
  }

  @override
  Future<void> delete(String id) {
    throw UnimplementedError('ObjectBoxProjectRepository.delete');
  }

  @override
  Future<Project?> findById(String id) {
    throw UnimplementedError('ObjectBoxProjectRepository.findById');
  }

  @override
  Future<List<Project>> listAll() {
    throw UnimplementedError('ObjectBoxProjectRepository.listAll');
  }

  @override
  Future<void> update(String id, ProjectUpdate update) {
    throw UnimplementedError('ObjectBoxProjectRepository.update');
  }

  @override
  Stream<List<Project>> watchActiveProjects() {
    throw UnimplementedError('ObjectBoxProjectRepository.watchActiveProjects');
  }

  @override
  Stream<List<Project>> watchProjectsByStatus(ProjectFilterStatus status) {
    throw UnimplementedError(
      'ObjectBoxProjectRepository.watchProjectsByStatus',
    );
  }

  @override
  Stream<List<Project>> watchProjectsByStatuses(
    Set<TaskStatus> allowedStatuses,
  ) {
    throw UnimplementedError(
      'ObjectBoxProjectRepository.watchProjectsByStatuses',
    );
  }
}
