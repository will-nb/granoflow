import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../core/utils/delta_json_utils.dart';
import '../../core/utils/rich_text_editor_config.dart';
import '../../generated/l10n/app_localizations.dart';
import 'gradient_page_scaffold.dart';

/// 全屏富文本编辑弹窗组件
/// 
/// 包含 QuillToolbar 和 QuillEditor，支持自动保存
class RichTextDescriptionEditorDialog extends StatefulWidget {
  /// 初始 description 值（Delta JSON 字符串或 null）
  final String? initialDescription;

  /// 保存回调（返回 Delta JSON 字符串或 null）
  final ValueChanged<String?> onSave;

  /// 弹窗标题（"编辑描述" 或 "添加描述"）
  final String title;

  const RichTextDescriptionEditorDialog({
    super.key,
    this.initialDescription,
    required this.onSave,
    required this.title,
  });

  @override
  State<RichTextDescriptionEditorDialog> createState() =>
      _RichTextDescriptionEditorDialogState();
}

class _RichTextDescriptionEditorDialogState
    extends State<RichTextDescriptionEditorDialog> {
  late QuillController _controller;
  StreamSubscription? _documentChangesSubscription;
  Timer? _debounceTimer;
  bool _isSaving = false;
  bool _saveSuccess = false;
  bool _saveFailed = false;
  String? _lastSavedContent;
  int _debounceDelay = 300;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _loadConfig();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _documentChangesSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final configService = await RichTextEditorConfigService.getInstance();
    final config = await configService.getConfig();
    setState(() {
      _debounceDelay = config.autoSaveDebounce;
    });
  }

  void _initializeController() {
    final document = DeltaJsonUtils.jsonToDocument(widget.initialDescription);
    _controller = QuillController.basic()..document = document;
    _lastSavedContent = widget.initialDescription;

    // 监听文档变化，实现自动保存
    _documentChangesSubscription = _controller.document.changes.listen((event) {
      _onDocumentChanged();
    });
  }

  void _onDocumentChanged() {
    // 取消之前的定时器
    _debounceTimer?.cancel();

    // 设置新的防抖定时器
    _debounceTimer = Timer(Duration(milliseconds: _debounceDelay), () {
      _performSave();
    });
  }

  Future<void> _performSave() async {
    if (_isSaving) return;

    // 检查内容是否为空（只包含空白字符）
    final isEmpty = DeltaJsonUtils.isDocumentEmpty(_controller.document);
    
    // 如果内容为空，保存 null，否则保存 JSON 字符串
    final currentContent = isEmpty ? null : DeltaJsonUtils.documentToJson(_controller.document);
    
    // 如果内容没有变化，不保存
    if (currentContent == _lastSavedContent) {
      return;
    }

    setState(() {
      _isSaving = true;
      _saveSuccess = false;
      _saveFailed = false;
    });

    try {
      // 调用保存回调
      widget.onSave(currentContent);
      
      setState(() {
        _isSaving = false;
        _saveSuccess = true;
        _saveFailed = false;
        _lastSavedContent = currentContent;
      });

      // 3 秒后隐藏"已保存"提示
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _saveSuccess = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _saveSuccess = false;
        _saveFailed = true;
      });

      // 显示错误提示
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.richTextDescriptionAutoSaveFailed),
            action: SnackBarAction(
              label: l10n.richTextDescriptionAutoSaveFailedRetry,
              onPressed: () {
                _performSave();
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<bool> _handleWillPop() async {
    // 如果保存失败，显示确认对话框
    if (_saveFailed) {
      final l10n = AppLocalizations.of(context);
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.richTextDescriptionUnsavedChanges),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.richTextDescriptionAutoSaveFailedCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.richTextDescriptionAutoSaveFailedRetry),
            ),
          ],
        ),
      );
      return shouldPop ?? false;
    }

    // 如果自动保存成功，直接关闭
    return true;
  }

  void _handleClose() async {
    final canClose = await _handleWillPop();
    if (canClose && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final canClose = await _handleWillPop();
          if (canClose && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: GradientPageScaffold(
        fullScreen: true,
        body: Column(
          children: [
            // 顶部栏
            _buildTopBar(context, theme, colorScheme, l10n),
            // 工具栏
            _buildToolbar(context, theme, colorScheme),
            // 编辑器
            Expanded(
              child: _buildEditor(context, theme, colorScheme, l10n),
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
                widget.title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            // 保存状态指示器
            SizedBox(
              width: 48,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _saveSuccess
                      ? Text(
                          l10n.richTextDescriptionAutoSaveSuccess,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                        )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // 自定义工具栏：手动构建按钮列表，完全控制布局，无分隔符
    // 按钮顺序：文本格式（加粗、倾斜、下划线）-> 颜色 -> 列表 -> 引用 -> 链接
    return Container(
      color: colorScheme.surface,
      height: 48,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 文本格式按钮组（加粗、倾斜、下划线）
              QuillToolbarToggleStyleButton(
                controller: _controller,
                attribute: Attribute.bold,
              ),
              const SizedBox(width: 4),
              QuillToolbarToggleStyleButton(
                controller: _controller,
                attribute: Attribute.italic,
              ),
              const SizedBox(width: 4),
              QuillToolbarToggleStyleButton(
                controller: _controller,
                attribute: Attribute.underline,
              ),
              const SizedBox(width: 8),
              // 颜色按钮
              QuillToolbarColorButton(
                controller: _controller,
                isBackground: false,
              ),
              const SizedBox(width: 8),
              // 列表按钮
              QuillToolbarToggleStyleButton(
                controller: _controller,
                attribute: Attribute.ul,
              ),
              const SizedBox(width: 8),
              // 引用按钮
              QuillToolbarToggleStyleButton(
                controller: _controller,
                attribute: Attribute.blockQuote,
              ),
              const SizedBox(width: 8),
              // 链接按钮
              QuillToolbarLinkStyleButton(
                controller: _controller,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditor(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Container(
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: QuillEditor.basic(
          controller: _controller,
          config: QuillEditorConfig(
            placeholder: l10n.projectSheetDescriptionHint,
          ),
          focusNode: FocusNode()..requestFocus(),
        ),
      ),
    );
  }
}

