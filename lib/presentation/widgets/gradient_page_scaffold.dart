import 'package:flutter/material.dart';
import '../../core/theme/app_gradients.dart';

/// 带渐变背景的 Scaffold 包装器
/// 统一管理所有页面的渐变背景
class GradientPageScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Gradient? gradient;
  final bool extendBodyBehindAppBar;
  final bool extendBody;
  /// 全屏沉浸式模式（无 AppBar、无导航栏）
  final bool fullScreen;

  const GradientPageScaffold({
    super.key,
    this.appBar,
    this.drawer,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.gradient,
    this.extendBodyBehindAppBar = false,
    this.extendBody = false,
    this.fullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    // 全屏沉浸式模式：无 AppBar、无导航栏
    if (fullScreen) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: gradient ?? context.gradients.pageBackground,
          ),
          child: SafeArea(
            child: body,
          ),
        ),
      );
    }
    
    // 正常模式
    final shouldExtendBody = extendBodyBehindAppBar || drawer != null;
    final hasAppBar = appBar != null;
    
    // 当 extendBodyBehindAppBar 为 true 且存在 AppBar 时，
    // 需要计算状态栏高度 + AppBar 高度的总 padding
    double topPadding = 0;
    if (shouldExtendBody && hasAppBar) {
      final mediaQuery = MediaQuery.of(context);
      final statusBarHeight = mediaQuery.padding.top;
      final appBarHeight = appBar!.preferredSize.height;
      topPadding = statusBarHeight + appBarHeight;
    }
    
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      extendBodyBehindAppBar: shouldExtendBody,
      extendBody: extendBody,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      body: Container(
        decoration: BoxDecoration(
          gradient: gradient ?? context.gradients.pageBackground,
        ),
        child: SafeArea(
          top: shouldExtendBody && hasAppBar,
          bottom: false,
          left: false,
          right: false,
          minimum: EdgeInsets.only(
            // SafeArea 会自动处理状态栏高度，minimum 确保总 padding 至少是
            // 状态栏高度 + AppBar 高度
            top: topPadding,
          ),
          child: body,
        ),
      ),
    );
  }
}

