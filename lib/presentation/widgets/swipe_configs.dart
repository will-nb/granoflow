import 'package:flutter/material.dart';
import '../../core/theme/ocean_breeze_color_schemes.dart';
import 'swipe_action_config.dart';
import 'swipe_action_type.dart';

/// 滑动配置预设
/// 
/// 提供不同页面的预配置滑动行为
class SwipeConfigs {
  /// Inbox页面的滑动配置
  /// 方向规范（极其重要，禁止随意改动）：
  /// - 本项目遵循 iOS HIG/Material 约定：破坏性操作放在 trailing（左滑 endToStart）侧；
  /// - 非破坏性高频操作放在 leading（右滑 startToEnd，LTR 环境）侧；
  /// - Dismissible 映射（在 LTR 下）：startToEnd=右滑（显示左侧背景），endToStart=左滑（显示右侧背景）。
  /// 因此，Inbox 的手势定义为：
  /// - 右滑（startToEnd，常用/安全）= 快速加入今日（quickPlan，绿色）
  /// - 左滑（endToStart，危险）= 移动到回收站（delete，红色）
  /// 注意：请勿反转！这是与 Tasks 页面一致的既定产品规范，任何修改都需产品评审确认。
  static const SwipeActionConfig inboxConfig = SwipeActionConfig(
    leftAction: SwipeActionType.quickPlan,
    rightAction: SwipeActionType.delete,
    leftHintKey: 'inboxQuickPlanAction',
    rightHintKey: 'inboxDeleteAction',
    leftIcon: Icons.today,
    rightIcon: Icons.delete,
    leftColor: OceanBreezeColorSchemes.softGreen,
    rightColor: OceanBreezeColorSchemes.errorDark,
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

  /// Inbox页面子任务的滑动配置
  /// 方向规范：与 inboxConfig 保持一致
  /// - 右滑（startToEnd，常用/安全）= 提升为独立任务（promoteToIndependent，绿色）
  /// - 左滑（endToStart，危险）= 移动到回收站（delete，红色）
  static const SwipeActionConfig inboxSubtaskConfig = SwipeActionConfig(
    leftAction: SwipeActionType.promoteToIndependent,
    rightAction: SwipeActionType.delete,
    leftHintKey: 'actionPromoteToIndependent',
    rightHintKey: 'inboxDeleteAction',
    leftIcon: Icons.arrow_upward,
    rightIcon: Icons.delete,
    leftColor: OceanBreezeColorSchemes.softGreen,
    rightColor: OceanBreezeColorSchemes.errorDark,
  );
}
