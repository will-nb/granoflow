import 'package:flutter/material.dart';
import 'modern_tag.dart';

/// 可内联删除的标签组件
/// 基于 ModernTag，右侧添加 × 图标，支持点击删除
class InlineEditableTag extends StatefulWidget {
  const InlineEditableTag({
    super.key,
    required this.label,
    required this.slug,
    required this.onRemove,
    this.color,
    this.icon,
    this.prefix,
    this.size = TagSize.medium,
    this.variant = TagVariant.dot,
  });

  final String label;
  final String slug;
  final Color? color;
  final IconData? icon;
  final String? prefix;
  final TagSize size;
  final TagVariant variant;
  final ValueChanged<String> onRemove;

  @override
  State<InlineEditableTag> createState() => _InlineEditableTagState();
}

class _InlineEditableTagState extends State<InlineEditableTag>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isRemoving = false;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRemove() async {
    if (_isRemoving) return;
    setState(() => _isRemoving = true);
    await _controller.forward();
    widget.onRemove(widget.slug);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModernTag(
              label: widget.label,
              color: widget.color ?? Theme.of(context).colorScheme.primary,
              icon: widget.icon,
              prefix: widget.prefix,
              selected: true,
              variant: widget.variant,
              size: widget.size,
              showCheckmark: false,
            ),
            const SizedBox(width: 4),
            Semantics(
              label: 'Remove ${widget.label}',
              button: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _isRemoving ? null : _handleRemove,
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: _isHovering
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
