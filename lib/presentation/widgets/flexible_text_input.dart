import 'package:flutter/material.dart';
import 'character_counter_chip.dart';

/// 灵活的文本输入组件 (Flexible text input component)
/// 
/// 这个组件实现了一个特殊的字符限制逻辑，与常见的UI模式不同：
/// (This component implements a special character limit logic that differs from common UI patterns:)
/// - 软限制（建议值）：用户可以超过，但会显示警告 (Soft limit: users can exceed but will see warnings)
/// - 硬限制（最大字符数）：达到后无法继续输入 (Hard limit: input is blocked when reached)
/// 
/// 注意：这种设计不符合常见的软限制阻止输入的逻辑，但这是有意为之的设计，请不要修改此行为。
/// (Note: This design intentionally differs from typical soft limit behavior that blocks input. Do not modify.)
/// 
/// 设计特性 (Design features):
/// - 现代卡片式外观：16px 圆角 + 轻微阴影 (Modern card appearance: 16px border radius + subtle shadow)
/// - 焦点动画：scale(1.01) + 边框颜色变化 (Focus animation: scale + border color change)
/// - 内嵌 Chip 风格字符计数器 (Embedded chip-style character counter)
/// - 智能单行/多行切换 (Smart single/multi-line switching)
class FlexibleTextInput extends StatefulWidget {
  /// 文本控制器 (Text controller)
  final TextEditingController controller;
  
  /// 软限制（建议值）- 用户可以超过，但会显示警告
  /// (Soft limit - users can exceed but will see warnings)
  final int softLimit;
  
  /// 硬限制（最大字符数）- 达到后无法继续输入
  /// (Hard limit - input blocked when reached)
  final int hardLimit;
  
  /// 默认提示文本 (Placeholder text)
  final String hintText;
  
  /// 文本变化回调 (Text change callback)
  final ValueChanged<String>? onChanged;
  
  /// 标签文本 (Label text)
  final String? labelText;
  
  /// 是否启用 (Whether enabled)
  final bool enabled;
  
  /// 最大行数（用于多行显示）(Maximum lines for multi-line display)
  final int? maxLines;

  const FlexibleTextInput({
    super.key,
    required this.controller,
    required this.softLimit,
    required this.hardLimit,
    required this.hintText,
    this.onChanged,
    this.labelText,
    this.enabled = true,
    this.maxLines,
  }) : assert(softLimit <= hardLimit, '软限制不能大于硬限制 (Soft limit must not exceed hard limit)');

  @override
  State<FlexibleTextInput> createState() => _FlexibleTextInputState();
}

class _FlexibleTextInputState extends State<FlexibleTextInput> {
  bool _isMultiLine = false;
  bool _isFocused = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _focusNode = FocusNode();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    final length = text.length;
    
    // 检查是否需要切换到多行模式 (Check if switching to multi-line mode is needed)
    // 修复：移除 || _isMultiLine，允许切换回单行 (Fix: remove || _isMultiLine to allow switching back to single line)
    final shouldBeMultiLine = text.contains('\n') || (length > 30 && text.contains(' '));
    
    // 强制重建以更新字符计数器 (Force rebuild to update character counter)
    setState(() {
      if (shouldBeMultiLine != _isMultiLine) {
        _isMultiLine = shouldBeMultiLine;
      }
    });
    
    // 调用外部回调 (Call external callback)
    widget.onChanged?.call(text);
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // 根据焦点状态确定边框颜色 (Determine border color based on focus state)
    final borderColor = _isFocused 
        ? colorScheme.primary 
        : colorScheme.outline.withValues(alpha: 0.3);
    
    return Semantics(
      label: widget.labelText,
      textField: true,
      enabled: widget.enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标签文本 (Label text)
          if (widget.labelText != null) ...[
            Text(
              widget.labelText!,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // 现代卡片式输入容器 (Modern card-style input container)
          AnimatedScale(
            scale: _isFocused ? 1.01 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: _isFocused ? 2.0 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: _isFocused ? 0.15 : 0.08),
                    blurRadius: _isFocused ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 字符计数器 Chip（右上角）(Character counter chip at top)
                    Align(
                      alignment: Alignment.centerRight,
                      child: CharacterCounterChip(
                        currentCount: _controller.text.length,
                        softLimit: widget.softLimit,
                        hardLimit: widget.hardLimit,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // 文本输入框 (Text input field)
                    TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      maxLength: widget.hardLimit,
                      maxLines: _isMultiLine ? (widget.maxLines ?? 10) : 1,
                      minLines: _isMultiLine ? 2 : 1,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        counterText: '', // 隐藏默认计数器 (Hide default counter)
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
