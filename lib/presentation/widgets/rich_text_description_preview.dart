import 'package:flutter/material.dart';
import '../../core/utils/delta_json_utils.dart';
import '../../generated/l10n/app_localizations.dart';

/// 富文本描述预览组件
/// 
/// 显示编辑按钮（Add Description 或 Edit Description）
/// 支持只读模式和可编辑模式
class RichTextDescriptionPreview extends StatelessWidget {
  /// description 字段值（Delta JSON 字符串或 null）
  final String? description;

  /// 点击回调（打开编辑弹窗），如果为 null 则不可点击（只读模式）
  final VoidCallback? onTap;

  /// 最大行数（已废弃，保留以兼容旧代码）
  @Deprecated('不再使用预览功能，此参数已废弃')
  final int? maxLines;

  /// 是否只读模式（默认 false），只读模式下不可点击
  final bool readOnly;

  const RichTextDescriptionPreview({
    super.key,
    this.description,
    this.onTap,
    this.maxLines,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 判断是否有内容
    final hasContent = description != null &&
        description!.isNotEmpty &&
        DeltaJsonUtils.isValidDeltaJson(description);

    // 如果 readOnly 为 true 或 onTap 为 null，不显示任何内容
    if (readOnly || onTap == null) {
      return const SizedBox.shrink();
    }

    // 如果 readOnly 为 false 且 onTap 不为 null，显示按钮
    // 根据是否有内容显示不同的按钮文本
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.notes_outlined),
      label: Text(hasContent 
          ? l10n.flexibleDescriptionEdit 
          : l10n.flexibleDescriptionAdd),
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
      ),
    );
  }
}

