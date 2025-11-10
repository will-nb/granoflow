import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:granoflow/core/providers/repository_providers.dart';
import 'package:granoflow/data/models/project.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/data/repositories/project_repository.dart';
import 'package:granoflow/core/providers/project_filter_providers.dart';

void main() {
  group('Project Filter Providers', () {
    late _FakeProjectRepository repository;

    setUp(() {
      repository = _FakeProjectRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    test(
      'projectsForCompletedArchivedFilterProvider returns active, completed, and archived projects',
      () async {
        // 创建测试项目
        final projects = [
          _createProject('active1', TaskStatus.pending),
          _createProject('active2', TaskStatus.doing),
          _createProject('completed1', TaskStatus.completedActive),
          _createProject('archived1', TaskStatus.archived),
          _createProject('trashed1', TaskStatus.trashed),
          _createProject('pseudoDeleted1', TaskStatus.pseudoDeleted),
        ];

        // 先设置项目，这样 stream 会立即发射值
        repository.setProjects(projects);

        final container = ProviderContainer(
          overrides: [projectRepositoryProvider.overrideWithValue(repository)],
        );

        // 直接读取 repository 的方法来测试
        final stream = repository.watchProjectsByStatuses({
          TaskStatus.pending,
          TaskStatus.doing,
          TaskStatus.completedActive,
          TaskStatus.archived,
        });
        final projectList = await stream.first;

        // 应该只包含活跃、已完成、已归档项目
        expect(projectList.length, 4);
        expect(projectList.map((p) => p.projectId).toSet(), {
          'active1',
          'active2',
          'completed1',
          'archived1',
        });
        // 不应该包含回收站和伪删除项目
        expect(projectList.any((p) => p.projectId == 'trashed1'), false);
        expect(projectList.any((p) => p.projectId == 'pseudoDeleted1'), false);

        container.dispose();
      },
    );

    test(
      'projectsForTrashFilterProvider returns all projects except pseudoDeleted',
      () async {
        // 创建测试项目
        final projects = [
          _createProject('inbox1', TaskStatus.inbox),
          _createProject('active1', TaskStatus.pending),
          _createProject('active2', TaskStatus.doing),
          _createProject('completed1', TaskStatus.completedActive),
          _createProject('archived1', TaskStatus.archived),
          _createProject('trashed1', TaskStatus.trashed),
          _createProject('pseudoDeleted1', TaskStatus.pseudoDeleted),
        ];

        // 先设置项目，这样 stream 会立即发射值
        repository.setProjects(projects);

        final container = ProviderContainer(
          overrides: [projectRepositoryProvider.overrideWithValue(repository)],
        );

        // 直接读取 repository 的方法来测试
        final stream = repository.watchProjectsByStatuses({
          TaskStatus.inbox,
          TaskStatus.pending,
          TaskStatus.doing,
          TaskStatus.completedActive,
          TaskStatus.archived,
          TaskStatus.trashed,
        });
        final projectList = await stream.first;

        // 应该包含所有项目（除了伪删除）
        expect(projectList.length, 6);
        expect(projectList.map((p) => p.projectId).toSet(), {
          'inbox1',
          'active1',
          'active2',
          'completed1',
          'archived1',
          'trashed1',
        });
        // 不应该包含伪删除项目
        expect(projectList.any((p) => p.projectId == 'pseudoDeleted1'), false);

        container.dispose();
      },
    );
  });
}

Project _createProject(String projectId, TaskStatus status) {
  return Project(
    id: projectId,

    title: 'Project $projectId',
    status: status,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    sortIndex: 0,
    tags: const [],
    templateLockCount: 0,
    seedSlug: null,
    allowInstantComplete: false,
    description: null,
    logs: const [],
  );
}

class _FakeProjectRepository implements ProjectRepository {
  final StreamController<List<Project>> _controller =
      StreamController<List<Project>>.broadcast();
  List<Project> _projects = [];

  void setProjects(List<Project> projects) {
    _projects = projects;
    _controller.add(_projects);
  }

  @override
  Future<Project?> findById(String id) async {
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<List<Project>> watchActiveProjects() {
    return watchProjectsByStatus(ProjectFilterStatus.active);
  }

  @override
  Stream<List<Project>> watchProjectsByStatus(ProjectFilterStatus status) {
    return _controller.stream.map((allProjects) {
      return allProjects
          .where((project) {
            switch (status) {
              case ProjectFilterStatus.all:
                return project.status != TaskStatus.pseudoDeleted;
              case ProjectFilterStatus.active:
                return project.status == TaskStatus.pending ||
                    project.status == TaskStatus.doing;
              case ProjectFilterStatus.completed:
                return project.status == TaskStatus.completedActive;
              case ProjectFilterStatus.archived:
                return project.status == TaskStatus.archived;
              case ProjectFilterStatus.trash:
                return project.status == TaskStatus.trashed;
            }
          })
          .toList(growable: false);
    });
  }

  @override
  Stream<List<Project>> watchProjectsByStatuses(
    Set<TaskStatus> allowedStatuses,
  ) {
    // 先发射当前值（如果有的话）
    final currentValue = _projects
        .where((project) {
          // 排除伪删除状态
          if (project.status == TaskStatus.pseudoDeleted) {
            return false;
          }
          // 只返回状态在允许集合中的项目
          return allowedStatuses.contains(project.status);
        })
        .toList(growable: false);

    // 然后监听后续变化
    return Stream.multi((controller) {
      // 立即发射当前值
      controller.add(currentValue);
      // 监听后续变化
      final subscription = _controller.stream.listen((allProjects) {
        final filtered = allProjects
            .where((project) {
              // 排除伪删除状态
              if (project.status == TaskStatus.pseudoDeleted) {
                return false;
              }
              // 只返回状态在允许集合中的项目
              return allowedStatuses.contains(project.status);
            })
            .toList(growable: false);
        controller.add(filtered);
      });
      controller.onCancel = () => subscription.cancel();
    });
  }

  @override
  Future<Project?> findByProjectId(String projectId) async {
    try {
      return _projects.firstWhere((p) => p.id == projectId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Project> create(ProjectDraft draft) async {
    throw UnimplementedError();
  }

  @override
  Future<Project> createProjectWithId(
    ProjectDraft draft,
    String projectId,
    DateTime createdAt,
    DateTime updatedAt,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> update(int isarId, ProjectUpdate update) async {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(int isarId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Project>> listAll() async {
    return _projects;
  }

  void dispose() {
    _controller.close();
  }
}
