import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../generated/l10n/app_localizations.dart';
import 'gradient_page_scaffold.dart';

/// 全屏节点编辑弹窗组件
/// 
/// 用于添加或编辑节点标题
class NodeEditorDialog extends StatefulWidget {
  /// 初始标题（用于编辑模式）
  final String? initialTitle;

  /// 保存回调（返回节点标题，异步）
  final Future<void> Function(String) onSave;

  /// 弹窗标题（"Add Node" 或 "Edit Node"）
  final String title;

  const NodeEditorDialog({
    super.key,
    this.initialTitle,
    required this.onSave,
    required this.title,
  });

  @override
  State<NodeEditorDialog> createState() => _NodeEditorDialogState();
}

class _NodeEditorDialogState extends State<NodeEditorDialog> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle ?? '');
    _focusNode = FocusNode();
    // 自动获得焦点
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      // 如果有初始文本，选中所有文本
      if (widget.initialTitle != null && widget.initialTitle!.isNotEmpty) {
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      // 如果标题为空，直接关闭
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSave(title);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.taskUpdateError}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<bool> _handleWillPop() async {
    // 允许直接关闭，不检查是否有未保存的更改
    return true;
  }

  void _handleClose() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: true,
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
            // 保存按钮
            TextButton(
              onPressed: _isSaving ? null : _handleSave,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.commonSave),
            ),
          ],
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
        child: Focus(
          onKeyEvent: (node, event) {
            // 处理 ESC 键
            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
              _handleClose();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: l10n.nodeTitleHint,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: theme.textTheme.bodyLarge,
            maxLines: null,
            minLines: 1,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSave(),
            autofocus: true,
          ),
        ),
      ),
    );
  }
}

