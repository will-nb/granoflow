import 'package:flutter/material.dart';
import '../../../core/constants/drag_constants.dart';
import '../../../core/theme/drag_theme.dart';

/// 插入类型枚举
enum InsertionType { between, first, last }

/// 标准拖拽目标组件
/// 
/// 封装 DragTarget，提供统一的插入线和 hover 效果
/// 支持三种插入类型：between（两个任务之间）、first（列表开头）、last（列表结尾）
class StandardDragTarget<T extends Object> extends StatefulWidget {
  const StandardDragTarget({
    required this.type,
    required this.canAccept,
    required this.onAccept,
    this.targetId,
    this.child,
    this.onHoverChanged,
    this.showWhenIdle = false,
    this.useMargin = true,
    this.expandedHeight,
    super.key,
  });

  final InsertionType type;
  final bool Function(T dragged) canAccept;
  final void Function(T dragged) onAccept;
  final int? targetId; // 用于唯一标识
  final Widget? child;
  final void Function(bool isHovering)? onHoverChanged;
  // 是否在未悬停时也渲染默认插入线（保持与 Tasks 行为一致）
  final bool showWhenIdle;
  // 是否使用 margin（在 Positioned 场景下应该设为 false）
  final bool useMargin;
  // 动态扩展高度（用于让位动画时扩展插入目标覆盖整个让出的空间）
  final double? expandedHeight;

  @override
  State<StandardDragTarget<T>> createState() => _StandardDragTargetState<T>();
}

class _StandardDragTargetState<T extends Object> extends State<StandardDragTarget<T>> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final dragTheme = DragTheme.of(context);

    return DragTarget<T>(
      onWillAcceptWithDetails: (d) => widget.canAccept(d.data),
      onAcceptWithDetails: (d) => widget.onAccept(d.data),
      onMove: (d) => _handleHover(true),
      onLeave: (_) => _handleHover(false),
      builder: (_, candidate, __) {
        final isHovering = candidate.isNotEmpty;
        return AnimatedContainer(
          duration: DragConstants.hoverAnimationDuration,
          decoration: const BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          // 非悬停：渲染 1px 透明命中区；悬停：渲染自定义/默认插入线
          child: isHovering
              ? (widget.child ?? _buildDefaultInsertionLine(context, dragTheme, true))
              : _buildDefaultInsertionLine(context, dragTheme, false),
        );
      },
    );
  }

  void _handleHover(bool isHovering) {
    if (_isHovering != isHovering) {
      setState(() {
        _isHovering = isHovering;
      });
      widget.onHoverChanged?.call(isHovering);
    }
  }

  // 背景高亮已移除，仅保留插入线，因此不再需要计算hover背景色

  Widget _buildDefaultInsertionLine(BuildContext context, DragTheme theme, bool isHovering) {
    // 标准实现：插入目标是一个小的独立区域，不显示视觉元素
    // 让位动画已经足够明显了，不需要额外的插入线
    // 按照官方标准：一旦让位动画发生（expandedHeight != null），整个让出的空间都应该可以接受拖拽
    // 不需要等待精确悬停，直接使用扩展高度覆盖整个让出的空间
    final height = widget.expandedHeight ?? DragConstants.insertionTargetHeight;
    
    return Container(
      height: height,
      // 标准实现：插入目标作为独立区域，不使用 margin
      // margin 只在需要视觉间距时使用（如使用 margin 的场景）
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
    );
  }
}
