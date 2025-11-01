import 'package:flutter/material.dart';
import '../../../generated/l10n/app_localizations.dart';
import 'inbox_tag_filter_strip.dart';

/// Inbox 筛选折叠组件
///
/// - 默认收拢，仅显示一个带图标的按钮行（参考“添加描述”组件的外观）
/// - 点击展开后显示标签筛选条（InboxTagFilterStrip）
/// - 再次点击收拢
class InboxFilterCollapsible extends StatefulWidget {
  const InboxFilterCollapsible({super.key});

  @override
  State<InboxFilterCollapsible> createState() => _InboxFilterCollapsibleState();
}

class _InboxFilterCollapsibleState extends State<InboxFilterCollapsible>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _arrowController;
  late Animation<double> _arrowTurns;

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _arrowTurns = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _arrowController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _arrowController.forward();
      } else {
        _arrowController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 折叠头
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_alt_outlined, size: 20, color: color),
                  const SizedBox(width: 8),
                  Text(
                    l10n.inboxFilterToggleLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  RotationTransition(
                    turns: _arrowTurns,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 展开内容（标签筛选条）
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _isExpanded
              ? const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: InboxTagFilterStrip(),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}


