import 'package:flutter/material.dart';

class EmptySectionHint extends StatelessWidget {
  const EmptySectionHint({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(color: color),
        textAlign: TextAlign.center,
      ),
    );
  }
}

