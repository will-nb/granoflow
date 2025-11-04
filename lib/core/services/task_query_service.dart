import '../../data/models/task.dart';
import '../../data/models/tag.dart';
import '../../data/repositories/tag_repository.dart';
import '../../data/repositories/task_repository.dart';

/// 任务查询服务
/// 负责任务和标签的查询操作
class TaskQueryService {
  TaskQueryService({
    required TaskRepository taskRepository,
    required TagRepository tagRepository,
  }) : _tasks = taskRepository,
       _tags = tagRepository;

  final TaskRepository _tasks;
  final TagRepository _tags;

  /// 按标签类型列出标签
  Future<List<Tag>> listTagsByKind(TagKind kind) => _tags.listByKind(kind);

  /// 监听快速任务列表变化
  Stream<List<Task>> watchQuickTasks() => _tasks.watchQuickTasks();

  /// 按标题搜索任务
  ///
  /// [query] 搜索关键词
  /// [status] 可选的任务状态过滤
  /// [limit] 返回结果数量限制，默认 20
  Future<List<Task>> searchTasksByTitle(
    String query, {
    TaskStatus? status,
    int limit = 20,
  }) {
    if (query.trim().isEmpty) {
      return Future.value(const <Task>[]);
    }
    return _tasks.searchByTitle(query, status: status, limit: limit);
  }
}

