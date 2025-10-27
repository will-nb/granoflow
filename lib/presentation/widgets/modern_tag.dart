import 'package:flutter/material.dart';

/// 标签视觉变体
enum TagVariant {
  /// 药丸形（用于编辑场景）
  pill,
  
  /// 圆点形（用于筛选场景）
  dot,
  
  /// 极简形（用于密集场景）
  minimal,
}

/// 标签尺寸
enum TagSize {
  small,
  medium,
  large,
}

/// 现代化的标签组件
/// 
/// 支持多种视觉变体和交互状态，符合2025年设计趋势
class ModernTag extends StatelessWidget {
  const ModernTag({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.prefix,
    this.selected = false,
    this.variant = TagVariant.pill,
    this.size = TagSize.medium,
    this.onTap,
    this.showCheckmark = true,
  });

  /// 标签文本
  final String label;
  
  /// 标签主题色（用于背景、边框、图标）
  final Color color;
  
  /// 标签图标（可选）
  final IconData? icon;
  
  /// 标签前缀（如 @、#），会自动添加到 label 前
  final String? prefix;
  
  /// 是否选中状态
  final bool selected;
  
  /// 视觉变体
  final TagVariant variant;
  
  /// 标签尺寸
  final TagSize size;
  
  /// 点击回调
  final VoidCallback? onTap;
  
  /// 选中时是否显示对勾图标（仅 pill 变体）
  final bool showCheckmark;

  @override
  Widget build(BuildContext context) {
    final widget = switch (variant) {
      TagVariant.pill => _buildPillTag(context),
      TagVariant.dot => _buildDotTag(context),
      TagVariant.minimal => _buildMinimalTag(context),
    };

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: widget,
      );
    }

    return widget;
  }

  /// 构建药丸形标签（用于编辑场景）
  Widget _buildPillTag(BuildContext context) {
    final opacity = selected ? 0.20 : 0.12;
    final borderOpacity = selected ? 0.3 : 0.2;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: _getPadding(),
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: borderOpacity),
          width: selected ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: _getIconSize(), color: color),
            SizedBox(width: _getSpacing()),
          ],
          Text(
            prefix != null ? '$prefix$label' : label,
            style: TextStyle(
              color: color,
              fontSize: _getFontSize(),
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              height: 1.2,
            ),
          ),
          if (selected && showCheckmark) ...[
            SizedBox(width: _getSpacing()),
            Icon(Icons.check, size: _getIconSize() - 2, color: color),
          ],
        ],
      ),
    );
  }

  /// 构建圆点标签（用于筛选场景）
  Widget _buildDotTag(BuildContext context) {
    final bgOpacity = selected ? 0.10 : 0.0;
    final dotSize = selected ? 8.0 : 6.0;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: _getPadding(),
      decoration: BoxDecoration(
        color: color.withValues(alpha: bgOpacity),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: _getSpacing()),
          Text(
            prefix != null ? '$prefix$label' : label,
            style: TextStyle(
              fontSize: _getFontSize(),
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected 
                ? color 
                : Theme.of(context).textTheme.bodyMedium?.color,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建极简标签（用于密集场景）
  Widget _buildMinimalTag(BuildContext context) {
    return Container(
      padding: _getPadding(),
      child: Text(
        prefix != null ? '$prefix$label' : label,
        style: TextStyle(
          fontSize: _getFontSize(),
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? color : Theme.of(context).textTheme.bodyMedium?.color,
          height: 1.2,
        ),
      ),
    );
  }

  /// 根据尺寸获取内边距
  EdgeInsets _getPadding() {
    return switch (size) {
      TagSize.small => const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      TagSize.medium => const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      TagSize.large => const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    };
  }

  /// 根据尺寸获取图标大小
  double _getIconSize() {
    return switch (size) {
      TagSize.small => 12.0,
      TagSize.medium => 14.0,
      TagSize.large => 16.0,
    };
  }

  /// 根据尺寸获取字体大小
  double _getFontSize() {
    return switch (size) {
      TagSize.small => 12.0,
      TagSize.medium => 13.0,
      TagSize.large => 14.0,
    };
  }

  /// 根据尺寸获取元素间距
  double _getSpacing() {
    return switch (size) {
      TagSize.small => 4.0,
      TagSize.medium => 6.0,
      TagSize.large => 8.0,
    };
  }
}

