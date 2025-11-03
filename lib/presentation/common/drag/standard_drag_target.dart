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
/// 注意：只使用移动让位动画作为视觉反馈，不渲染插入线
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
  // 是否在未悬停时也显示插入目标区域（保持与 Tasks 行为一致）
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
          // 非悬停：渲染透明命中区；悬停：渲染自定义内容或默认透明区域
          // 注意：不渲染插入线，视觉反馈通过移动让位动画提供
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

  // 构建默认插入目标区域（容错区间）
  // 注意：这是一个透明的命中区域，不渲染任何视觉元素
  // 视觉反馈完全通过移动让位动画提供

  Widget _buildDefaultInsertionZone(BuildContext context, DragTheme theme, bool isHovering) {
    // 标准实现：插入目标是一个透明的容错区域，用于接收拖拽操作
    // 不显示任何视觉元素，视觉反馈完全依靠移动让位动画
    // 
    // 高度说明：
    // - 默认使用 insertionTargetHeight (34像素，包含上下各16像素容错)
    // - 如果有 expandedHeight（让位动画触发时），使用扩展高度覆盖整个让出的空间
    // - 这确保了即使让位动画发生，整个让出的空间都可以接收拖拽
    final height = widget.expandedHeight ?? DragConstants.insertionTargetHeight;
    
    return Container(
      height: height,
      // 完全透明的容器，只作为命中区域使用
      // 不渲染边框、背景或任何视觉元素
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
    );
  }
}
