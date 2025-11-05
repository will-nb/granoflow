import 'package:flutter/material.dart';

/// 自定义 FAB 位置
/// 将 FAB 嵌入导航栏，水平左边缘对齐第 3 个槽位，垂直顶部对齐图标顶部
/// 支持传入 NavigationBar 的实际宽度，确保槽位宽度与 NavigationBar 按钮槽位一致
class CustomFloatingActionButtonLocation extends FloatingActionButtonLocation {
  final double? navBarWidth;

  const CustomFloatingActionButtonLocation({this.navBarWidth});

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // 水平位置：FAB 左边缘对齐第 3 个槽位（索引 2）的左边缘
    // 使用传入的 NavigationBar 宽度，如果没有则使用屏幕宽度
    const int fabSlotIndex = 2; // FAB 在第三个槽位（从 0 开始）
    const int totalSlots = 5; // 总共 5 个槽位
    final double screenWidth = scaffoldGeometry.scaffoldSize.width;
    final double effectiveWidth = navBarWidth ?? screenWidth;
    final double slotWidth = effectiveWidth / totalSlots;
    final double fabX = slotWidth * fabSlotIndex;

    // 垂直位置：FAB 顶部与 NavigationBar 按钮图标顶部对齐
    // 根据测试结果：图标顶部在 contentBottom + 约 17dp 的位置
    const double iconTopPadding = 17.0;
    final double fabY = scaffoldGeometry.contentBottom + iconTopPadding;

    return Offset(fabX, fabY);
  }
}
