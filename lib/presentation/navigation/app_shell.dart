import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:granoflow/generated/l10n/app_localizations.dart';

import '../../core/providers/app_providers.dart';
import '../home/home_page.dart';
import '../inbox/inbox_page.dart';
import '../tasks/task_list_page.dart';
import '../completion_management/completed_page.dart';
import '../completion_management/trash_page.dart';
import 'settings_controls.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const List<Widget> _pages = <Widget>[
    HomePage(),
    InboxPage(),
    TaskListPage(),
    SettingsControlsPage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);
    const navigation = NavigationDestinations.values;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 960;

        // 尝试标签页导航作为替代方案（仅用于演示）
        final showTabsDemo = false; // 设置为 true 可以看到标签页导航效果

        if (showTabsDemo) {
          return DefaultTabController(
            length: navigation.length,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('GranoFlow'),
                bottom: TabBar(
                  isScrollable: true, // 允许滚动以展示更多标签
                  tabs: navigation
                      .map(
                        (destination) => Tab(
                          icon: Icon(destination.icon),
                          text: destination.label(context),
                        ),
                      )
                      .toList(),
                ),
              ),
              body: TabBarView(
                children: _pages,
              ),
            ),
          );
        }

        final Widget navigationWidget = useRail
            ? NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) =>
                    ref.read(navigationIndexProvider.notifier).state = index,
                labelType: NavigationRailLabelType.selected,
                destinations: navigation
                    .map(
                      (destination) => NavigationRailDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: Text(destination.label(context)),
                      ),
                    )
                    .toList(),
              )
            : NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) =>
                    ref.read(navigationIndexProvider.notifier).state = index,
                destinations: navigation
                    .map(
                      (destination) => NavigationDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: destination.label(context),
                      ),
                    )
                    .toList(),
              );

        final content = IndexedStack(index: selectedIndex, children: _pages);

        if (useRail) {
          return Scaffold(
            body: Row(
              children: [
                navigationWidget,
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(body: content, bottomNavigationBar: navigationWidget);
      },
    );
  }
}

enum NavigationDestinations {
  home,
  inbox,
  tasks,
  settings;

  IconData get icon {
    switch (this) {
      case NavigationDestinations.home:
        return Icons.home_outlined;
      case NavigationDestinations.inbox:
        return Icons.inbox_outlined;
      case NavigationDestinations.tasks:
        return Icons.checklist;
      case NavigationDestinations.settings:
        return Icons.settings_outlined;
    }
  }

  IconData get selectedIcon {
    switch (this) {
      case NavigationDestinations.home:
        return Icons.home;
      case NavigationDestinations.inbox:
        return Icons.inbox;
      case NavigationDestinations.tasks:
        return Icons.fact_check;
      case NavigationDestinations.settings:
        return Icons.settings;
    }
  }

  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case NavigationDestinations.home:
        return l10n.appShellHome;
      case NavigationDestinations.inbox:
        return l10n.appShellInbox;
      case NavigationDestinations.tasks:
        return l10n.appShellTasks;
      case NavigationDestinations.settings:
        return l10n.appShellSettings;
    }
  }
}
