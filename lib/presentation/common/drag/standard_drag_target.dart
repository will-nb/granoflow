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
    final baseColor = widget.type == InsertionType.between
        ? theme.insertionLineBetweenColor
        : theme.insertionLineSectionColor;

    return Container(
      height: isHovering
          ? DragConstants.insertionLineHeight
          : DragConstants.insertionHitHeight,
      margin: _getMargin(widget.type),
      decoration: BoxDecoration(
        color: isHovering ? baseColor : Colors.transparent,
        borderRadius: BorderRadius.circular(1),
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
