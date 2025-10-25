import 'package:flutter/material.dart';

/// 统一的页面顶部导航栏组件
/// 提供主菜单按钮、动态标题和操作按钮
class PageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PageAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showMenuButton = true,
    this.automaticallyImplyLeading = false,
  });

  /// 导航栏标题
  final String title;
  
  /// 右侧操作按钮列表
  final List<Widget>? actions;
  
  /// 是否显示左侧主菜单按钮
  final bool showMenuButton;
  
  /// 是否自动显示返回按钮
  final bool automaticallyImplyLeading;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: _buildLeading(context),
      actions: actions ?? [],
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      elevation: 1,
      centerTitle: true,
    );
  }

  /// 构建左侧按钮
  Widget? _buildLeading(BuildContext context) {
    if (automaticallyImplyLeading) {
      return null; // 让AppBar自动处理返回按钮
    }
    if (showMenuButton) {
      return Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: '打开主菜单',
        ),
      );
    }
    return null;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
