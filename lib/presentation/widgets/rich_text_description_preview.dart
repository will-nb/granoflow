import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../core/utils/delta_json_utils.dart';
import '../../core/utils/rich_text_editor_config.dart';
import '../../generated/l10n/app_localizations.dart';

/// 富文本描述预览组件
/// 
/// 显示只读预览（最多三行）或编辑按钮
/// 支持只读模式和可编辑模式
class RichTextDescriptionPreview extends StatefulWidget {
  /// description 字段值（Delta JSON 字符串或 null）
  final String? description;

  /// 点击回调（打开编辑弹窗），如果为 null 则不可点击（只读模式）
  final VoidCallback? onTap;

  /// 最大行数（可选，默认从配置文件读取）
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
  State<RichTextDescriptionPreview> createState() =>
      _RichTextDescriptionPreviewState();
}

class _RichTextDescriptionPreviewState
    extends State<RichTextDescriptionPreview> {
  QuillController? _controller;
  int _maxLines = 3;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _initializeController();
  }

  @override
  void didUpdateWidget(RichTextDescriptionPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.description != widget.description) {
      _initializeController();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final configService = await RichTextEditorConfigService.getInstance();
    final config = await configService.getConfig();
    setState(() {
      _maxLines = widget.maxLines ?? config.previewMaxLines;
    });
  }

  void _initializeController() {
    _controller?.dispose();
    
    final document = DeltaJsonUtils.jsonToDocument(widget.description);
    _controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    )..readOnly = true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 判断是否有内容
    final hasContent = widget.description != null &&
        widget.description!.isNotEmpty &&
        DeltaJsonUtils.isValidDeltaJson(widget.description);

    // 如果 description 为 null 或空，或者解析失败
    if (!hasContent) {
      // 如果 readOnly 为 false 且 onTap 不为 null，显示"添加描述"按钮
      if (!widget.readOnly && widget.onTap != null) {
        return TextButton.icon(
          onPressed: widget.onTap,
          icon: const Icon(Icons.notes_outlined),
          label: Text(l10n.flexibleDescriptionAdd),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
          ),
        );
      }
      // 如果 readOnly 为 true 或 onTap 为 null，不显示任何内容
      return const SizedBox.shrink();
    }

    // 如果 description 有值，使用 QuillEditor 只读模式显示预览
    final previewWidget = QuillEditor.basic(
      controller: _controller!,
      config: const QuillEditorConfig(),
    );

    // 如果 readOnly 为 false 且 onTap 不为 null，整个预览区域可点击
    if (!widget.readOnly && widget.onTap != null) {
      return InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            height: _maxLines * (theme.textTheme.bodyMedium?.fontSize ?? 14) *
                1.5, // 估算行高
            child: ClipRect(
              child: previewWidget,
            ),
          ),
        ),
      );
    }

    // 如果 readOnly 为 true 或 onTap 为 null，预览区域不可点击
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: _maxLines * (theme.textTheme.bodyMedium?.fontSize ?? 14) *
            1.5, // 估算行高
        child: ClipRect(
          child: previewWidget,
        ),
      ),
    );
  }
}

