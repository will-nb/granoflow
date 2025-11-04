import 'package:flutter/material.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';

/// 任务标题行编辑器组件
/// 支持内联编辑任务标题
class TaskRowTitleEditor extends StatefulWidget {
  const TaskRowTitleEditor({
    super.key,
    required this.task,
    this.leading,
    this.trailing,
    this.showConvertAction = false,
    this.onConvertToProject,
    this.useBodyText = false,
    required this.onTitleChanged,
  });

  final Task task;
  final Widget? leading;
  final Widget? trailing;
  final bool showConvertAction;
  final VoidCallback? onConvertToProject;
  final bool useBodyText;
  final Future<void> Function(String newTitle) onTitleChanged;

  @override
  State<TaskRowTitleEditor> createState() => _TaskRowTitleEditorState();
}

class _TaskRowTitleEditorState extends State<TaskRowTitleEditor> {
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
      return;
    }

    if (newTitle != widget.task.title) {
      await widget.onTitleChanged(newTitle);
    }

    setState(() {
      _isEditingTitle = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isCompleted = widget.task.status == TaskStatus.completedActive;
    final isTrashed = widget.task.status == TaskStatus.trashed;

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
                  onSubmitted: (_) => _saveTitle(),
                )
              : GestureDetector(
                  onTap: isTrashed ? null : () {
                    setState(() {
                      _isEditingTitle = true;
                    });
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

