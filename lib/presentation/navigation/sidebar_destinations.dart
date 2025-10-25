import 'package:flutter/material.dart';

/// 侧边栏导航目标
enum SidebarDestinations {
  /// 收集箱
  inbox(Icons.inbox, '收集箱', '/inbox'),
  /// 任务清单
  taskList(Icons.list_alt, '任务清单', '/tasks'),
  /// 已完成
  completed(Icons.check_circle, '已完成', '/completed'),
  /// 已归档
  archived(Icons.archive, '已归档', '/archived'),
  /// 垃圾箱
  trash(Icons.delete, '垃圾箱', '/trash');

  const SidebarDestinations(this.icon, this.label, this.route);

  final IconData icon;
  final String label;
  final String route;
}
