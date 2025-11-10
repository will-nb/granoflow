import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/drag_constants.dart';
import '../../../core/theme/drag_theme.dart';

/// 插入类型枚举
enum InsertionType { between, first, last }

/// 标准拖拽目标组件
/// 
/// 封装 DragTarget，提供统一的拖拽目标区域和 hover 效果
/// 支持三种插入类型：between（两个任务之间）、first（列表开头）、last（列表结尾）
/// 使用间隔线方案：悬停时显示带阴影的间隔线作为视觉反馈
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
    super.key,
  });

  final InsertionType type;
  final bool Function(T dragged) canAccept;
    final void Function(T dragged) onAccept;
    final String? targetId; // 用于唯一标识
  final Widget? child;
  final void Function(bool isHovering)? onHoverChanged;
  // 是否在未悬停时也显示插入目标区域（保持与 Tasks 行为一致）
  final bool showWhenIdle;
  // 是否使用 margin（在 Positioned 场景下应该设为 false）
  final bool useMargin;

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
      onMove: (details) {
        if (kDebugMode) {
          // 记录拖拽进入插入目标时的详细坐标信息
          final globalPos = details.offset;
          final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
          final localPos = renderBox != null
              ? renderBox.globalToLocal(globalPos)
              : null;
          final size = renderBox?.size;
          
          debugPrint(
            '[DnD] {event: insertion:hover:enter, type: ${widget.type.name}, targetId: ${widget.targetId ?? "null"}, globalPos: (${globalPos.dx.toStringAsFixed(1)}, ${globalPos.dy.toStringAsFixed(1)}), localPos: (${localPos?.dx.toStringAsFixed(1) ?? "null"}, ${localPos?.dy.toStringAsFixed(1) ?? "null"}), targetSize: (${size?.width.toStringAsFixed(1) ?? "null"}, ${size?.height.toStringAsFixed(1) ?? "null"})}',
          );
        }
        _handleHover(true);
      },
      onLeave: (data) {
        if (kDebugMode) {
          debugPrint(
            '[DnD] {event: insertion:hover:leave, type: ${widget.type.name}, targetId: ${widget.targetId ?? "null"}}',
          );
        }
        _handleHover(false);
      },
      builder: (_, candidate, __) {
        final isHovering = candidate.isNotEmpty;
        return AnimatedContainer(
          duration: DragConstants.hoverAnimationDuration,
          decoration: const BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          // 非悬停：渲染透明命中区；悬停：渲染自定义内容或间隔线
          child: isHovering
              ? (widget.child ?? _buildDefaultInsertionZone(context, dragTheme, true))
              : _buildDefaultInsertionZone(context, dragTheme, false),
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

  // 构建默认插入目标区域（间隔线方案）
  // 未悬停：10px 透明命中区域（无视觉元素）
  // 悬停：显示 3px 带阴影的间隔线

  Widget _buildDefaultInsertionZone(BuildContext context, DragTheme theme, bool isHovering) {
    // 间隔线方案：使用间隔线替代让位动画提供视觉反馈
    // - 命中区域：10px 透明区域（用于容错）
    // - 视觉线：3px 带阴影的线（悬停时显示）
    // - 左右边距：16px（与任务卡片水平 padding 对齐）
    
    return Container(
      height: DragConstants.insertionLineHitArea, // 10px 命中区域
      alignment: Alignment.center,
      child: AnimatedOpacity(
        opacity: isHovering ? 1.0 : 0.0,
        duration: DragConstants.hoverAnimationDuration,
        child: Container(
          height: DragConstants.insertionLineHeight, // 3px 视觉线
          margin: EdgeInsets.symmetric(
            horizontal: DragConstants.insertionLineMargin, // 16px 左右边距
          ),
          decoration: BoxDecoration(
            color: theme.insertionLineColor,
            borderRadius: BorderRadius.circular(2.0), // 2px 圆角
            boxShadow: [
              BoxShadow(
                color: theme.insertionLineColor.withValues(
                  alpha: theme.insertionLineShadowAlpha,
                ),
                blurRadius: 4.0, // 4px 模糊半径
                spreadRadius: 1.0, // 1px 扩散半径
                offset: const Offset(0, 1), // 轻微向下偏移
              ),
            ],
          ),
        ),
      ),
    );
  }
}
