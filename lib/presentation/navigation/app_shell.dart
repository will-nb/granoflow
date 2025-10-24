import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:granoflow/generated/l10n/app_localizations.dart';

import '../../core/providers/app_providers.dart';
import '../achievements/achievements_page.dart';
import '../home/home_page.dart';
import '../inbox/inbox_page.dart';
import '../tasks/task_list_page.dart';
import '../completion_management/completed_page.dart';
import '../completion_management/trash_page.dart';
import '../widgets/create_task_dialog.dart';
import 'settings_controls.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const List<Widget> _pages = <Widget>[
    HomePage(),
    TaskListPage(),
    AchievementsPage(),
    SettingsControlsPage(),
  ];

  // 使用GlobalKey来访问Scaffold
  static final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _getCurrentPageTitle(BuildContext context, int selectedIndex) {
    final l10n = AppLocalizations.of(context);
    final destinations = NavigationDestinations.values;
    if (selectedIndex >= 0 && selectedIndex < destinations.length) {
      switch (destinations[selectedIndex]) {
        case NavigationDestinations.home:
          return l10n.appShellHome; // 使用导航标题而不是问候语
        case NavigationDestinations.tasks:
          return l10n.taskListTitle;
        case NavigationDestinations.achievements:
          return l10n.appShellAchievements;
        case NavigationDestinations.settings:
          return l10n.navSettingsSectionTitle;
      }
    }
    return 'GranoFlow'; // 默认标题
  }

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

        return Scaffold(
          key: _scaffoldKey,
            body: Column(
              children: [
                // 顶部菜单栏
                SafeArea(
                  child: Container(
                    height: 56, // 标准AppBar高度
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // 左侧菜单按钮
                        IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () {
                            _scaffoldKey.currentState?.openDrawer();
                          },
                        ),
                        // 中间标题
                        Expanded(
                          child: Center(
                            child: Text(
                              _getCurrentPageTitle(context, selectedIndex),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        // 右侧头像按钮
                        IconButton(
                          icon: const CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person, size: 20, color: Colors.white),
                          ),
                          onPressed: () {
                            _scaffoldKey.currentState?.openEndDrawer();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // 主要内容区域
                Expanded(child: content),
              ],
            ),
            bottomNavigationBar: navigationWidget,
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const CreateTaskDialog(),
                );
              },
              child: const Icon(Icons.add),
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
            drawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    child: Text(
                      'GranoFlow',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.inbox),
                    title: const Text('收集箱'),
                    onTap: () {
                      // TODO: 导航到收集箱
                      Navigator.of(context).pop();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.checklist),
                    title: const Text('任务'),
                    onTap: () {
                      // TODO: 导航到任务
                      Navigator.of(context).pop();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.task_alt),
                    title: const Text('已完成'),
                    onTap: () {
                      // TODO: 导航到已完成
                      Navigator.of(context).pop();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.archive),
                    title: const Text('已归档'),
                    onTap: () {
                      // TODO: 导航到已归档
                      Navigator.of(context).pop();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('垃圾箱'),
                    onTap: () {
                      // TODO: 导航到垃圾箱
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
            endDrawer: Drawer(
              child: const SettingsControlsPage(),
            ),
          );
      },
    );
  }
}

enum NavigationDestinations {
  home,
  tasks,
  achievements,
  settings;

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

  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case NavigationDestinations.home:
        return l10n.appShellHome;
      case NavigationDestinations.tasks:
        return l10n.appShellTasks;
      case NavigationDestinations.achievements:
        return l10n.appShellAchievements;
      case NavigationDestinations.settings:
        return l10n.appShellSettings;
    }
  }
}
