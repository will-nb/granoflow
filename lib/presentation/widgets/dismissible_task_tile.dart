import 'package:flutter/material.dart';
import '../../data/models/task.dart';
import '../../generated/l10n/app_localizations.dart';
import 'swipe_action_config.dart';

/// 通用滑动任务瓦片组件
/// 
/// 手势与方向（请勿随意修改，避免方向被“纠正”成与规范相反）：
/// - 在 LTR 环境下，DismissDirection.startToEnd 表示“右滑”，会显示左侧背景（leading side）。
/// - 在 LTR 环境下，DismissDirection.endToStart 表示“左滑”，会显示右侧背景（trailing side）。
/// - 我们的命名 left/rightAction 指“左/右侧背景对应的动作”，而非“左/右滑”本身。
///   也就是说：startToEnd 触发 leftAction；endToStart 触发 rightAction。
/// 规范约定：
/// - 右滑（startToEnd）用于非破坏性/高频操作（如：加入今日）。
/// - 左滑（endToStart）用于破坏性/风险操作（如：移动到回收站/删除）。
/// 任何反转需经过产品评审，不要因为“看起来更自然”而私自调整。
class DismissibleTaskTile extends StatelessWidget {
  /// 任务对象
  final Task task;
  
  /// 滑动配置
  final SwipeActionConfig config;
  
  /// 左滑动作回调
  final Function(Task) onLeftAction;
  
  /// 右滑动作回调
  final Function(Task) onRightAction;
  
  /// 子组件（任务内容）
  final Widget child;
  
  /// 滑动方向，默认为水平滑动
  final DismissDirection direction;

  const DismissibleTaskTile({
    super.key,
    required this.task,
    required this.config,
    required this.onLeftAction,
    required this.onRightAction,
    required this.child,
    this.direction = DismissDirection.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Dismissible(
      key: Key('dismissible_${task.id}'),
      direction: direction,
      // 左侧背景：在 LTR 下“右滑”（startToEnd）时显示。
      background: _buildLeftBackground(
        context, 
        config.leftIcon, 
        config.leftColor, 
        _getLocalizedText(l10n, config.leftHintKey)
      ),
      // 右侧背景：在 LTR 下“左滑”（endToStart）时显示。
      secondaryBackground: _buildRightBackground(
        context, 
        config.rightIcon, 
        config.rightColor, 
        _getLocalizedText(l10n, config.rightHintKey)
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // 右滑（LTR）：触发 leftAction（显示的是左侧背景）
          onLeftAction(task);
        } else if (direction == DismissDirection.endToStart) {
          // 左滑（LTR）：触发 rightAction（显示的是右侧背景）
          onRightAction(task);
        }
        // 返回 false，让 Dismissible 在回调执行后自动复位
        // 实际的任务移除由 Provider 触发的重建来完成
        return false;
      },
      child: child,
    );
  }


  /// 左侧背景（在 LTR 下“右滑”时展示，文字靠左）
  Widget _buildLeftBackground(BuildContext context, IconData icon, Color color, String hint) {
    return Container(
      color: color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  hint,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 右侧背景（在 LTR 下“左滑”时展示，文字靠右）
  Widget _buildRightBackground(BuildContext context, IconData icon, Color color, String hint) {
    return Container(
      color: color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Text(
                  hint,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 获取本地化文本
  String _getLocalizedText(AppLocalizations l10n, String key) {
    switch (key) {
      case 'actionPromoteToIndependent':
        return l10n.actionPromoteToIndependent;
      case 'inboxDeleteAction':
        return l10n.inboxDeleteAction;
      case 'inboxQuickPlanAction':
        return l10n.inboxQuickPlanAction;
      case 'taskArchiveAction':
        return l10n.taskArchiveAction;
      case 'taskDeleteAction':
        return l10n.taskDeleteAction;
      case 'taskPostponeAction':
        return l10n.taskPostponeAction;
      default:
        return key; // 如果找不到对应的本地化字符串，返回key本身
    }
  }
}
