import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';

/// ProjectService 任务相关操作方法
/// 
/// 包含项目下任务的管理方法
class ProjectServiceTasks {
  ProjectServiceTasks({
    required TaskRepository taskRepository,
  }) : _tasks = taskRepository;

  final TaskRepository _tasks;

  Future<List<Task>> listTasksForProject(String projectId) async {
    final allTasks = await _tasks.listAll();
    return allTasks
        .where((task) => task.projectId == projectId)
        .toList(growable: false);
  }

  /// 检查项目下是否有活跃任务
  Future<bool> hasActiveTasks(String projectId) async {
    final tasks = await listTasksForProject(projectId);
    return tasks.any((task) =>
        task.status == TaskStatus.pending || task.status == TaskStatus.doing);
  }

  /// 层级功能已移除，不再有后代任务
  Future<List<Task>> getAllDescendants(String taskId) async {
    // 层级功能已移除，返回空列表
    return <Task>[];
  }

  /// 归档项目下所有活跃任务及其子任务
  Future<void> archiveActiveTasksForProject(String projectId) async {
    final tasks = await listTasksForProject(projectId);
    final activeTasks = tasks.where((task) =>
        task.status == TaskStatus.pending || task.status == TaskStatus.doing);
    
    for (final task in activeTasks) {
      // archiveTask会自动归档所有子任务
      await _tasks.archiveTask(task.id);
    }
  }

  /// 将项目下所有任务移入回收站（包括子任务）
  Future<void> trashAllTasksForProject(String projectId) async {
    final tasks = await listTasksForProject(projectId);
    
    for (final task in tasks) {
      // softDelete会自动将子任务移入回收站
      await _tasks.softDelete(task.id);
    }
  }

  /// 删除项目下所有任务（包括子任务）
  Future<void> deleteAllTasksForProject(String projectId) async {
    final tasks = await listTasksForProject(projectId);
    
    // 收集所有需要删除的任务ID（包括子任务）
    final taskIdsToDelete = <String>{};
    for (final task in tasks) {
      taskIdsToDelete.add(task.id);
      final descendants = await getAllDescendants(task.id);
      taskIdsToDelete.addAll(descendants.map((t) => t.id));
    }
    
    // 将所有任务标记为 pseudoDeleted
    for (final taskId in taskIdsToDelete) {
      await _tasks.markStatus(taskId: taskId, status: TaskStatus.pseudoDeleted);
    }
    
    // 立即清理标记为 pseudoDeleted 的任务
    await _tasks.purgeObsolete(DateTime.now());
  }

  /// 层级功能已移除，不再需要递归分配项目给后代任务
  Future<void> assignProjectToDescendants(String taskId, String projectId) async {
    // 层级功能已移除，不再有后代任务
  }
}

