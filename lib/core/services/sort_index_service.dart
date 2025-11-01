import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';

/// 稀疏整数排序（gap-based ranking）服务
/// - 取中值插入；
/// - 无间隙时在插入点附近做局部重排；
/// - 支持整域批量重排（按有序ID列表）。
/// - 统一管理任务排序规则和 sortIndex 修改逻辑
class SortIndexService {
  SortIndexService({
    required TaskRepository taskRepository,
    DateTime Function()? clock,
  })  : _tasks = taskRepository,
        _clock = clock ?? DateTime.now;

  final TaskRepository _tasks;
  final DateTime Function() _clock;

  // 默认参数
  static const double _step = 1024.0;
  static const double _minGap = 2.0;
  static const int _window = 50;

  // ===== 排序方法（静态方法，纯函数，不依赖服务状态） =====

  /// Inbox页面的排序比较函数
  ///
  /// 排序规则：sortIndex升序 → createdAt降序（兜底）
  static int _compareTasksForInbox(Task a, Task b) {
    // 1. 按 sortIndex 升序排序
    final sortIndexComparison = a.sortIndex.compareTo(b.sortIndex);
    if (sortIndexComparison != 0) return sortIndexComparison;

    // 2. sortIndex 相同，按 createdAt 降序排序（新任务在前）
    return b.createdAt.compareTo(a.createdAt);
  }

  /// Tasks页面的排序比较函数
  ///
  /// 排序规则：dueAt升序 → sortIndex升序 → createdAt降序（兜底）
  static int _compareTasksForTasksPage(Task a, Task b) {
    // 1. 比较 dueAt 的日期部分（忽略时间）
    final aDate = a.dueAt;
    final bDate = b.dueAt;

    if (aDate == null && bDate == null) {
      // 两者都没有 dueAt，按 sortIndex 升序 → createdAt 降序
      final sortIndexComparison = a.sortIndex.compareTo(b.sortIndex);
      if (sortIndexComparison != 0) return sortIndexComparison;
      return b.createdAt.compareTo(a.createdAt);
    }

    if (aDate == null) return 1; // 没有 dueAt 的排在后面
    if (bDate == null) return -1;

    // 提取日期部分（年-月-日，忽略时分秒）
    final aDayOnly = DateTime(aDate.year, aDate.month, aDate.day);
    final bDayOnly = DateTime(bDate.year, bDate.month, bDate.day);

    final dateComparison = aDayOnly.compareTo(bDayOnly);
    if (dateComparison != 0) return dateComparison;

    // 2. 日期相同，按 sortIndex 升序
    final sortIndexComparison = a.sortIndex.compareTo(b.sortIndex);
    if (sortIndexComparison != 0) return sortIndexComparison;

    // 3. sortIndex 也相同，按 createdAt 降序（新任务在前）
    return b.createdAt.compareTo(a.createdAt);
  }

  /// 子任务排序比较函数
  ///
  /// 排序规则：sortIndex升序 → createdAt降序（兜底）
  /// 用于在各自父任务内对子任务进行排序
  static int _compareTasksForChildren(Task a, Task b) {
    // 与 Inbox 排序规则相同：sortIndex升序 → createdAt降序
    return _compareTasksForInbox(a, b);
  }

  /// 对任务列表进行排序（Inbox页面）
  ///
  /// [tasks] 要排序的任务列表（会被原地修改）
  static void sortTasksForInbox(List<Task> tasks) {
    tasks.sort(_compareTasksForInbox);
  }

  /// 对任务列表进行排序（Tasks页面）
  ///
  /// [tasks] 要排序的任务列表（会被原地修改）
  static void sortTasksForTasksPage(List<Task> tasks) {
    tasks.sort(_compareTasksForTasksPage);
  }

  /// 对子任务列表进行排序
  ///
  /// [tasks] 要排序的子任务列表（会被原地修改）
  static void sortChildrenTasks(List<Task> tasks) {
    tasks.sort(_compareTasksForChildren);
  }

  /// 直接按域内的有序ID进行重排（标准化）
  ///
  /// [orderedIds] 已排序的任务ID列表
  Future<void> reorderIds({
    required List<int> orderedIds,
    String? domainKey,
    double start = 1024,
    double step = _step,
  }) async {
    if (orderedIds.isEmpty) return;
    final updates = <int, TaskUpdate>{};
    for (int i = 0; i < orderedIds.length; i++) {
      updates[orderedIds[i]] = TaskUpdate(sortIndex: (start + i * step).toDouble());
    }
    await _tasks.batchUpdate(updates);
  }

  /// 按任务列表排序并重排（Inbox页面）
  ///
  /// 接收任务列表，使用统一的排序规则排序后，批量更新 sortIndex
  Future<void> reorderTasksForInbox({
    required List<Task> tasks,
    double start = 1024,
    double step = _step,
  }) async {
    if (tasks.isEmpty) return;
    final sorted = List<Task>.from(tasks);
    sortTasksForInbox(sorted);
    final updates = <int, TaskUpdate>{};
    for (int i = 0; i < sorted.length; i++) {
      updates[sorted[i].id] = TaskUpdate(sortIndex: (start + i * step).toDouble());
    }
    await _tasks.batchUpdate(updates);
  }

  /// 按任务列表排序并重排（Tasks页面）
  ///
  /// 接收任务列表，使用统一的排序规则排序后，批量更新 sortIndex
  Future<void> reorderTasksForTasksPage({
    required List<Task> tasks,
    double start = 1024,
    double step = _step,
  }) async {
    if (tasks.isEmpty) return;
    final sorted = List<Task>.from(tasks);
    sortTasksForTasksPage(sorted);
    final updates = <int, TaskUpdate>{};
    for (int i = 0; i < sorted.length; i++) {
      updates[sorted[i].id] = TaskUpdate(sortIndex: (start + i * step).toDouble());
    }
    await _tasks.batchUpdate(updates);
  }

  /// 批量重排子任务的sortIndex
  ///
  /// 接收子任务列表，使用统一的排序规则排序后，批量更新 sortIndex
  /// 用于父任务内的子任务重排序
  ///
  /// [children] 子任务列表
  /// [start] 起始 sortIndex 值
  /// [step] sortIndex 间隔
  Future<void> reorderChildrenTasks({
    required List<Task> children,
    double start = 1024,
    double step = _step,
  }) async {
    if (children.isEmpty) return;
    final sorted = List<Task>.from(children);
    sortChildrenTasks(sorted);
    final updates = <int, TaskUpdate>{};
    for (int i = 0; i < sorted.length; i++) {
      updates[sorted[i].id] = TaskUpdate(sortIndex: (start + i * step).toDouble());
    }
    await _tasks.batchUpdate(updates);
  }

  /// 按日期分组批量重排同一天的任务（Tasks页面）
  ///
  /// 从任务列表中筛选出与目标日期同一天的任务，按统一排序规则排序后批量更新 sortIndex
  /// 用于Tasks页面中，当任务移动后，只重排同一天内的任务
  ///
  /// [allTasks] 所有任务列表（用于筛选）
  /// [targetDate] 目标日期（只比较日期部分，忽略时分秒）
  /// [start] 起始 sortIndex 值
  /// [step] sortIndex 间隔
  Future<void> reorderTasksForSameDate({
    required List<Task> allTasks,
    required DateTime? targetDate,
    double start = 1024,
    double step = _step,
  }) async {
    if (targetDate == null) {
      // 如果目标日期为 null，筛选所有没有 dueAt 的任务
      final tasksWithoutDate = allTasks.where((task) => task.dueAt == null).toList();
      if (tasksWithoutDate.isEmpty) return;
      
      final sorted = List<Task>.from(tasksWithoutDate);
      sortTasksForTasksPage(sorted);
      final updates = <int, TaskUpdate>{};
      for (int i = 0; i < sorted.length; i++) {
        updates[sorted[i].id] = TaskUpdate(sortIndex: (start + i * step).toDouble());
      }
      await _tasks.batchUpdate(updates);
      return;
    }

    // 提取目标日期的日期部分（年-月-日，忽略时分秒）
    final targetDayOnly = DateTime(targetDate.year, targetDate.month, targetDate.day);

    // 筛选出同一天的任务
    final sameDateTasks = allTasks.where((task) {
      if (task.dueAt == null) return false;
      final taskDayOnly = DateTime(task.dueAt!.year, task.dueAt!.month, task.dueAt!.day);
      return taskDayOnly == targetDayOnly;
    }).toList();

    if (sameDateTasks.isEmpty) return;

    // 使用统一的排序规则排序
    final sorted = List<Task>.from(sameDateTasks);
    sortTasksForTasksPage(sorted);
    
    // 批量更新 sortIndex
    final updates = <int, TaskUpdate>{};
    for (int i = 0; i < sorted.length; i++) {
      updates[sorted[i].id] = TaskUpdate(sortIndex: (start + i * step).toDouble());
    }
    await _tasks.batchUpdate(updates);
  }

  /// 插入到相邻任务之间；必要时做局部重排
  Future<void> insertBetween({
    required int draggedId,
    required int beforeId,
    required int afterId,
    String? domainKey,
    int window = _window,
    double step = _step,
  }) async {
    final before = await _tasks.findById(beforeId);
    final after = await _tasks.findById(afterId);
    if (before == null || after == null) {
      throw StateError('Task not found');
    }

    final section = _sectionOf(before);
    double left = before.sortIndex;
    double right = after.sortIndex;

    if ((right - left) < _minGap) {
      // 在插入点附近做局部等差重排
      await _reindexAround(
        section: section,
        anchorBeforeId: beforeId,
        anchorAfterId: afterId,
        window: window,
        step: step,
      );
      final b2 = await _tasks.findById(beforeId);
      final a2 = await _tasks.findById(afterId);
      if (b2 == null || a2 == null) {
        throw StateError('Task not found after reindex');
      }
      left = b2.sortIndex;
      right = a2.sortIndex;
    }

    final newIndex = ((left + right) / 2).floorToDouble();
    await _tasks.updateTask(draggedId, TaskUpdate(sortIndex: newIndex));
  }

  /// 移动到区域头部
  Future<void> moveToHead({
    required int draggedId,
    required TaskSection section,
    required int firstId,
    int window = _window,
    double step = _step,
  }) async {
    final first = await _tasks.findById(firstId);
    final dragged = await _tasks.findById(draggedId);
    if (first == null || dragged == null) {
      // 区域为空或首元素缺失，赋默认
      await _tasks.updateTask(draggedId, const TaskUpdate(sortIndex: 1024));
      return;
    }
    // 若 first 与 dragged sortIndex 相等或非常接近，先规范化该区再计算
    if ((first.sortIndex - dragged.sortIndex).abs() < _minGap) {
      await normalizeSection(section: section);
      final f2 = await _tasks.findById(firstId);
      final head2 = (f2?.sortIndex ?? 1024.0) - step;
      await _tasks.updateTask(draggedId, TaskUpdate(sortIndex: head2));
      return;
    }
    final headCandidate = first.sortIndex - step;
    await _tasks.updateTask(draggedId, TaskUpdate(sortIndex: headCandidate));
  }

  /// 移动到区域尾部
  Future<void> moveToTail({
    required int draggedId,
    required TaskSection section,
    required int lastId,
    double step = _step,
  }) async {
    final last = await _tasks.findById(lastId);
    final dragged = await _tasks.findById(draggedId);
    if (last == null || dragged == null) {
      await _tasks.updateTask(draggedId, const TaskUpdate(sortIndex: 1024));
      return;
    }
    // 若 last 与 dragged sortIndex 相等或非常接近，先规范化该区再计算
    if ((last.sortIndex - dragged.sortIndex).abs() < _minGap) {
      await normalizeSection(section: section);
      final last2 = await _tasks.findById(lastId);
      final tail2 = (last2?.sortIndex ?? 1024.0) + step;
      await _tasks.updateTask(draggedId, TaskUpdate(sortIndex: tail2));
      return;
    }
    final tail = last.sortIndex + step;
    await _tasks.updateTask(draggedId, TaskUpdate(sortIndex: tail));
  }

  /// 对一个区域做规范化（按当前顺序等差赋值）
  ///
  /// 使用统一的排序规则：Tasks页面使用 dueAt升序 → sortIndex升序 → createdAt降序
  Future<void> normalizeSection({
    required TaskSection section,
    double start = 1024,
    double step = _step,
  }) async {
    final tasks = await _tasks.listSectionTasks(section);
    if (tasks.isEmpty) return;
    // 使用统一的排序函数：Tasks页面的排序规则
    final ordered = List<Task>.from(tasks);
    sortTasksForTasksPage(ordered);
    final updates = <int, TaskUpdate>{};
    for (int i = 0; i < ordered.length; i++) {
      updates[ordered[i].id] = TaskUpdate(sortIndex: (start + i * step).toDouble());
    }
    await _tasks.batchUpdate(updates);
  }

  // —— 内部实现 ——

  Future<void> _reindexAround({
    required TaskSection section,
    required int anchorBeforeId,
    required int anchorAfterId,
    required int window,
    required double step,
  }) async {
    final tasks = await _tasks.listSectionTasks(section);
    if (tasks.isEmpty) return;
    final idxBefore = tasks.indexWhere((t) => t.id == anchorBeforeId);
    final idxAfter = tasks.indexWhere((t) => t.id == anchorAfterId);
    if (idxBefore == -1 || idxAfter == -1) return;

    final start = (idxBefore - window).clamp(0, tasks.length - 1);
    final end = (idxAfter + window).clamp(0, tasks.length - 1);
    final updates = <int, TaskUpdate>{};
    double base = 1024.0;
    for (int i = start; i <= end; i++) {
      updates[tasks[i].id] = TaskUpdate(sortIndex: base);
      base += step;
    }
    await _tasks.batchUpdate(updates);
  }

  // 已不再使用的方法移除，避免未引用告警

  TaskSection _sectionOf(Task task) {
    final now = _clock();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final dayAfterTomorrowStart = tomorrowStart.add(const Duration(days: 1));
    final nextMondayStart = _getNextMonday(todayStart);
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);

    final due = task.dueAt;
    if (due == null) return TaskSection.later; // 兜底
    if (due.isBefore(todayStart)) return TaskSection.overdue;
    if (due.isBefore(tomorrowStart)) return TaskSection.today;
    if (due.isBefore(dayAfterTomorrowStart)) return TaskSection.tomorrow;
    if (due.isBefore(nextMondayStart)) return TaskSection.thisWeek;
    if (due.isBefore(nextMonthStart)) return TaskSection.thisMonth;
    return TaskSection.later;
  }

  DateTime _getNextMonday(DateTime today) {
    final daysUntilNextMonday = (DateTime.monday - today.weekday + 7) % 7;
    return today.add(Duration(days: daysUntilNextMonday == 0 ? 7 : daysUntilNextMonday));
  }
}


