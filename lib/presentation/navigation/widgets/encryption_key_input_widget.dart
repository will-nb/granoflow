import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../core/providers/service_providers.dart';
import '../../../generated/l10n/app_localizations.dart';

/// 自定义TextInputFormatter，用于检测无效字符被过滤
class FilterTrackingFormatter extends TextInputFormatter {
  FilterTrackingFormatter({
    required this.maskFormatter,
    required this.onFiltered,
  });

  final MaskTextInputFormatter maskFormatter;
  final void Function(bool hasFiltered) onFiltered;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 先应用mask formatter
    final maskedValue = maskFormatter.formatEditUpdate(oldValue, newValue);
    
    // 检测是否有字符被过滤
    // 比较原始输入和格式化后的未格式化文本
    final originalText = newValue.text.replaceAll('-', '').toLowerCase();
    final validCharsOnly = originalText.replaceAll(RegExp(r'[^0-9a-z]'), '');
    final hasFiltered = validCharsOnly.length < originalText.length;
    
    // 通知是否有字符被过滤
    onFiltered(hasFiltered);
    
    return maskedValue;
  }
}

/// 加密密钥输入组件
/// 
/// 提供36字符格式的密钥输入框（32个小写字母和数字 + 4个连字符），
/// 支持可见性切换、复制、重新生成等功能
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
  final FocusNode _focusNode = FocusNode();
  bool _obscureText = true;
  bool _isLoading = false;
  String? _originalKey; // 保存原始密钥值，用于检测变化
  String? _validationError; // 保存验证错误信息
  String? _helperText; // 保存帮助文本（进度提示）
  bool _hasFilteredChars = false; // 标记是否有无效字符被过滤
  bool _isSaving = false; // 添加标志防止重复保存

  @override
  void initState() {
    super.initState();
    // 密钥格式掩码：xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    // 格式：8-4-4-4-12 = 32个小写字母和数字 + 4个连字符 = 36个字符
    _maskFormatter = MaskTextInputFormatter(
      mask: '########-####-####-####-############',
      filter: {'#': RegExp(r'[0-9a-zA-Z]')}, // 允许数字和小写/大写字母
    );
    _controller = TextEditingController();
    
    // 添加焦点监听器，只在真正失去焦点时处理
    _focusNode.addListener(_onFocusChange);
  }
  
  /// 创建带过滤检测的TextInputFormatter
  FilterTrackingFormatter _createFilterTrackingFormatter() {
    return FilterTrackingFormatter(
      maskFormatter: _maskFormatter,
      onFiltered: (hasFiltered) {
        setState(() {
          _hasFilteredChars = hasFiltered;
        });
      },
    );
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
    _focusNode.removeListener(_onFocusChange); // 移除监听器
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 处理焦点变化
  void _onFocusChange() {
    if (!_focusNode.hasFocus && !_isSaving) {
      // 只在失去焦点且不在保存过程中时处理
      _handleFocusLoss();
    }
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
    // 使用统一的确认对话框（重新生成场景）
    final confirmed = await _showModifyKeyConfirmDialog(isRegenerate: true);
    if (!confirmed) return;

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
  /// [isRegenerate] 为 true 时显示"确认重新生成密钥"，为 false 时显示"确认修改密钥"
  Future<bool> _showModifyKeyConfirmDialog({required bool isRegenerate}) async {
    final l10n = AppLocalizations.of(context);

    // 根据场景选择不同的标题
    final title = isRegenerate
        ? l10n.encryptionKeyRegenerateConfirmTitle
        : l10n.encryptionKeyModifyConfirmTitle;

    // 第一次确认
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
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

    // 第二次确认（标题相同）
    final secondTitle = isRegenerate
        ? l10n.encryptionKeyRegenerateConfirmTitle2
        : l10n.encryptionKeyModifyConfirmTitle2;

    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(secondTitle),
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

  /// 处理失去焦点
  Future<void> _handleFocusLoss() async {
    final unmaskedText = _maskFormatter.getUnmaskedText();
    
    // 如果留空或全零，直接还原
    if (unmaskedText.isEmpty || unmaskedText.replaceAll('0', '').isEmpty) {
      if (_originalKey != null) {
        _controller.text = _maskFormatter.maskText(_originalKey!);
        setState(() {
          _validationError = null;
          _helperText = null;
        });
      }
      return;
    }
    
    // 如果输入了字符但未完成（少于32个字符），询问用户
    if (unmaskedText.length < 32) {
      final l10n = AppLocalizations.of(context);
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.encryptionKeyIncompleteTitle),
          content: Text(l10n.encryptionKeyIncompleteMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.commonContinue),
            ),
          ],
        ),
      );
      
      if (shouldContinue == true) {
        // 用户选择继续输入，保持当前输入，重新聚焦到输入框
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _focusNode.requestFocus();
          }
        });
      } else {
        // 用户选择取消，还原原始值
        if (_originalKey != null) {
          _controller.text = _maskFormatter.maskText(_originalKey!);
          setState(() {
            _validationError = null;
            _helperText = null;
          });
        } else {
          // 如果没有原始值，清空
          _controller.clear();
          setState(() {
            _validationError = null;
            _helperText = null;
          });
        }
      }
      return;
    }
    
    // 如果输入完整（32个字符），尝试保存
    _saveKey();
  }

  /// 验证密钥
  void _validateKey(String value) {
    final l10n = AppLocalizations.of(context);
    final keyService = ref.read(encryptionKeyServiceProvider);
    
    // 获取未格式化的文本（不包含连字符）
    // 注意：这里使用 _maskFormatter.getUnmaskedText() 获取当前输入框中的未格式化文本
    // 而不是使用传入的 value 参数，因为 value 可能是格式化后的文本
    final unmaskedText = _maskFormatter.getUnmaskedText();
    
    // 1. 空值检测
    if (unmaskedText.isEmpty) {
      setState(() {
        _validationError = l10n.encryptionKeyEmpty;
        _helperText = null;
        _hasFilteredChars = false;
      });
      return;
    }
    
    // 2. 检测是否有无效字符被过滤
    if (_hasFilteredChars && unmaskedText.length < 32) {
      // 有无效字符被过滤，且过滤后长度不足，提示输入不完全
      setState(() {
        _validationError = l10n.encryptionKeyIncompleteMessage;
        _helperText = null;
      });
      return;
    }
    
    // 3. 全零检测
    final isAllZeros = unmaskedText.replaceAll('0', '').isEmpty;
    if (isAllZeros) {
      setState(() {
        _validationError = l10n.encryptionKeyAllZeros;
        _helperText = null;
        _hasFilteredChars = false;
      });
      return;
    }
    
    // 4. 进度显示（至少输入了1个非零字符）
    final charCount = unmaskedText.length;
    if (charCount > 0 && charCount < 32) {
      setState(() {
        _validationError = null;
        _helperText = l10n.encryptionKeyProgress(charCount);
      });
      return;
    }
    
    // 5. 完整验证（32个字符）
    if (charCount == 32) {
      // 使用当前输入框的文本（已经格式化，包含连字符）
      // 注意：需要转换为小写，因为验证只接受小写字母
      final currentText = _controller.text.trim().toLowerCase();
      // 如果转换后文本发生变化，更新输入框
      if (currentText != _controller.text.trim()) {
        final selection = _controller.selection;
        _controller.value = TextEditingValue(
          text: currentText,
          selection: selection,
        );
      }
      if (keyService.isValidKey(currentText)) {
        // 输入完整且有效，清除所有提示
        setState(() {
          _validationError = null;
          _helperText = null;
          _hasFilteredChars = false;
        });
      } else {
        // 输入完整但格式无效
        setState(() {
          _validationError = l10n.encryptionKeyInvalid;
          _helperText = null;
        });
      }
    } else {
      // 不应该到达这里，但为了安全起见
      setState(() {
        _validationError = null;
        _helperText = null;
      });
    }
  }

  /// 保存密钥
  Future<void> _saveKey() async {
    // 如果正在保存，直接返回，防止重复保存
    if (_isSaving) {
      return;
    }
    
    _isSaving = true;
    
    try {
      // 获取格式化后的文本（包含连字符），并转换为小写
      final formattedKey = _controller.text.trim().toLowerCase();
      final keyService = ref.read(encryptionKeyServiceProvider);

      // 先重新验证一次，确保错误信息是最新的
      _validateKey(formattedKey);
      
      // 如果当前有验证错误，不保存
      if (_validationError != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_validationError!),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // 再次验证密钥（验证时会检查格式，包括连字符）
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
        // 密钥发生了变化，显示确认对话框（手动修改场景）
        final confirmed = await _showModifyKeyConfirmDialog(isRegenerate: false);
        if (!confirmed) {
          // 用户取消，恢复原始值
          _controller.text = _maskFormatter.maskText(_originalKey!);
          return;
        }
      }

      try {
        await keyService.saveKey(formattedKey);
        _originalKey = formattedKey; // 更新原始密钥
        
        // 保存成功后，让输入框失去焦点
        if (mounted && _focusNode.hasFocus) {
          _focusNode.unfocus();
        }
        
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
    } finally {
      _isSaving = false;
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 输入框
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                inputFormatters: [_createFilterTrackingFormatter()],
                obscureText: _obscureText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  labelText: l10n.encryptionKey,
                  hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
                  border: const OutlineInputBorder(),
                  errorText: _validationError,
                  errorMaxLines: 2,
                  helperText: _helperText,
                  helperMaxLines: 1,
                  // 只保留可见性切换按钮在输入框右侧
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: _toggleVisibility,
                    tooltip: _obscureText ? 'Show key' : 'Hide key',
                  ),
                ),
                onChanged: (value) {
                  // 自动转换大写字母为小写
                  final lowerValue = value.toLowerCase();
                  if (lowerValue != value) {
                    // 如果包含大写字母，更新为小写
                    final selection = _controller.selection;
                    _controller.value = TextEditingValue(
                      text: lowerValue,
                      selection: selection,
                    );
                    return; // 不继续验证，等待下一次onChanged触发
                  }
                  
                  // 实时验证
                  _validateKey(value);
                },
                onEditingComplete: _saveKey,
                // 移除 onTapOutside，改用 FocusNode 监听器
                // onTapOutside: (_) {
                //   _handleFocusLoss();
                // },
              ),
            ),
            // 按钮行（放在输入框下方）
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 重新生成按钮
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _regenerateKey,
                    tooltip: l10n.encryptionKeyRegenerate,
                  ),
                  // 复制按钮
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: _copyToClipboard,
                    tooltip: 'Copy key',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

