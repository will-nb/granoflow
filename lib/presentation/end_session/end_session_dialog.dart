import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../data/models/focus_session.dart';
import '../../data/models/task.dart';
import '../../generated/l10n/app_localizations.dart';

enum EndSessionSelection { complete, addSubtask, logMultiple, markWasted }

Future<FocusOutcome?> showEndSessionDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Task task,
  required FocusSession session,
}) {
  return showDialog<FocusOutcome>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _EndSessionDialog(task: task, session: session, ref: ref),
  );
}

class _EndSessionDialog extends StatefulWidget {
  const _EndSessionDialog({required this.task, required this.session, required this.ref});

  final Task task;
  final FocusSession session;
  final WidgetRef ref;

  @override
  State<_EndSessionDialog> createState() => _EndSessionDialogState();
}

class _EndSessionDialogState extends State<_EndSessionDialog> {
  EndSessionSelection _selection = EndSessionSelection.complete;
  final TextEditingController _reflectionController = TextEditingController();
  final TextEditingController _subtaskController = TextEditingController();
  final TextEditingController _multiTaskController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _reflectionController.dispose();
    _subtaskController.dispose();
    _multiTaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final duration = DateTime.now().difference(widget.session.startedAt);
    final estimate = widget.session.estimateMinutes;

    return AlertDialog(
      title: Text(l10n.endSessionTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SummaryRow(label: l10n.endSessionSummaryLabel, value: _formatDuration(duration)),
            if (estimate != null) ...[
              const SizedBox(height: 4),
              _SummaryRow(label: l10n.endSessionEstimateComparison, value: '$estimate min'),
            ],
            const SizedBox(height: 16),
            RadioGroup<EndSessionSelection>(
              groupValue: _selection,
              onChanged: (selection) {
                if (selection == null) {
                  return;
                }
                setState(() {
                  _selection = selection;
                  _error = null;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRadioOption(
                    context,
                    l10n.endSessionCompleteTask,
                    EndSessionSelection.complete,
                  ),
                  _buildRadioOption(
                    context,
                    l10n.endSessionAddSubtask,
                    EndSessionSelection.addSubtask,
                  ),
                  if (_selection == EndSessionSelection.addSubtask)
                    Padding(
                      padding: const EdgeInsets.only(left: 32, bottom: 12),
                      child: TextField(
                        controller: _subtaskController,
                        decoration: InputDecoration(
                          labelText: l10n.endSessionSubtaskTitleLabel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  _buildRadioOption(
                    context,
                    l10n.endSessionAddMultiple,
                    EndSessionSelection.logMultiple,
                  ),
                  if (_selection == EndSessionSelection.logMultiple)
                    Padding(
                      padding: const EdgeInsets.only(left: 32, bottom: 12),
                      child: TextField(
                        controller: _multiTaskController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: l10n.endSessionMultipleHint,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  _buildRadioOption(
                    context,
                    l10n.endSessionLogWasted,
                    EndSessionSelection.markWasted,
                  ),
                  if (_selection == EndSessionSelection.markWasted)
                    Padding(
                      padding: const EdgeInsets.only(left: 32, bottom: 12),
                      child: Text(
                        l10n.endSessionWastedNote,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reflectionController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.endSessionReflectionLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : () => _submit(context),
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.endSessionCloseButton),
        ),
      ],
    );
  }

  Widget _buildRadioOption(BuildContext context, String label, EndSessionSelection value) {
    final registry = RadioGroup.maybeOf<EndSessionSelection>(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Radio<EndSessionSelection>(value: value, groupRegistry: registry),
      title: Text(label),
      onTap: () {
        if (registry != null) {
          registry.onChanged(value);
        } else {
          setState(() {
            _selection = value;
            _error = null;
          });
        }
      },
    );
  }

  Future<void> _submit(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _error = null;
      _submitting = true;
    });

    final reflection = _reflectionController.text.trim().isEmpty
        ? null
        : _reflectionController.text.trim();
    final focusNotifier = widget.ref.read(focusActionsNotifierProvider.notifier);
    final navigator = Navigator.of(context);

    try {
      switch (_selection) {
        case EndSessionSelection.complete:
          await focusNotifier.end(
            sessionId: widget.session.id,
            outcome: FocusOutcome.complete,
            reflection: reflection,
          );
          navigator.pop(FocusOutcome.complete);
          break;
        case EndSessionSelection.addSubtask:
          final title = _subtaskController.text.trim();
          if (title.isEmpty) {
            setState(() {
              _error = l10n.endSessionSubtaskValidation;
              _submitting = false;
            });
            return;
          }
          await widget.ref
              .read(taskEditActionsNotifierProvider.notifier)
              .addSubtask(parentId: widget.task.id, title: title);
          await focusNotifier.end(
            sessionId: widget.session.id,
            outcome: FocusOutcome.complete,
            reflection: reflection,
          );
          navigator.pop(FocusOutcome.complete);
          break;
        case EndSessionSelection.logMultiple:
          final lines = _multiTaskController.text
              .split('\n')
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
              .toList();
          if (lines.isEmpty) {
            setState(() {
              _error = l10n.endSessionMultipleValidation;
              _submitting = false;
            });
            return;
          }
          final taskService = await widget.ref.read(taskServiceProvider.future);
          for (final line in lines) {
            await taskService.captureInboxTask(title: line);
          }
          await focusNotifier.end(
            sessionId: widget.session.id,
            outcome: FocusOutcome.complete,
            reflection: reflection,
          );
          navigator.pop(FocusOutcome.complete);
          break;
        case EndSessionSelection.markWasted:
          await focusNotifier.end(
            sessionId: widget.session.id,
            outcome: FocusOutcome.markWasted,
            reflection: reflection,
          );
          navigator.pop(FocusOutcome.markWasted);
          break;
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to finish session: $error\n$stackTrace');
      setState(() {
        _error = error.toString();
        _submitting = false;
      });
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textTheme.bodyMedium),
        Text(value, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
