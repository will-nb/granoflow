import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 项目状态筛选枚举
/// 用于项目页面的状态筛选功能
enum ProjectFilterStatus {
  /// 全部 - 显示所有状态的项目
  all,

  /// 活跃 - 显示pending/doing状态的项目（默认选中）
  active,

  /// 已完成 - 显示completedActive状态的项目
  completed,

  /// 已归档 - 显示archived状态的项目
  archived,

  /// 回收站 - 显示trashed状态的项目
  trash,
}

/// 项目状态筛选Provider
/// 管理当前选中的项目状态筛选
final projectFilterStatusProvider = StateProvider<ProjectFilterStatus>(
  (ref) => ProjectFilterStatus.active,
);

