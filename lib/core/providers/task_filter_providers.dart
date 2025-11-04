import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 通用任务筛选状态
/// 
/// 包含标签筛选和项目筛选的所有字段
@immutable
class TaskFilterState {
  const TaskFilterState({
    this.contextTag,
    this.priorityTag,
    this.urgencyTag,
    this.importanceTag,
    this.projectId,
    this.milestoneId,
    this.showNoProject = false,
  });

  /// 场景标签筛选
  final String? contextTag;
  
  /// 优先级标签筛选（保留，用于兼容，实际使用urgencyTag和importanceTag）
  @Deprecated('使用urgencyTag和importanceTag替代')
  final String? priorityTag;
  
  /// 紧急度标签筛选
  final String? urgencyTag;
  
  /// 重要度标签筛选
  final String? importanceTag;
  
  /// 项目ID筛选
  final String? projectId;
  
  /// 里程碑ID筛选（仅在projectId不为空时有效）
  final String? milestoneId;
  
  /// 是否只显示无项目的任务
  final bool showNoProject;

  bool get hasFilters =>
      (contextTag != null && contextTag!.isNotEmpty) ||
      // priorityTag 已废弃，不再用于筛选检查
      (urgencyTag != null && urgencyTag!.isNotEmpty) ||
      (importanceTag != null && importanceTag!.isNotEmpty) ||
      (projectId != null && projectId!.isNotEmpty) ||
      (milestoneId != null && milestoneId!.isNotEmpty) ||
      showNoProject;

  TaskFilterState copyWith({
    String? contextTag,
    @Deprecated('使用urgencyTag和importanceTag替代')
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  }) {
    // ignore: deprecated_member_use_from_same_package
    return TaskFilterState(
      contextTag: contextTag ?? this.contextTag,
      // ignore: deprecated_member_use_from_same_package
      priorityTag: priorityTag ?? this.priorityTag,
      urgencyTag: urgencyTag ?? this.urgencyTag,
      importanceTag: importanceTag ?? this.importanceTag,
      projectId: projectId ?? this.projectId,
      milestoneId: milestoneId ?? this.milestoneId,
      showNoProject: showNoProject ?? this.showNoProject,
    );
  }

  @override
  bool operator ==(Object other) {
    // ignore: deprecated_member_use_from_same_package
    return other is TaskFilterState &&
        other.contextTag == contextTag &&
        // ignore: deprecated_member_use_from_same_package
        other.priorityTag == priorityTag &&
        other.urgencyTag == urgencyTag &&
        other.importanceTag == importanceTag &&
        other.projectId == projectId &&
        other.milestoneId == milestoneId &&
        other.showNoProject == showNoProject;
  }

  @override
  int get hashCode => Object.hash(
        contextTag,
        // ignore: deprecated_member_use_from_same_package
        priorityTag,
        urgencyTag,
        importanceTag,
        projectId,
        milestoneId,
        showNoProject,
      );
}

/// 通用任务筛选Notifier
class TaskFilterNotifier extends StateNotifier<TaskFilterState> {
  TaskFilterNotifier() : super(const TaskFilterState());

  void setContextTag(String? tag) {
    final normalized = (tag != null && tag.isEmpty) ? null : tag;
    if (state.contextTag == normalized) {
      return;
    }
    state = state.copyWith(contextTag: normalized);
  }

  @Deprecated('使用urgencyTag和importanceTag替代')
  void setPriorityTag(String? tag) {
    final normalized = (tag != null && tag.isEmpty) ? null : tag;
    if (state.priorityTag == normalized) {
      return;
    }
    state = state.copyWith(priorityTag: normalized);
  }

  void setUrgencyTag(String? tag) {
    final normalized = (tag != null && tag.isEmpty) ? null : tag;
    if (state.urgencyTag == normalized) {
      return;
    }
    state = state.copyWith(urgencyTag: normalized);
  }

  void setImportanceTag(String? tag) {
    final normalized = (tag != null && tag.isEmpty) ? null : tag;
    if (state.importanceTag == normalized) {
      return;
    }
    state = state.copyWith(importanceTag: normalized);
  }

  void setProjectId(String? projectId) {
    if (state.projectId == projectId) {
      return;
    }
    // 如果切换项目，清除里程碑筛选
    state = state.copyWith(
      projectId: projectId,
      milestoneId: projectId == null ? null : state.milestoneId,
      showNoProject: false, // 选择项目时，关闭"无项目"筛选
    );
  }

  void setMilestoneId(String? milestoneId) {
    if (state.milestoneId == milestoneId) {
      return;
    }
    state = state.copyWith(milestoneId: milestoneId);
  }

  void toggleShowNoProject() {
    state = state.copyWith(
      showNoProject: !state.showNoProject,
      projectId: state.showNoProject ? state.projectId : null, // 开启"无项目"时，清除项目筛选
      milestoneId: state.showNoProject ? state.milestoneId : null,
    );
  }

  void reset() {
    state = const TaskFilterState();
  }
}

/// Inbox筛选状态（向后兼容）
/// 
/// 作为TaskFilterState的别名，保持向后兼容
@Deprecated('使用TaskFilterState替代')
typedef InboxFilterState = TaskFilterState;

/// Inbox筛选Notifier（向后兼容）
/// 
/// 继承TaskFilterNotifier，保持向后兼容
class InboxFilterNotifier extends TaskFilterNotifier {
  InboxFilterNotifier() : super();
}

/// Inbox筛选Provider（向后兼容）
/// 
/// 继续使用InboxFilterNotifier和InboxFilterState，但内部实现使用通用类
final inboxFilterProvider =
    StateNotifierProvider<InboxFilterNotifier, TaskFilterState>((ref) {
      return InboxFilterNotifier();
    });

/// 已完成任务筛选Provider
final completedTasksFilterProvider =
    StateNotifierProvider<TaskFilterNotifier, TaskFilterState>((ref) {
      return TaskFilterNotifier();
    });

/// 已归档任务筛选Provider
final archivedTasksFilterProvider =
    StateNotifierProvider<TaskFilterNotifier, TaskFilterState>((ref) {
      return TaskFilterNotifier();
    });

/// 已删除任务筛选Provider
final trashedTasksFilterProvider =
    StateNotifierProvider<TaskFilterNotifier, TaskFilterState>((ref) {
      return TaskFilterNotifier();
    });

/// 任务页面筛选Provider
final tasksFilterProvider =
    StateNotifierProvider<TaskFilterNotifier, TaskFilterState>((ref) {
      return TaskFilterNotifier();
    });

