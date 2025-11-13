import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../core/utils/delta_json_utils.dart';
import '../../generated/l10n/app_localizations.dart';
import 'gradient_page_scaffold.dart';
import 'utils/rich_text_description_editor_helper.dart';

/// Description 只读查看弹窗组件
/// 
/// 提供只读查看、复制和编辑功能
class DescriptionViewerDialog extends StatefulWidget {
  /// description 字段值（Delta JSON 字符串或 null）
  final String? description;

  /// 保存回调（返回 Delta JSON 字符串或 null）
  final ValueChanged<String?> onSave;

  const DescriptionViewerDialog({
    super.key,
    this.description,
    required this.onSave,
  });

  @override
  State<DescriptionViewerDialog> createState() => _DescriptionViewerDialogState();
}

class _DescriptionViewerDialogState extends State<DescriptionViewerDialog> {
  late QuillController _controller;

  @override
  void initState() {
    super.initState();
    final document = DeltaJsonUtils.jsonToDocument(widget.description);
    _controller = QuillController.basic()..document = document;
    // 设置为只读模式
    _controller.document = document;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleClose() {
    Navigator.of(context).pop();
  }

  Future<void> _handleCopy() async {
    final document = DeltaJsonUtils.jsonToDocument(widget.description);
    final plainText = document.toPlainText();
    
    if (plainText.trim().isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: plainText));
    if (mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.taskCopySuccess),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleEdit() async {
    // 关闭当前查看弹窗
    Navigator.of(context).pop();
    
    // 打开编辑弹窗
    await RichTextDescriptionEditorHelper.showRichTextDescriptionEditor(
      context,
      initialDescription: widget.description,
      onSave: widget.onSave,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: true,
      child: GradientPageScaffold(
        fullScreen: true,
        body: Column(
          children: [
            // 顶部栏
            _buildTopBar(context, theme, colorScheme, l10n),
            // 只读编辑器
            Expanded(
              child: _buildViewer(context, theme, colorScheme, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // 关闭按钮
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _handleClose,
              tooltip: MaterialLocalizations.of(context).closeButtonLabel,
            ),
            // 标题
            Expanded(
              child: Text(
                l10n.flexibleDescriptionEdit,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            // 复制和编辑按钮
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: _handleCopy,
                  tooltip: l10n.taskCopyTitle,
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _handleEdit,
                  tooltip: l10n.flexibleDescriptionEdit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewer(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Container(
      color: colorScheme.surface,
      child: IgnorePointer(
        child: QuillEditor.basic(
          controller: _controller,
          config: QuillEditorConfig(
            padding: const EdgeInsets.all(16),
            placeholder: '',
            expands: false,
            autoFocus: false,
            showCursor: false,
            maxHeight: null,
            minHeight: null,
            scrollable: true,
            enableInteractiveSelection: true,
            enableSelectionToolbar: true,
          ),
        ),
      ),
    );
  }
}

