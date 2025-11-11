import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../core/providers/service_providers.dart';
import '../../../generated/l10n/app_localizations.dart';

/// 加密密钥输入组件
/// 
/// 提供 UUID v4 格式的密钥输入框，支持可见性切换、复制、重新生成等功能
class EncryptionKeyInputWidget extends ConsumerStatefulWidget {
  const EncryptionKeyInputWidget({super.key});

  @override
  ConsumerState<EncryptionKeyInputWidget> createState() =>
      _EncryptionKeyInputWidgetState();
}

class _EncryptionKeyInputWidgetState
    extends ConsumerState<EncryptionKeyInputWidget> {
  late TextEditingController _controller;
  late MaskTextInputFormatter _maskFormatter;
  bool _obscureText = true;
  bool _isLoading = false;
  String? _originalKey; // 保存原始密钥值，用于检测变化
  String? _validationError; // 保存验证错误信息

  @override
  void initState() {
    super.initState();
    // UUID v4 格式掩码：xxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    _maskFormatter = MaskTextInputFormatter(
      mask: '####-####-####-####-############',
      filter: {'#': RegExp(r'[0-9a-fA-F]')},
    );
    _controller = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在 didChangeDependencies 中加载密钥，此时可以访问 ref
    if (_isLoading == false && _controller.text.isEmpty) {
      _loadKey(ref);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 加载密钥
  Future<void> _loadKey(WidgetRef ref) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final keyService = ref.read(encryptionKeyServiceProvider);
      final key = await keyService.loadKey();
      if (key != null && mounted) {
        _originalKey = key; // 保存原始密钥
        _controller.text = _maskFormatter.maskText(key);
      }
    } catch (e) {
      debugPrint('Failed to load encryption key: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 切换可见性
  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  /// 复制密钥到剪贴板
  Future<void> _copyToClipboard() async {
    final key = _controller.text;
    if (key.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: key));
    if (mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.encryptionKeyCopySuccess),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 重新生成密钥
  Future<void> _regenerateKey() async {
    final l10n = AppLocalizations.of(context);

    // 第一次确认
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.encryptionKeyRegenerateConfirmTitle),
        content: Text(l10n.encryptionKeyRegenerateConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );

    if (firstConfirm != true) return;

    // 第二次确认
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.encryptionKeyRegenerateConfirmTitle2),
        content: Text(l10n.encryptionKeyRegenerateConfirmMessage2),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );

    if (secondConfirm != true) return;

    // 生成新密钥
    try {
      final keyService = ref.read(encryptionKeyServiceProvider);
      final newKey = keyService.generateKey();
      await keyService.saveKey(newKey);
      _originalKey = newKey; // 更新原始密钥
      setState(() {
        _controller.text = _maskFormatter.maskText(newKey);
      });
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.encryptionKeySaveError}: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 显示修改密钥确认对话框
  Future<bool> _showModifyKeyConfirmDialog() async {
    final l10n = AppLocalizations.of(context);

    // 第一次确认
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.encryptionKeyRegenerateConfirmTitle),
        content: Text(l10n.encryptionKeyRegenerateConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );

    if (firstConfirm != true) return false;

    // 第二次确认
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.encryptionKeyRegenerateConfirmTitle2),
        content: Text(l10n.encryptionKeyRegenerateConfirmMessage2),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );

    return secondConfirm == true;
  }

  /// 验证密钥
  void _validateKey(String value) {
    final keyService = ref.read(encryptionKeyServiceProvider);
    final trimmedValue = value.trim();
    
    if (trimmedValue.isEmpty) {
      setState(() {
        _validationError = null;
      });
      return;
    }
    
    if (!keyService.isValidKey(trimmedValue)) {
      setState(() {
        _validationError = AppLocalizations.of(context).encryptionKeyInvalid;
      });
    } else {
      setState(() {
        _validationError = null;
      });
    }
  }

  /// 保存密钥
  Future<void> _saveKey() async {
    // 获取格式化后的文本（包含连字符）
    final formattedKey = _controller.text.trim();
    final keyService = ref.read(encryptionKeyServiceProvider);

    // 验证密钥（验证时会检查 UUID v4 格式，包括连字符）
    if (!keyService.isValidKey(formattedKey)) {
      setState(() {
        _validationError = AppLocalizations.of(context).encryptionKeyInvalid;
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.encryptionKeyInvalid),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      // 如果密钥无效，恢复原始值
      if (_originalKey != null) {
        _controller.text = _maskFormatter.maskText(_originalKey!);
        setState(() {
          _validationError = null;
        });
      }
      return;
    }
    
    // 清除验证错误
    setState(() {
      _validationError = null;
    });

    // 检查密钥是否发生了变化
    if (_originalKey != null && formattedKey != _originalKey) {
      // 密钥发生了变化，显示确认对话框
      final confirmed = await _showModifyKeyConfirmDialog();
      if (!confirmed) {
        // 用户取消，恢复原始值
        _controller.text = _maskFormatter.maskText(_originalKey!);
        return;
      }
    }

    try {
      await keyService.saveKey(formattedKey);
      _originalKey = formattedKey; // 更新原始密钥
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).commonSave),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.encryptionKeySaveError}: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      // 保存失败，恢复原始值
      if (_originalKey != null) {
        _controller.text = _maskFormatter.maskText(_originalKey!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const ListTile(
        leading: CircularProgressIndicator(),
        title: Text('Loading encryption key...'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 说明文字
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            l10n.encryptionKeyDescription,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        // 输入框和按钮
        ListTile(
          title: TextField(
            controller: _controller,
            inputFormatters: [_maskFormatter],
            obscureText: _obscureText,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              labelText: l10n.encryptionKey,
              hintText: 'xxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
              border: const OutlineInputBorder(),
              errorText: _validationError,
              errorMaxLines: 2,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 可见性切换按钮
                  IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: _toggleVisibility,
                    tooltip: _obscureText ? 'Show key' : 'Hide key',
                  ),
                  // 复制按钮
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: _copyToClipboard,
                    tooltip: 'Copy key',
                  ),
                  // 重新生成按钮
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _regenerateKey,
                    tooltip: l10n.encryptionKeyRegenerate,
                  ),
                ],
              ),
            ),
            onChanged: (value) {
              // 实时验证
              _validateKey(value);
            },
            onEditingComplete: _saveKey,
            onTapOutside: (_) {
              // 失去焦点时保存
              _saveKey();
            },
          ),
        ),
      ],
    );
  }
}

