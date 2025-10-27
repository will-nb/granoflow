import 'package:flutter/material.dart';
import '../../data/models/task.dart';
import '../../generated/l10n/app_localizations.dart';
import 'swipe_action_config.dart';

/// 通用滑动任务瓦片组件
/// 
/// 提供可配置的滑动功能，支持不同的滑动动作和提示
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

  const DismissibleTaskTile({
    super.key,
    required this.task,
    required this.config,
    required this.onLeftAction,
    required this.onRightAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Dismissible(
      key: Key('dismissible_${task.id}'),
      direction: DismissDirection.horizontal,
      background: _buildLeftBackground(
        context, 
        config.leftIcon, 
        config.leftColor, 
        _getLocalizedText(l10n, config.leftHintKey)
      ),
      secondaryBackground: _buildRightBackground(
        context, 
        config.rightIcon, 
        config.rightColor, 
        _getLocalizedText(l10n, config.rightHintKey)
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // 左滑
          onLeftAction(task);
        } else if (direction == DismissDirection.endToStart) {
          // 右滑
          onRightAction(task);
        }
        return true; // 直接执行，无需确认弹窗
      },
      child: child,
    );
  }


  /// 构建左滑背景（文字靠左）
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

  /// 构建右滑背景（文字靠右）
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
