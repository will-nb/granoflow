import 'package:flutter/material.dart';

import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';

class ClockSubtaskItem extends StatelessWidget {
  const ClockSubtaskItem({
    super.key,
    required this.subtask,
    required this.onStartTimer,
  });

  final Task subtask;
  final VoidCallback onStartTimer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                subtask.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonal(
              onPressed: onStartTimer,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    l10n.clockStartButton,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
