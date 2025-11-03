import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';

/// 侧边栏导航目标
enum SidebarDestinations {
  /// 收集箱
  inbox(Icons.inbox, '/inbox'),
  /// 任务清单
  taskList(Icons.list_alt, '/tasks'),
  /// 已完成
  completed(Icons.check_circle, '/completed'),
  /// 已归档
  archived(Icons.archive, '/archived'),
  /// 垃圾箱
  trash(Icons.delete, '/trash');

  const SidebarDestinations(this.icon, this.route);

  final IconData icon;
  final String route;

  /// 获取本地化标签
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case SidebarDestinations.inbox:
        return l10n.inbox;
      case SidebarDestinations.taskList:
        return l10n.taskListTitle;
      case SidebarDestinations.completed:
        return l10n.completedTabLabel;
      case SidebarDestinations.archived:
        return l10n.archivedTabLabel;
      case SidebarDestinations.trash:
        return l10n.navTrashTitle;
    }
  }
}
