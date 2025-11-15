import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/task_search_providers.dart';
import '../../../generated/l10n/app_localizations.dart';

/// 任务搜索栏组件
class TaskSearchBar extends ConsumerStatefulWidget {
  const TaskSearchBar({super.key, this.onTap, this.autofocus = false, this.onChanged});

  /// 点击回调（用于跳转到搜索页面）
  final VoidCallback? onTap;

  /// 是否自动获得焦点
  final bool autofocus;

  /// 输入变化回调（用于实时搜索）
  final ValueChanged<String>? onChanged;

  @override
  ConsumerState<TaskSearchBar> createState() => _TaskSearchBarState();
}

class _TaskSearchBarState extends ConsumerState<TaskSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    ref.read(taskSearchQueryProvider.notifier).state = value;
    widget.onChanged?.call(value);
  }

  void _handleClear() {
    _controller.clear();
    ref.read(taskSearchQueryProvider.notifier).state = '';
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(taskSearchQueryProvider);

    // 同步 controller 和 provider 的状态
    if (_controller.text != query) {
      _controller.text = query;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focusNode.hasFocus
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: _focusNode.hasFocus ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: widget.onTap != null && !widget.autofocus
          ? InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 24,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.searchTasksPlaceholder,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
              decoration: InputDecoration(
                hintText: l10n.searchTasksPlaceholder,
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 24,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 20,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        onPressed: _handleClear,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: _handleChanged,
            ),
    );
  }
}
