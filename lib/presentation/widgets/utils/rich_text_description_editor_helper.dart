import 'package:flutter/material.dart';
import '../rich_text_description_editor_dialog.dart';
import '../../../generated/l10n/app_localizations.dart';

/// 富文本描述编辑工具类
/// 
/// 统一处理富文本编辑弹窗的显示逻辑
/// 参考 TaskBottomSheetHelper 的实现模式
class RichTextDescriptionEditorHelper {
  RichTextDescriptionEditorHelper._();

  /// 显示富文本描述编辑弹窗
  /// 
  /// [context] BuildContext
  /// [initialDescription] 初始 description 值（Delta JSON 字符串或 null）
  /// [onSave] 保存回调（返回 Delta JSON 字符串或 null）
  /// [title] 弹窗标题（可选，默认从本地化文本读取）
  static Future<void> showRichTextDescriptionEditor(
    BuildContext context, {
    required String? initialDescription,
    required ValueChanged<String?> onSave,
    String? title,
  }) async {
    final l10n = AppLocalizations.of(context);
    final dialogTitle = title ??
        (initialDescription != null && initialDescription.isNotEmpty
            ? l10n.flexibleDescriptionEdit
            : l10n.flexibleDescriptionAdd);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => RichTextDescriptionEditorDialog(
        initialDescription: initialDescription,
        onSave: onSave,
        title: dialogTitle,
      ),
    );
  }
}

