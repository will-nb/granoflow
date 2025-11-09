import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../data/models/focus_session.dart';
import '../../data/models/task.dart';
import '../../data/models/task_template.dart';
import '../navigation/navigation_destinations.dart';
import '../end_session/end_session_dialog.dart';
import '../widgets/page_app_bar.dart';
import '../widgets/main_drawer.dart';
import '../widgets/gradient_page_scaffold.dart';

class TimerPage extends ConsumerStatefulWidget {
  const TimerPage({super.key});

  @override
  ConsumerState<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends ConsumerState<TimerPage> {
  Task? _selectedTask;
  String _templateQuery = '';
  bool _startLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rootTasksAsync = ref.watch(rootTasksProvider);
    final templateQuery = _templateQuery.trim().isEmpty ? null : _templateQuery;
    final templateSuggestions = ref.watch(
      templateSuggestionsProvider(TemplateSuggestionQuery(text: templateQuery, limit: 6)),
    );
    final activeSessionAsync = _selectedTask == null
        ? const AsyncValue<FocusSession?>.data(null)
        : ref.watch(focusSessionProvider(_selectedTask!.id));

    return GradientPageScaffold(
      appBar: PageAppBar(title: l10n.actionStartTimer),
      drawer: const MainDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TaskSelectorCard(
              rootTasksAsync: rootTasksAsync,
              selectedTask: _selectedTask,
              onSelected: (task) => setState(() => _selectedTask = task),
              onNavigateToTaskList: () => _openTaskList(context),
            ),
            const SizedBox(height: 16),
            _StartControlsCard(
                onStart: _selectedTask == null
                    ? null
                    : () => _startFocus(_selectedTask!.id, l10n),
              loading: _startLoading,
              startLabel: l10n.actionStartTimer,
            ),
            const SizedBox(height: 16),
            activeSessionAsync.when(
              data: (session) => session == null
                  ? const _IdleSessionHint()
                  : _ActiveSessionCard(
                      task: _selectedTask!,
                      session: session,
                      onEnd: () => _handleEndSession(context, _selectedTask!, session, l10n),
                      endLabel: l10n.timerEndSession,
                    ),
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, stackTrace) => _ErrorCard(message: '$error'),
            ),
            const SizedBox(height: 24),
            Text(l10n.timerTemplatesTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: l10n.timerSearchTemplatesPlaceholder,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _templateQuery = value),
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
                          onPressed: () => _applyTemplate(context, template),
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
        ),
      ),
    );
  }

    Future<void> _startFocus(String taskId, AppLocalizations l10n) async {
    setState(() => _startLoading = true);
    final notifier = ref.read(focusActionsNotifierProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await notifier.start(taskId);
      ref.read(monetizationActionsNotifierProvider.notifier).registerPremiumHit();
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.taskListFocusStartedToast)));
    } catch (error, stackTrace) {
      debugPrint('Failed to start focus: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.taskListFocusError)));
    } finally {
      if (mounted) {
        setState(() => _startLoading = false);
      }
    }
  }

  Future<void> _applyTemplate(BuildContext context, TaskTemplate template) async {
    final service = ref.read(taskTemplateServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      final task = await service.applyTemplate(templateId: template.id);
      if (!mounted) {
        return;
      }
      setState(() => _selectedTask = task);
      await _startFocus(task.id, l10n);
    } catch (error, stackTrace) {
      debugPrint('Failed to apply template: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.timerTemplateApplyError)));
    }
  }

  Future<void> _handleEndSession(
    BuildContext context,
    Task task,
    FocusSession session,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await showEndSessionDialog(
      context: context,
      ref: ref,
      task: task,
      session: session,
    );
    if (!mounted || outcome == null) {
      return;
    }

    String message;
    switch (outcome) {
      case FocusOutcome.complete:
      case FocusOutcome.completeWithoutTimer:
        message = l10n.timerEndSessionSuccess;
        break;
      case FocusOutcome.addSubtask:
        message = l10n.timerEndSessionAddSubtask;
        break;
      case FocusOutcome.logMultiple:
        message = l10n.timerEndSessionAddMultiple;
        break;
      case FocusOutcome.markWasted:
        message = l10n.timerEndSessionLogWasted;
        break;
    }

    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _openTaskList(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.isFirst);
    ref.read(navigationIndexProvider.notifier).state = NavigationDestinations.tasks.index;
  }
}

class _TaskSelectorCard extends StatelessWidget {
  const _TaskSelectorCard({
    required this.rootTasksAsync,
    required this.selectedTask,
    required this.onSelected,
    required this.onNavigateToTaskList,
  });

  final AsyncValue<List<Task>> rootTasksAsync;
  final Task? selectedTask;
  final ValueChanged<Task> onSelected;
  final VoidCallback onNavigateToTaskList;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.timerSelectTaskTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            rootTasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.timerNoPlannedTasks),
                      const SizedBox(height: 8),
                      TextButton(onPressed: onNavigateToTaskList, child: Text(l10n.timerGoPlan)),
                    ],
                  );
                }
                final entries = tasks
                    .map((task) => DropdownMenuEntry<int>(value: task.id, label: task.title))
                    .toList(growable: false);
                final currentValue = selectedTask != null
                    ? tasks
                          .firstWhere((t) => t.id == selectedTask!.id, orElse: () => tasks.first)
                          .id
                    : tasks.first.id;
                if (selectedTask == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    onSelected(tasks.first);
                  });
                }
                return DropdownMenu<int>(
                  initialSelection: currentValue,
                  dropdownMenuEntries: entries,
                  onSelected: (value) {
                    if (value == null) {
                      return;
                    }
                    final task = tasks.firstWhere((element) => element.id == value);
                    onSelected(task);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _ErrorCard(message: '$error'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartControlsCard extends StatelessWidget {
  const _StartControlsCard({
    required this.onStart,
    required this.loading,
    required this.startLabel,
  });

  final VoidCallback? onStart;
  final bool loading;
  final String startLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.timerControlTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: loading ? null : onStart,
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(startLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveSessionCard extends StatelessWidget {
  const _ActiveSessionCard({
    required this.task,
    required this.session,
    required this.onEnd,
    required this.endLabel,
  });

  final Task task;
  final FocusSession session;
  final VoidCallback onEnd;
  final String endLabel;

  @override
  Widget build(BuildContext context) {
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
      ).textTheme.displaySmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
    );
  }

  Duration _computeElapsed() {
    final now = DateTime.now();
    return now.difference(widget.startedAt);
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

class _IdleSessionHint extends StatelessWidget {
  const _IdleSessionHint();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.timerIdleTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l10n.timerIdleHint),
          ],
        ),
      ),
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
          ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onErrorContainer),
        ),
      ),
    );
  }
}
