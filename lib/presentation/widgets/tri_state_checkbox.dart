import 'package:flutter/material.dart';

/// 三态枚举
enum TriState {
  pending,   // 未选中（待处理）
  finished,  // 选中（已完成）
  deleted,   // 删除状态（显示 X）
}

/// 三态复选框组件
class TriStateCheckbox extends StatelessWidget {
  const TriStateCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 24.0,
  });

  final TriState value;
  final ValueChanged<TriState>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onChanged == null ? null : () {
        // 循环切换：pending -> finished -> deleted -> pending
        final nextState = switch (value) {
          TriState.pending => TriState.finished,
          TriState.finished => TriState.deleted,
          TriState.deleted => TriState.pending,
        };
        onChanged!(nextState);
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _getBorderColor(theme),
            width: 2,
          ),
          color: _getBackgroundColor(theme),
        ),
        child: _buildContent(theme),
      ),
    );
  }

  Color _getBorderColor(ThemeData theme) {
    return switch (value) {
      TriState.pending => theme.colorScheme.outline,
      TriState.finished => theme.colorScheme.primary,
      TriState.deleted => theme.colorScheme.error,
    };
  }

  Color? _getBackgroundColor(ThemeData theme) {
    return switch (value) {
      TriState.pending => null,
      TriState.finished => theme.colorScheme.primary,
      TriState.deleted => theme.colorScheme.errorContainer,
    };
  }

  Widget _buildContent(ThemeData theme) {
    return switch (value) {
      TriState.pending => const SizedBox.shrink(),
      TriState.finished => Icon(
          Icons.check,
          size: size * 0.6,
          color: theme.colorScheme.onPrimary,
        ),
      TriState.deleted => Icon(
          Icons.close,
          size: size * 0.6,
          color: theme.colorScheme.onErrorContainer,
        ),
    };
  }
}

