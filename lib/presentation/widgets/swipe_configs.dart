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
  /// 左滑：完成任务（安全操作），右滑：归档任务（警告操作）
  static const SwipeActionConfig tasksConfig = SwipeActionConfig(
    leftAction: SwipeActionType.complete,
    rightAction: SwipeActionType.archive,
    leftHintKey: 'taskCompleteAction',
    rightHintKey: 'taskArchiveAction',
    leftIcon: Icons.check_circle,
    rightIcon: Icons.archive,
    leftColor: OceanBreezeColorSchemes.softGreen,
    rightColor: OceanBreezeColorSchemes.softPink,
  );

  /// Tasks页面子任务的滑动配置
  /// 左滑：完成任务（安全操作），右滑：移动到回收站（删除操作）
  /// 用于 level > 1 的子任务
  static const SwipeActionConfig tasksSubtaskConfig = SwipeActionConfig(
    leftAction: SwipeActionType.complete,
    rightAction: SwipeActionType.delete,
    leftHintKey: 'taskCompleteAction',
    rightHintKey: 'inboxDeleteAction',
    leftIcon: Icons.check_circle,
    rightIcon: Icons.delete,
    leftColor: OceanBreezeColorSchemes.softGreen,
    rightColor: OceanBreezeColorSchemes.errorDark,
  );

  /// Tasks页面非今日区域的滑动配置
  /// 左滑：移动到今日（quickPlan，安全操作），右滑：归档任务（警告操作）
  /// 用于非今日区域的根任务（本周、本月、下月、以后、已逾期）
  static const SwipeActionConfig tasksNonTodayConfig = SwipeActionConfig(
    leftAction: SwipeActionType.quickPlan,
    rightAction: SwipeActionType.archive,
    leftHintKey: 'inboxQuickPlanAction',
    rightHintKey: 'taskArchiveAction',
    leftIcon: Icons.today,
    rightIcon: Icons.archive,
    leftColor: OceanBreezeColorSchemes.softGreen,
    rightColor: OceanBreezeColorSchemes.softPink,
  );

  /// Tasks页面非今日区域子任务的滑动配置
  /// 左滑：移动到今日（quickPlan，安全操作），右滑：移动到回收站（删除操作）
  /// 用于非今日区域的子任务（level > 1）
  static const SwipeActionConfig tasksNonTodaySubtaskConfig = SwipeActionConfig(
    leftAction: SwipeActionType.quickPlan,
    rightAction: SwipeActionType.delete,
    leftHintKey: 'inboxQuickPlanAction',
    rightHintKey: 'inboxDeleteAction',
    leftIcon: Icons.today,
    rightIcon: Icons.delete,
    leftColor: OceanBreezeColorSchemes.softGreen,
    rightColor: OceanBreezeColorSchemes.errorDark,
  );

  /// 已完成/已归档页面的滑动配置
  /// 方向规范：与 inboxConfig 保持一致
  /// - 右滑（startToEnd，常用/安全）= 加入今日任务（quickPlan，绿色）
  /// - 左滑（endToStart，危险）= 移动到回收站（delete，红色）
  static const SwipeActionConfig completedArchivedConfig = SwipeActionConfig(
    leftAction: SwipeActionType.quickPlan,
    rightAction: SwipeActionType.delete,
    leftHintKey: 'completedQuickPlanAction',
    rightHintKey: 'completedDeleteAction',
    leftIcon: Icons.today,
    rightIcon: Icons.delete,
    leftColor: OceanBreezeColorSchemes.softGreen,
    rightColor: OceanBreezeColorSchemes.errorDark,
  );

  /// Inbox页面子任务的滑动配置
  /// 方向规范：与 inboxConfig 保持一致
  /// - 右滑（startToEnd，常用/安全）= 快速加入今日（quickPlan，绿色）
  /// - 左滑（endToStart，危险）= 移动到回收站（delete，红色）
  /// 注意：子任务功能已禁用，此配置与 inboxConfig 相同
  static const SwipeActionConfig inboxSubtaskConfig = SwipeActionConfig(
    leftAction: SwipeActionType.quickPlan,
    rightAction: SwipeActionType.delete,
    leftHintKey: 'inboxQuickPlanAction',
    rightHintKey: 'inboxDeleteAction',
    leftIcon: Icons.today,
    rightIcon: Icons.delete,
    leftColor: OceanBreezeColorSchemes.softGreen,
    rightColor: OceanBreezeColorSchemes.errorDark,
  );

  /// 回收站页面的滑动配置
  /// 方向规范：与 inboxConfig 保持一致
  /// - 右滑（startToEnd，常用/安全）= 恢复任务（restore，绿色）
  /// - 左滑（endToStart，危险）= 永久删除（permanentDelete，红色）
  static const SwipeActionConfig trashConfig = SwipeActionConfig(
    leftAction: SwipeActionType.restore,
    rightAction: SwipeActionType.permanentDelete,
    leftHintKey: 'trashRestoreAction',
    rightHintKey: 'trashPermanentDeleteAction',
    leftIcon: Icons.restore,
    rightIcon: Icons.delete_forever,
    leftColor: OceanBreezeColorSchemes.softGreen,
    rightColor: OceanBreezeColorSchemes.errorDark,
  );
}
