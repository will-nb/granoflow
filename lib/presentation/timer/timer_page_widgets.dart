import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../core/providers/template_providers.dart';
import '../../data/models/focus_session.dart';
import '../../data/models/task.dart';
import '../../data/models/task_template.dart';

/// TimerPage 辅助组件
/// 
/// 包含 TimerPage 使用的各种辅助组件
class TimerPageWidgets {
  /// 构建模板选择部分
  static Widget buildTemplatesSection(
    BuildContext context,
    WidgetRef ref,
    String templateQuery,
    ValueChanged<String> onQueryChanged,
    ValueChanged<TaskTemplate> onTemplateSelected,
  ) {
    final l10n = AppLocalizations.of(context);
    final templateSuggestions = ref.watch(
      templateSuggestionsProvider(TemplateSuggestionQuery(
        text: templateQuery.trim().isEmpty ? null : templateQuery,
        limit: 6,
      )),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.timerTemplatesTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            labelText: l10n.timerSearchTemplatesPlaceholder,
            border: const OutlineInputBorder(),
          ),
          onChanged: onQueryChanged,
        ),
        const SizedBox(height: 12),
        templateSuggestions.when(
          data: (templates) {
            if (templates.isEmpty) {
              return _EmptyTemplatesHint(message: l10n.timerTemplatesEmpty);
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: templates
                  .map(
                    (template) => ActionChip(
                      label: Text(template.title),
                      avatar: const Icon(Icons.auto_awesome_outlined),
                      onPressed: () => onTemplateSelected(template),
                    ),
                  )
                  .toList(growable: false),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => _ErrorCard(message: '$error'),
        ),
      ],
    );
  }

  /// 构建活动会话卡片
  static Widget buildActiveSessionCard(
    BuildContext context,
    Task task,
    FocusSession session,
    VoidCallback onEnd,
    String endLabel,
  ) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).timerActiveTitle(task.title),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            _ActiveSessionTicker(startedAt: session.startedAt),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onEnd,
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(endLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTemplatesHint extends StatelessWidget {
  const _EmptyTemplatesHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: Text(message),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      ),
    );
  }
}

class _ActiveSessionTicker extends StatefulWidget {
  const _ActiveSessionTicker({required this.startedAt});

  final DateTime startedAt;

  @override
  State<_ActiveSessionTicker> createState() => _ActiveSessionTickerState();
}

class _ActiveSessionTickerState extends State<_ActiveSessionTicker> {
  late StreamSubscription<int> _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _elapsed = _computeElapsed();
    _ticker = Stream<int>.periodic(
      const Duration(seconds: 1),
    ).listen((_) => setState(() => _elapsed = _computeElapsed()));
  }

  @override
  void didUpdateWidget(covariant _ActiveSessionTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startedAt != widget.startedAt) {
      setState(() => _elapsed = _computeElapsed());
    }
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final hours = _elapsed.inHours.toString().padLeft(2, '0');
    final seconds = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final text = '$hours:$minutes:$seconds';
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.displaySmall?.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  Duration _computeElapsed() {
    final now = DateTime.now();
    return now.difference(widget.startedAt);
  }
}

