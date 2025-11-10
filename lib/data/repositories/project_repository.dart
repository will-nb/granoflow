import '../../core/providers/project_filter_providers.dart';
import '../models/project.dart';
import '../models/task.dart';

abstract class ProjectRepository {
  Stream<List<Project>> watchActiveProjects();

  Stream<List<Project>> watchProjectsByStatus(ProjectFilterStatus status);

  Stream<List<Project>> watchProjectsByStatuses(
    Set<TaskStatus> allowedStatuses,
  );

  Future<Project?> findById(String id);

  Future<Project> create(ProjectDraft draft);

  Future<Project> createProjectWithId(
    ProjectDraft draft,
    String projectId,
    DateTime createdAt,
    DateTime updatedAt,
  );

  Future<void> update(String id, ProjectUpdate update);

  Future<void> delete(String id);

  Future<List<Project>> listAll();
}
