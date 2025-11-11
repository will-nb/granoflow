import 'package:flutter/material.dart';

/// 自定义 FAB 位置（用于 BottomAppBar）
/// 将 FAB 居中放置在 BottomAppBar 中间，FAB 底部与其他图标底部对齐
class BottomAppBarFloatingActionButtonLocation extends FloatingActionButtonLocation {
  const BottomAppBarFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // 水平位置：FAB 居中
    final double screenWidth = scaffoldGeometry.scaffoldSize.width;
    const double fabDiameter = 48.0;
    final double fabX = (screenWidth - fabDiameter) / 2;

    // 垂直位置：FAB 底部与其他图标底部对齐
    // getOffset 返回的 Y 是从屏幕顶部算起的绝对位置
    // BottomAppBar 高度：50dp
    // 图标底部距离屏幕底部：约 10dp（根据 IconButton 的约束和 padding 计算）
    // FAB 底部应该在距离屏幕底部 10dp 的位置
    // 所以 FAB 顶部应该在距离屏幕顶部 (screenHeight - 10 - 48) 的位置
    final double screenHeight = scaffoldGeometry.scaffoldSize.height;
    const double iconBottomFromScreenBottom = 23.0; // 图标底部距离屏幕底部的距离
    final double fabY = screenHeight - iconBottomFromScreenBottom - fabDiameter;

    return Offset(fabX, fabY);
  }
}

