part of 'task_repository.dart';

/// TaskRepository 区域查询方法 mixin
/// 
/// 包含区域查询相关的私有方法
mixin TaskRepositorySectionQueries on TaskRepositoryHelpers {
  /// 获取区域对应的状态
  TaskStatus _sectionToStatus(TaskSection section) {
    switch (section) {
      case TaskSection.overdue:
      case TaskSection.today:
      case TaskSection.tomorrow:
      case TaskSection.thisWeek:
      case TaskSection.thisMonth:
      case TaskSection.nextMonth:
      case TaskSection.later:
        return TaskStatus.pending;
      case TaskSection.completed:
        return TaskStatus.completedActive;
      case TaskSection.archived:
        return TaskStatus.archived;
      case TaskSection.trash:
        return TaskStatus.trashed;
    }
  }

  /// 获取指定区域的任务列表
  /// 
  /// 使用 TaskSectionUtils 统一边界定义（严禁修改）
  /// 边界定义见 TaskSectionUtils 文件顶部的注释
  Future<List<Task>> _fetchSection(TaskSection section) async {
    final now = _clock();

    // 使用 TaskSectionUtils 统一边界定义（严禁修改）
    // 边界定义见 TaskSectionUtils 文件顶部的注释
    final sectionStart = TaskSectionUtils.getSectionStartTime(section, now: now);
    final sectionEnd = TaskSectionUtils.getSectionEndTimeForQuery(section, now: now);

    List<TaskEntity> results;
    
    switch (section) {
      case TaskSection.overdue:
        // 已逾期：[~, <今天00:00:00)
        // 使用 dueAtLessThan 而不是 dueAtBetween，因为 overdue 没有明确的开始时间
        final todayStart = DateTime(now.year, now.month, now.day);
        results = await _isar.taskEntitys
            .filter()
            .statusEqualTo(TaskStatus.pending)
            .dueAtLessThan(todayStart, include: false)
            .findAll();
        break;
      case TaskSection.today:
        // 今天：[>=今天00:00:00, <明天00:00:00)
        results = await _isar.taskEntitys
            .filter()
            .statusEqualTo(TaskStatus.pending)
            .dueAtBetween(sectionStart, sectionEnd, includeUpper: false)
            .findAll();
        break;
      case TaskSection.tomorrow:
        // 明天：[>=明天00:00:00, <后天00:00:00)
        results = await _isar.taskEntitys
            .filter()
            .statusEqualTo(TaskStatus.pending)
            .dueAtBetween(sectionStart, sectionEnd, includeUpper: false)
            .findAll();
        break;
      case TaskSection.thisWeek:
        // 本周：[>=后天00:00:00, <下周日00:00:00) （如果今天是周六，则为空范围）
        // 检查是否为空范围：如果开始时间 >= 结束时间，则为空范围
        if (sectionStart.isBefore(sectionEnd)) {
          results = await _isar.taskEntitys
              .filter()
              .statusEqualTo(TaskStatus.pending)
              .dueAtBetween(sectionStart, sectionEnd, includeUpper: false)
              .findAll();
        } else {
          // 空范围：使用一个永远为 false 的条件（dueAt 必须同时 < today 和 > today+365）
          final todayStart = DateTime(now.year, now.month, now.day);
          results = await _isar.taskEntitys
              .filter()
              .statusEqualTo(TaskStatus.pending)
              .dueAtLessThan(todayStart, include: false)
              .and()
              .dueAtGreaterThan(
                todayStart.add(const Duration(days: 365)),
                include: false,
              )
              .findAll();
        }
        break;
      case TaskSection.thisMonth:
        // 当月：[>=下周日00:00:00, <下月1日00:00:00) （如果本周跨月，则为空范围）
        // 检查是否为空范围：如果开始时间 >= 结束时间，则为空范围
        if (sectionStart.isBefore(sectionEnd)) {
          results = await _isar.taskEntitys
              .filter()
              .statusEqualTo(TaskStatus.pending)
              .dueAtBetween(sectionStart, sectionEnd, includeUpper: false)
              .findAll();
        } else {
          // 空范围：使用一个永远为 false 的条件（dueAt 必须同时 < today 和 > today+365）
          final todayStart = DateTime(now.year, now.month, now.day);
          results = await _isar.taskEntitys
              .filter()
              .statusEqualTo(TaskStatus.pending)
              .dueAtLessThan(todayStart, include: false)
              .and()
              .dueAtGreaterThan(
                todayStart.add(const Duration(days: 365)),
                include: false,
              )
              .findAll();
        }
        break;
      case TaskSection.nextMonth:
        // 下月：[>=下月1日00:00:00, <下下月1日00:00:00)
        results = await _isar.taskEntitys
            .filter()
            .statusEqualTo(TaskStatus.pending)
            .dueAtBetween(sectionStart, sectionEnd, includeUpper: false)
            .findAll();
        break;
      case TaskSection.later:
        // 以后：[>=下下月1日00:00:00, ~) 或 dueAt == null
        // 由于 Isar 的 OR 查询语法限制，需要分别查询并合并结果
        // 查询1: dueAt == null 的任务
        final nullTasks = await _isar.taskEntitys
            .filter()
            .statusEqualTo(TaskStatus.pending)
            .dueAtIsNull()
            .findAll();
        // 查询2: dueAt >= sectionStart 的任务
        final dateTasks = await _isar.taskEntitys
            .filter()
            .statusEqualTo(TaskStatus.pending)
            .dueAtGreaterThan(sectionStart, include: true)
            .findAll();
        // 合并结果并去重（按 id）
        final allTasks = <int, TaskEntity>{};
        for (final task in nullTasks) {
          allTasks[task.id] = task;
        }
        for (final task in dateTasks) {
          allTasks[task.id] = task;
        }
        results = allTasks.values.toList();
        break;
      case TaskSection.completed:
        results = await _isar.taskEntitys
            .filter()
            .statusEqualTo(TaskStatus.completedActive)
            .findAll();
        break;
      case TaskSection.archived:
        results = await _isar.taskEntitys
            .filter()
            .statusEqualTo(TaskStatus.archived)
            .findAll();
        break;
      case TaskSection.trash:
        results = await _isar.taskEntitys
            .filter()
            .statusEqualTo(TaskStatus.trashed)
            .findAll();
        break;
    }

    // CRITICAL FIX: Removed _filterLeafTasks() call to support parent task display
    //
    // Problem: The original code called _filterLeafTasks(results) which filtered out
    // ALL tasks that have children, regardless of whether those children are in the
    // current section or not. This caused severe display issues:
    //
    // 1. Parent tasks completely disappeared from their own sections
    // 2. Parent tasks couldn't be shown with simplified headers when "following" children
    // 3. The entire task hierarchy system broke down
    //
    // Example of the bug:
    // - Parent task (id=2) due today, child task (id=1) also due today
    // - Parent has children → _filterLeafTasks removes parent from results
    // - Today section shows only child (id=1)
    // - But child's parentId=2 → UI tries to display parent header → parent not in list!
    // - Result: Empty screen because rendering fails
    //
    // Another example:
    // - Parent task due next week, child due today
    // - Today section: _filterLeafTasks removes child (it's a leaf, but parent is elsewhere)
    // - Next week: _filterLeafTasks removes parent (it has a child, even though child is elsewhere!)
    // - Result: Parent disappears completely from all sections!
    //
    // Solution: Return ALL tasks matching the date criteria. Let the UI layer handle
    // hierarchy display through:
    // - collectRoots(): Filters tasks to show roots (no parent OR parent not in list)
    // - TaskWithParentChain: Queries and displays parent headers on demand
    // - TaskTreeView: Shows parent with children when both in same section
    //
    // This separation of concerns is architecturally correct:
    // - Data layer: Returns tasks by date/status criteria (domain logic)
    // - UI layer: Handles display logic and parent-child relationships (presentation logic)
    // 移除过滤，让 tasks 页面显示所有任务（包括关联项目的）
    // Inbox 页面使用 watchInbox() 方法，它会单独过滤普通任务
    final tasks = results.map(_toDomain).toList(growable: false);

    // 在内存中排序：先按日期（不含时间）升序，再按 sortIndex 升序，最后按 createdAt 降序
    // 使用统一的排序工具函数
    tasks.sort((a, b) {
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
    });


    return tasks;
  }
}

