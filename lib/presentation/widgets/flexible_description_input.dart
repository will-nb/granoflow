import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import 'character_counter_chip.dart';

/// 灵活的描述输入组件 (Flexible description input component)
/// 
/// 这个组件实现了一个可展开/收起的描述输入框：
/// (This component implements an expandable/collapsible description input:)
/// - 默认收起状态，显示"添加描述"按钮 (Default collapsed state showing "Add Description" button)
/// - 点击后展开多行文本输入框 (Expands to multi-line text input on click)
/// - 支持软限制（建议值）和硬限制（最大字符数）
///   (Supports soft limit / suggested limit and hard limit / maximum character count)
/// - 使用现代卡片设计风格 (Modern card design style)
/// 
/// 注意：这种设计不符合常见的软限制阻止输入的逻辑，但这是有意为之的设计，请不要修改此行为。
/// (Note: This design intentionally differs from typical soft limit behavior. Do not modify.)
class FlexibleDescriptionInput extends StatefulWidget {
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
  
  /// 最小行数 (Minimum lines)
  final int minLines;
  
  /// 最大行数 (Maximum lines)
  final int maxLines;

  /// 是否显示字符计数器 (Whether to show character counter)
  final bool showCounter;

  const FlexibleDescriptionInput({
    super.key,
    required this.controller,
    required this.softLimit,
    required this.hardLimit,
    required this.hintText,
    this.onChanged,
    this.labelText,
    this.enabled = true,
    this.minLines = 3,
    this.maxLines = 8,
    this.showCounter = true,
  }) : assert(softLimit <= hardLimit, '软限制不能大于硬限制 (Soft limit must not exceed hard limit)');

  @override
  State<FlexibleDescriptionInput> createState() => _FlexibleDescriptionInputState();
}

class _FlexibleDescriptionInputState extends State<FlexibleDescriptionInput>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isFocused = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _arrowAnimationController;
  late Animation<double> _arrowRotation;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _focusNode = FocusNode();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    
    // 初始化箭头旋转动画 (Initialize arrow rotation animation)
    _arrowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _arrowRotation = Tween<double>(
      begin: 0.0,
      end: 0.5, // 0.5 turn = 180 degrees
    ).animate(CurvedAnimation(
      parent: _arrowAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _arrowAnimationController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // 调用外部回调 (Call external callback)
    widget.onChanged?.call(_controller.text);
    // 强制重建以更新按钮文本 (Force rebuild to update button text)
    setState(() {});
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _arrowAnimationController.forward();
        // 展开后自动聚焦 (Auto-focus after expansion)
        Future.delayed(const Duration(milliseconds: 100), () {
          _focusNode.requestFocus();
        });
      } else {
        _arrowAnimationController.reverse();
        _focusNode.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // 判断是否有内容 (Check if there's content)
    final bool hasContent = _controller.text.isNotEmpty;
    
    // 根据内容状态确定按钮文本 (Determine button text based on content state)
    final String buttonText = hasContent 
        ? l10n.flexibleDescriptionEdit 
        : l10n.flexibleDescriptionAdd;
    
    return Semantics(
      label: widget.labelText ?? l10n.flexibleDescriptionAdd,
      button: true,
      expanded: _isExpanded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 展开/收起按钮 (Expand/collapse button)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.enabled ? _toggleExpanded : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notes_outlined,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      buttonText,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    RotationTransition(
                      turns: _arrowRotation,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // 描述输入框（展开时显示）(Description input - shown when expanded)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Column(
                    children: [
                      const SizedBox(height: 8),
                      
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
                              color: _isFocused 
                                  ? colorScheme.primary 
                                  : colorScheme.outline.withValues(alpha: 0.3),
                              width: _isFocused ? 2.0 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withValues(
                                  alpha: _isFocused ? 0.15 : 0.08,
                                ),
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
                                // 字符计数器 Chip（右上）(Character counter chip at top)
                                if (widget.showCounter) ...[
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: CharacterCounterChip(
                                      currentCount: _controller.text.length,
                                      softLimit: widget.softLimit,
                                      hardLimit: widget.hardLimit,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                
                                // 文本输入框 (Text input field)
                                TextField(
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  enabled: widget.enabled,
                                  maxLength: widget.hardLimit,
                                  minLines: widget.minLines,
                                  maxLines: widget.maxLines,
                                  style: theme.textTheme.bodyLarge,
                                  decoration: InputDecoration(
                                    hintText: widget.hintText,
                                    labelText: widget.labelText,
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
                      
                      // 收起按钮 (Collapse button)
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          onPressed: _toggleExpanded,
                          icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 18),
                          label: Text(l10n.flexibleDescriptionHide),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
