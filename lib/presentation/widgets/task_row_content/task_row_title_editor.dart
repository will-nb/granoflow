import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/task_action_providers.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';

/// 任务标题行编辑器组件
/// 支持内联编辑任务标题
class TaskRowTitleEditor extends ConsumerStatefulWidget {
  const TaskRowTitleEditor({
    super.key,
    required this.task,
    this.leading,
    this.trailing,
    this.showConvertAction = false,
    this.onConvertToProject,
    this.useBodyText = false,
    required this.onTitleChanged,
    this.isEditingNotifier, // 编辑状态通知器，用于控制拖拽和滑动
  });

  final Task task;
  final Widget? leading;
  final Widget? trailing;
  final bool showConvertAction;
  final VoidCallback? onConvertToProject;
  final bool useBodyText;
  final Future<void> Function(String newTitle) onTitleChanged;
  /// 编辑状态通知器，用于控制拖拽和滑动的启用/禁用
  final ValueNotifier<bool>? isEditingNotifier;

  @override
  ConsumerState<TaskRowTitleEditor> createState() => _TaskRowTitleEditorState();
}

class _TaskRowTitleEditorState extends ConsumerState<TaskRowTitleEditor> {
  late TextEditingController _titleController;
  late FocusNode _titleFocusNode;
  bool _isEditingTitle = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _titleFocusNode = FocusNode();
    _titleFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _titleFocusNode.removeListener(_onFocusChange);
    // 如果当前任务正在编辑，清除全局状态
    if (_isEditingTitle && ref.read(currentEditingTaskIdProvider) == widget.task.id) {
      ref.read(currentEditingTaskIdProvider.notifier).state = null;
    }
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TaskRowTitleEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果任务标题从外部更新，同步到控制器
    if (widget.task.title != oldWidget.task.title && !_isEditingTitle) {
      _titleController.text = widget.task.title;
    }
  }

  void _onFocusChange() {
    if (!_titleFocusNode.hasFocus && _isEditingTitle) {
      _saveTitle();
    } else if (_titleFocusNode.hasFocus && !_isEditingTitle) {
      // 焦点获得时，如果还没进入编辑状态，更新状态
      // 先设置全局状态，这会自动清除其他任务的编辑状态
      ref.read(currentEditingTaskIdProvider.notifier).state = widget.task.id;
      setState(() {
        _isEditingTitle = true;
      });
      widget.isEditingNotifier?.value = true;
    } else if (!_titleFocusNode.hasFocus && _isEditingTitle) {
      // 焦点失去时，如果还在编辑状态，更新状态
      widget.isEditingNotifier?.value = false;
      // 如果当前任务ID匹配，清除全局状态
      if (ref.read(currentEditingTaskIdProvider) == widget.task.id) {
        ref.read(currentEditingTaskIdProvider.notifier).state = null;
      }
    }
  }

  Future<void> _saveTitle() async {
    final newTitle = _titleController.text.trim();
    if (newTitle.isEmpty) {
      // 如果为空，恢复原标题
      _titleController.text = widget.task.title;
      setState(() {
        _isEditingTitle = false;
      });
      widget.isEditingNotifier?.value = false;
      // 清除全局状态
      if (ref.read(currentEditingTaskIdProvider) == widget.task.id) {
        ref.read(currentEditingTaskIdProvider.notifier).state = null;
      }
      return;
    }

    if (newTitle != widget.task.title) {
      await widget.onTitleChanged(newTitle);
    }

    setState(() {
      _isEditingTitle = false;
    });
    widget.isEditingNotifier?.value = false;
    // 清除全局状态
    if (ref.read(currentEditingTaskIdProvider) == widget.task.id) {
      ref.read(currentEditingTaskIdProvider.notifier).state = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isCompleted = widget.task.status == TaskStatus.completedActive;
    final isTrashed = widget.task.status == TaskStatus.trashed;

    // 监听全局编辑状态，当其他任务开始编辑时自动退出当前编辑
    ref.listen<int?>(currentEditingTaskIdProvider, (previous, next) {
      // 如果当前任务正在编辑，但全局状态变为其他任务ID，则退出编辑
      if (_isEditingTitle && next != null && next != widget.task.id) {
        // 其他任务开始编辑，当前任务需要退出编辑状态
        // 直接调用 unfocus，这会触发 _onFocusChange，进而调用 _saveTitle
        if (mounted) {
          _titleFocusNode.unfocus();
        }
      }
    });

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.leading != null)
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 4),
            child: widget.leading!,
          ),
        Expanded(
          child: _isEditingTitle
              ? TextField(
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  style: (widget.useBodyText
                      ? theme.textTheme.bodyLarge
                      : theme.textTheme.titleMedium),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    isDense: true,
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    _titleFocusNode.unfocus(); // 这会触发 _onFocusChange，进而调用 _saveTitle
                  },
                )
              : GestureDetector(
                  onTap: isTrashed ? null : () {
                    // 先设置全局状态，这会自动清除其他任务的编辑状态
                    ref.read(currentEditingTaskIdProvider.notifier).state = widget.task.id;
                    setState(() {
                      _isEditingTitle = true;
                    });
                    widget.isEditingNotifier?.value = true;
                    // 延迟聚焦，确保TextField已经构建
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _titleFocusNode.requestFocus();
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      widget.task.title,
                      style:
                          (widget.useBodyText
                                  ? theme.textTheme.bodyLarge
                                  : theme.textTheme.titleMedium)
                              ?.copyWith(
                                decoration: (isCompleted || isTrashed)
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isTrashed
                                    ? theme.colorScheme.onSurface
                                        .withValues(alpha: 0.45)
                                    : null,
                              ),
                    ),
                  ),
                ),
        ),
        if (widget.trailing != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: widget.trailing!,
          ),
        if (widget.showConvertAction)
          IconButton(
            onPressed: widget.onConvertToProject,
            tooltip: l10n.projectConvertTooltip,
            icon: Icon(Icons.autorenew, color: theme.colorScheme.primary),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }
}

