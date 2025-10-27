import 'package:flutter/material.dart';
import '../../core/theme/ocean_breeze_color_schemes.dart';
import 'swipe_action_config.dart';
import 'swipe_action_type.dart';

/// 滑动配置预设
/// 
/// 提供不同页面的预配置滑动行为
class SwipeConfigs {
  /// Inbox页面的滑动配置
  /// 左滑：删除到回收站（危险操作），右滑：快速规划到今日（推荐操作）
  static const SwipeActionConfig inboxConfig = SwipeActionConfig(
    leftAction: SwipeActionType.delete,
    rightAction: SwipeActionType.quickPlan,
    leftHintKey: 'inboxDeleteAction',
    rightHintKey: 'inboxQuickPlanAction',
    leftIcon: Icons.delete,
    rightIcon: Icons.today,
    leftColor: OceanBreezeColorSchemes.errorDark,
    rightColor: OceanBreezeColorSchemes.softGreen,
  );

  /// Tasks页面的滑动配置
  /// 左滑：智能推迟（安全操作），右滑：归档任务（警告操作）
  static const SwipeActionConfig tasksConfig = SwipeActionConfig(
    leftAction: SwipeActionType.postpone,
    rightAction: SwipeActionType.archive,
    leftHintKey: 'taskPostponeAction',
    rightHintKey: 'taskArchiveAction',
    leftIcon: Icons.schedule,
    rightIcon: Icons.archive,
    leftColor: OceanBreezeColorSchemes.softGreen,
    rightColor: OceanBreezeColorSchemes.softPink,
  );
}
