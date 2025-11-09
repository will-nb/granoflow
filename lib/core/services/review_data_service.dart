import '../../data/models/review_data.dart';
import '../../data/models/task.dart';
import '../../data/repositories/focus_session_repository.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/task_repository.dart';

/// 回顾页面数据查询服务
/// 封装所有回顾页面的数据查询逻辑
class ReviewDataService {
  ReviewDataService({
    required TaskRepository taskRepository,
    required ProjectRepository projectRepository,
    required FocusSessionRepository focusSessionRepository,
  })  : _taskRepository = taskRepository,
        _projectRepository = projectRepository,
        _focusSessionRepository = focusSessionRepository;

  final TaskRepository _taskRepository;
  final ProjectRepository _projectRepository;
  final FocusSessionRepository _focusSessionRepository;

  /// 一次性加载所有回顾数据
  Future<ReviewData> loadAllReviewData() async {
    // 并行加载所有数据
    final results = await Future.wait([
      calculateDayCount(),
      calculateStats(),
      getActiveProjects(),
      getStandaloneTasks(),
      findLongestCompletedTask(),
      findLongestArchivedTask(),
      findMostCompletedDay(),
    ]);

    return ReviewData(
      welcome: ReviewWelcomeData(dayCount: results[0] as int),
      stats: results[1] as ReviewStatsData,
      projects: results[2] as List<ReviewProjectInfo>,
      standaloneTasks: results[3] as ReviewStandaloneTasksData,
      longestCompletedTask: results[4] as ReviewLongestTaskInfo?,
      longestArchivedTask: results[5] as ReviewLongestTaskInfo?,
      mostCompletedDay: results[6] as ReviewMostCompletedDayInfo?,
    );
  }

  /// 计算使用天数
  /// 从新建日期最早的 task 创建时间算起
  Future<int> calculateDayCount() async {
    final allTasks = await _taskRepository.listAll();
    
    if (allTasks.isEmpty) {
      return 1;
    }

    // 找到创建时间最早的任务
    final earliestTask = allTasks.reduce((a, b) {
      return a.createdAt.isBefore(b.createdAt) ? a : b;
    });

    final now = DateTime.now();
    final difference = now.difference(earliestTask.createdAt);
    final days = difference.inDays;

    // 至少显示为第1天
    return days < 1 ? 1 : days + 1;
  }

  /// 计算统计信息
  Future<ReviewStatsData> calculateStats() async {
    final allProjects = await _projectRepository.listAll();
    final allTasks = await _taskRepository.listAll();

    // 过滤项目：排除 trashed 状态
    final projectCount = allProjects
        .where((project) => project.status != TaskStatus.trashed)
        .length;

    // 过滤任务：排除 trashed 状态，只统计根任务（parentId == null）
    final taskCount = allTasks
        .where((task) =>
            task.status != TaskStatus.trashed &&
            task.parentId == null)
        .length;

    return ReviewStatsData(
      projectCount: projectCount,
      taskCount: taskCount,
    );
  }

  /// 获取活跃项目列表
  /// 返回正在进行中的项目（status 为 pending 或 doing，排除 trashed）
  Future<List<ReviewProjectInfo>> getActiveProjects() async {
    final allProjects = await _projectRepository.listAll();
    final allTasks = await _taskRepository.listAll();

    // 过滤活跃项目：status 为 pending 或 doing，排除 trashed
    final activeProjects = allProjects.where((project) {
      return project.status != TaskStatus.trashed &&
          (project.status == TaskStatus.pending ||
              project.status == TaskStatus.doing);
    }).toList();

    // 按截止日期和创建时间排序
    activeProjects.sort((a, b) {
      if (a.dueAt != null && b.dueAt != null) {
        final dueCompare = a.dueAt!.compareTo(b.dueAt!);
        if (dueCompare != 0) return dueCompare;
      } else if (a.dueAt != null) {
        return -1;
      } else if (b.dueAt != null) {
        return 1;
      }
      return a.createdAt.compareTo(b.createdAt);
    });

    // 计算每个项目的任务数量
    final projectInfos = <ReviewProjectInfo>[];
    for (final project in activeProjects) {
      // 统计该项目下的根任务数量（排除 trashed，只统计根任务）
        final taskCount = allTasks
            .where((task) =>
                task.projectId == project.id &&
                task.status != TaskStatus.trashed &&
                task.parentId == null)
            .length;

      projectInfos.add(ReviewProjectInfo(
          projectId: project.id,
        name: project.title,
        taskCount: taskCount,
      ));
    }

    return projectInfos;
  }

  /// 获取独立任务统计
  /// 独立任务：没有列入项目的根任务（projectId 为 null 或空，且 parentId == null）
  Future<ReviewStandaloneTasksData> getStandaloneTasks() async {
    final allTasks = await _taskRepository.listAll();

    // 过滤独立任务：projectId 为 null 或空，且 parentId == null，排除 trashed
    final standaloneTasks = allTasks.where((task) {
      return task.status != TaskStatus.trashed &&
          (task.projectId == null || task.projectId!.isEmpty) &&
          task.parentId == null;
    }).toList();

    final totalCount = standaloneTasks.length;
    final activeCount = standaloneTasks
        .where((task) =>
            task.status == TaskStatus.pending ||
            task.status == TaskStatus.doing)
        .length;
    final completedCount = standaloneTasks
        .where((task) => task.status == TaskStatus.completedActive)
        .length;
    final archivedCount = standaloneTasks
        .where((task) => task.status == TaskStatus.archived)
        .length;

    return ReviewStandaloneTasksData(
      totalCount: totalCount,
      activeCount: activeCount,
      completedCount: completedCount,
      archivedCount: archivedCount,
    );
  }

  /// 查找最长已完成任务
  /// 返回执行时间最长的已完成任务（status == completedActive，排除 trashed）
  /// 如果多个任务时间相同，选择创建时间最早的
  Future<ReviewLongestTaskInfo?> findLongestCompletedTask() async {
    final allTasks = await _taskRepository.listAll();

    // 过滤已完成任务：status == completedActive，只统计根任务
    final completedTasks = allTasks.where((task) {
      return task.status == TaskStatus.completedActive &&
          task.parentId == null;
    }).toList();

    if (completedTasks.isEmpty) {
      return null;
    }

    // 批量查询所有任务的时间
    final taskIds = completedTasks.map((task) => task.id).toList();
    final timeMap = await _focusSessionRepository.totalMinutesForTasks(taskIds);

    // 找到时间最长的任务
    Task? longestTask;
    int maxMinutes = 0;

    for (final task in completedTasks) {
      final minutes = timeMap[task.id] ?? 0;
      if (minutes > maxMinutes ||
          (minutes == maxMinutes &&
              longestTask != null &&
              task.createdAt.isBefore(longestTask.createdAt))) {
        maxMinutes = minutes;
        longestTask = task;
      }
    }

    if (longestTask == null) {
      return null;
    }

    // 查询最长任务的子任务
    final subtasks = await _taskRepository.listChildren(longestTask.id);

    return ReviewLongestTaskInfo(
      task: longestTask,
      totalMinutes: maxMinutes,
      subtasks: subtasks,
    );
  }

  /// 查找最长归档任务
  /// 返回执行时间最长的归档任务（status == archived，排除 trashed）
  /// 如果多个任务时间相同，选择创建时间最早的
  Future<ReviewLongestTaskInfo?> findLongestArchivedTask() async {
    final allTasks = await _taskRepository.listAll();

    // 过滤归档任务：status == archived，只统计根任务
    final archivedTasks = allTasks.where((task) {
      return task.status == TaskStatus.archived &&
          task.parentId == null;
    }).toList();

    if (archivedTasks.isEmpty) {
      return null;
    }

    // 批量查询所有任务的时间
    final taskIds = archivedTasks.map((task) => task.id).toList();
    final timeMap = await _focusSessionRepository.totalMinutesForTasks(taskIds);

    // 找到时间最长的任务
    ReviewLongestTaskInfo? longestTaskInfo;
    int maxMinutes = 0;

    for (final task in archivedTasks) {
      final minutes = timeMap[task.id] ?? 0;
      if (minutes > maxMinutes ||
          (minutes == maxMinutes &&
              longestTaskInfo != null &&
              task.createdAt.isBefore(longestTaskInfo.task.createdAt))) {
        maxMinutes = minutes;
        longestTaskInfo = ReviewLongestTaskInfo(
          task: task,
          totalMinutes: minutes,
          subtasks: const [], // 归档任务不显示子任务
        );
      }
    }

    return longestTaskInfo;
  }

  /// 查找完成根任务最多的一天
  /// 返回完成根任务数量最多的日期，如果数量相同，选择总时间最长的日期
  Future<ReviewMostCompletedDayInfo?> findMostCompletedDay() async {
    final allTasks = await _taskRepository.listAll();

    // 过滤已完成任务：status == completedActive，只统计根任务，必须有 endedAt
    final completedTasks = allTasks.where((task) {
      return task.status == TaskStatus.completedActive &&
          task.parentId == null &&
          task.endedAt != null;
    }).toList();

    if (completedTasks.isEmpty) {
      return null;
    }

    // 按完成日期（endedAt 的本地日期）分组
    final Map<DateTime, List<Task>> tasksByDate = {};
    for (final task in completedTasks) {
      final date = DateTime(
        task.endedAt!.year,
        task.endedAt!.month,
        task.endedAt!.day,
      );
      tasksByDate.putIfAbsent(date, () => []).add(task);
    }

    // 批量查询所有任务的时间
    final taskIds = completedTasks.map((task) => task.id).toList();
    final timeMap = await _focusSessionRepository.totalMinutesForTasks(taskIds);

    // 找到任务数量最多的日期，如果数量相同，选择总时间最长的日期
    DateTime? mostCompletedDate;
    int maxTaskCount = 0;
    double maxTotalHours = 0;

    for (final entry in tasksByDate.entries) {
      final date = entry.key;
      final tasks = entry.value;
      final taskCount = tasks.length;

      // 计算总时间（小时）
      double totalHours = 0;
      for (final task in tasks) {
        final minutes = timeMap[task.id] ?? 0;
        totalHours += minutes / 60;
      }

      // 判断是否是最多完成日
      if (taskCount > maxTaskCount ||
          (taskCount == maxTaskCount && totalHours > maxTotalHours)) {
        maxTaskCount = taskCount;
        maxTotalHours = totalHours;
        mostCompletedDate = date;
      }
    }

    if (mostCompletedDate == null) {
      return null;
    }

    return ReviewMostCompletedDayInfo(
      date: mostCompletedDate,
      taskCount: maxTaskCount,
      totalHours: maxTotalHours,
    );
  }
}

