import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';

/// 字符计数器 Chip 组件状态 (Character counter chip state)
enum CounterState {
  /// 正常：字符数 ≤ 软限制 (Normal: count <= soft limit)
  normal,
  
  /// 警告：软限制 < 字符数 < 硬限制 (Warning: soft limit < count < hard limit)
  warning,
  
  /// 错误：字符数 = 硬限制 (Error: count = hard limit)
  error,
}

/// 字符计数器 Chip 组件 (Character counter chip component)
/// 
/// 用于显示文本输入的字符计数，支持软限制和硬限制
/// (Used to display character count for text input, supports soft and hard limits)
/// 
/// 特性 (Features):
/// - 三种状态：正常/警告/错误 (Three states: normal/warning/error)
/// - Chip 风格设计，999px 圆角 (Chip style design with 999px border radius)
/// - 国际化支持 (i18n support)
/// - 可访问性支持 (Accessibility support)
class CharacterCounterChip extends StatelessWidget {
  const CharacterCounterChip({
    super.key,
    required this.currentCount,
    required this.softLimit,
    required this.hardLimit,
  }) : assert(softLimit <= hardLimit, '软限制不能大于硬限制 (Soft limit must not exceed hard limit)');

  /// 当前字符数 (Current character count)
  final int currentCount;
  
  /// 软限制（建议值）(Soft limit / suggested limit)
  final int softLimit;
  
  /// 硬限制（最大字符数）(Hard limit / maximum character count)
  final int hardLimit;

  /// 获取当前状态 (Get current state)
  CounterState get _state {
    if (currentCount <= softLimit) {
      return CounterState.normal;
    } else if (currentCount < hardLimit) {
      return CounterState.warning;
    } else {
      return CounterState.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = _state;
    
    // 根据状态确定样式 (Determine style based on state)
    final Color baseColor;
    final String text;
    final IconData? icon;
    
    switch (state) {
      case CounterState.normal:
        baseColor = theme.textTheme.bodySmall?.color ?? Colors.grey;
        text = '${l10n.flexibleInputSoftLimit}: $currentCount/$softLimit';
        icon = null;
      
      case CounterState.warning:
        baseColor = theme.colorScheme.error;
        text = '${l10n.flexibleInputExceeded}: $currentCount/$softLimit';
        icon = Icons.warning_amber_rounded;
      
      case CounterState.error:
        baseColor = theme.colorScheme.error;
        text = '$hardLimit/$hardLimit';
        icon = Icons.error_rounded;
    }
    
    // 计算透明度 (Calculate opacity)
    final double bgOpacity = state == CounterState.normal ? 0.08 : 0.12;
    final double borderOpacity = state == CounterState.normal ? 0.15 : 0.25;
    
    return Semantics(
      label: text,
      readOnly: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: bgOpacity),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: baseColor.withValues(alpha: borderOpacity),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: baseColor,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: baseColor,
                fontWeight: state == CounterState.normal 
                    ? FontWeight.w400 
                    : FontWeight.w600,
                fontSize: 12,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
