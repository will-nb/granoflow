import 'package:flutter/material.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';

/// 导航目标枚举
/// 定义应用中所有可导航的目标页面
enum NavigationDestinations {
  home,
  tasks,
  achievements,
  settings;

  /// 获取未选中状态的图标
  IconData get icon {
    switch (this) {
      case NavigationDestinations.home:
        return Icons.home_outlined;
      case NavigationDestinations.tasks:
        return Icons.checklist;
      case NavigationDestinations.achievements:
        return Icons.emoji_events_outlined;
      case NavigationDestinations.settings:
        return Icons.settings_outlined;
    }
  }

  /// 获取选中状态的图标
  IconData get selectedIcon {
    switch (this) {
      case NavigationDestinations.home:
        return Icons.home;
      case NavigationDestinations.tasks:
        return Icons.fact_check;
      case NavigationDestinations.achievements:
        return Icons.emoji_events;
      case NavigationDestinations.settings:
        return Icons.settings;
    }
  }

  /// 获取路由路径
  String get route {
    switch (this) {
      case NavigationDestinations.home:
        return '/';
      case NavigationDestinations.tasks:
        return '/tasks';
      case NavigationDestinations.achievements:
        return '/achievements';
      case NavigationDestinations.settings:
        return '/settings';
    }
  }

  /// 获取本地化标签
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case NavigationDestinations.home:
        return l10n.appShellHome;
      case NavigationDestinations.tasks:
        return l10n.taskListTitle;
      case NavigationDestinations.achievements:
        return l10n.appShellAchievements;
      case NavigationDestinations.settings:
        return l10n.navSettingsSectionTitle;
    }
  }
}