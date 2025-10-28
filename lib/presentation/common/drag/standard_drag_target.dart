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
    this.showWhenIdle = true,
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
        final showInsertion = isHovering || widget.showWhenIdle;
        return AnimatedContainer(
          duration: DragConstants.hoverAnimationDuration,
          decoration: BoxDecoration(
            color: showInsertion ? _getHoverColor(dragTheme) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: showInsertion
              ? (widget.child ?? _buildDefaultInsertionLine(context, dragTheme, isHovering))
              : const SizedBox.shrink(),
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

  Color _getHoverColor(DragTheme theme) {
    switch (widget.type) {
      case InsertionType.between:
        return theme.hoverBackgroundBetween;
      case InsertionType.first:
      case InsertionType.last:
        return theme.hoverBackgroundSection;
    }
  }

  Widget _buildDefaultInsertionLine(BuildContext context, DragTheme theme, bool isHovering) {
    final color = widget.type == InsertionType.between
        ? theme.insertionLineBetweenColor
        : theme.insertionLineSectionColor;

    return Container(
      height: DragConstants.insertionLineHeight,
      margin: _getMargin(widget.type),
      decoration: BoxDecoration(
        color: isHovering ? color : color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(1),
        boxShadow: isHovering ? [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: DragConstants.insertionLineBlurRadius,
            spreadRadius: DragConstants.insertionLineSpreadRadius,
          ),
        ] : null,
      ),
    );
  }

  EdgeInsets _getMargin(InsertionType type) {
    switch (type) {
      case InsertionType.between:
        return const EdgeInsets.symmetric(vertical: 12);
      case InsertionType.first:
        return const EdgeInsets.only(bottom: 12);
      case InsertionType.last:
        return const EdgeInsets.only(top: 12);
    }
  }
}
