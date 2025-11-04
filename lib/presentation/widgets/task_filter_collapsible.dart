import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../generated/l10n/app_localizations.dart';
import 'task_tag_filter_strip.dart';

/// 通用任务筛选折叠组件
///
/// - 默认收拢，仅显示一个带图标的按钮行（参考"添加描述"组件的外观）
/// - 点击展开后显示筛选条（TaskTagFilterStrip）
/// - 再次点击收拢
/// 
/// 接受一个filterProvider参数，可以在任何页面使用
class TaskFilterCollapsible extends ConsumerStatefulWidget {
  const TaskFilterCollapsible({
    super.key,
    required this.filterProvider,
    this.label,
    this.trailing,
  });

  /// 筛选Provider（StateNotifierProvider<TaskFilterNotifier, TaskFilterState>）
  final StateNotifierProvider<TaskFilterNotifier, TaskFilterState>
      filterProvider;

  /// 自定义标签文本（如果为空，使用默认的"筛选"文本）
  final String? label;

  /// 可选的尾部 widget，显示在筛选行右侧
  final Widget? trailing;

  @override
  ConsumerState<TaskFilterCollapsible> createState() =>
      _TaskFilterCollapsibleState();
}

class _TaskFilterCollapsibleState
    extends ConsumerState<TaskFilterCollapsible>
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
    final label = widget.label ?? l10n.inboxFilterToggleLabel;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 折叠头
        Material(
          color: Colors.transparent,
          child: Row(
            children: [
              Expanded(
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
                          label,
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
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),

        // 展开内容（标签筛选条）
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TaskTagFilterStrip(
                    filterProvider: widget.filterProvider,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

