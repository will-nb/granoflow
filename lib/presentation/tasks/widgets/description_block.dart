import 'package:flutter/material.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';

class DescriptionBlock extends StatefulWidget {
  const DescriptionBlock({super.key, required this.description, this.trim = 255});

  final String description;
  final int trim;

  @override
  State<DescriptionBlock> createState() => _DescriptionBlockState();
}

class _DescriptionBlockState extends State<DescriptionBlock> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final needsTrim = widget.description.length > widget.trim;
    final text = !_expanded && needsTrim
        ? widget.description.substring(0, widget.trim).trimRight() + '…'
        : widget.description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: theme.textTheme.bodyMedium,
        ),
        if (needsTrim)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded
                  ? l10n.projectDescriptionShowLess
                  : l10n.projectDescriptionShowMore,
            ),
          ),
      ],
    );
  }
}

