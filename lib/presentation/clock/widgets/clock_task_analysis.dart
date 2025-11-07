import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/clock_providers.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../widgets/flexible_description_input.dart';

/// 计时器任务分析组件
///
/// 使用 FlexibleDescriptionInput，展开时自动暂停计时器
///
/// 注意：由于 FlexibleDescriptionInput 的内部状态是私有的，我们通过
/// 监听输入框的焦点变化来推断是否展开。当焦点在输入框时，通常意味着已展开。
class ClockTaskAnalysis extends ConsumerStatefulWidget {
  const ClockTaskAnalysis({
    super.key,
    required this.task,
    required this.onDescriptionChanged,
  });

  final Task task;
  final ValueChanged<String> onDescriptionChanged;

  @override
  ConsumerState<ClockTaskAnalysis> createState() =>
      _ClockTaskAnalysisState();
}

class _ClockTaskAnalysisState extends ConsumerState<ClockTaskAnalysis> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.task.description ?? '');
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    widget.onDescriptionChanged(_controller.text);
  }

  void _onFocusChanged() {
    // 当输入框获得焦点时，说明已展开
    final newExpanded = _focusNode.hasFocus || _controller.text.isNotEmpty;

    if (newExpanded != _isExpanded) {
      setState(() {
        _isExpanded = newExpanded;
      });

      if (newExpanded) {
        _onExpand();
      } else {
        _onCollapse();
      }
    }
  }

  void _onExpand() {
    final timerState = ref.read(clockTimerProvider);

    // 如果计时器已开始且未暂停，则暂停
    if (timerState.isStarted && !timerState.isPaused) {
      ref.read(clockTimerProvider.notifier).pause();
    }
  }

  void _onCollapse() {
    // 收起时保持暂停状态（不自动继续）
    // 用户需要手动点击继续按钮
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // 监听焦点变化来检测展开状态
    return FocusScope(
      child: Focus(
        focusNode: _focusNode,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: FlexibleDescriptionInput(
              controller: _controller,
              softLimit: 200,
              hardLimit: 60000,
              hintText: l10n.clockTaskAnalysisHint,
              labelText: l10n.clockTaskAnalysis,
              buttonText: l10n.clockTaskAnalysis,
              minLines: 3,
              maxLines: 8,
              showCounter: true,
              onChanged: (text) {
                _onTextChanged();
                if (text.isNotEmpty && !_isExpanded) {
                  _isExpanded = true;
                  _onExpand();
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
