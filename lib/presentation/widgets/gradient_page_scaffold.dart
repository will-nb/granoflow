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
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      extendBodyBehindAppBar: extendBodyBehindAppBar || drawer != null, // 如果有 drawer 则默认扩展
      extendBody: extendBody,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      body: Container(
        decoration: BoxDecoration(
          gradient: gradient ?? context.gradients.pageBackground,
        ),
        child: body,
      ),
    );
  }
}

