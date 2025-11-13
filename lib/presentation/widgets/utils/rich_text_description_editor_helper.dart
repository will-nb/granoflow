import 'package:flutter/material.dart';
import '../rich_text_description_editor_dialog.dart';

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
  static Future<void> showRichTextDescriptionEditor(
    BuildContext context, {
    required String? initialDescription,
    required ValueChanged<String?> onSave,
  }) async {
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            RichTextDescriptionEditorDialog(
          initialDescription: initialDescription,
          onSave: onSave,
        ),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        fullscreenDialog: true,
        opaque: true,
      ),
    );
  }
}

