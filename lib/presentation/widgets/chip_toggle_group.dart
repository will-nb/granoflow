import 'package:flutter/material.dart';

@immutable
class ChipToggleOption {
  const ChipToggleOption({
    required this.value,
    required this.label,
    this.icon,
  });

  final String value;
  final String label;
  final IconData? icon;
}

class ChipToggleGroup extends StatelessWidget {
  const ChipToggleGroup({
    super.key,
    required this.options,
    required this.selectedValues,
    required this.onSelectionChanged,
    this.multiSelect = false,
    this.spacing = 8,
    this.runSpacing = 8,
  });

  final List<ChipToggleOption> options;
  final Set<String> selectedValues;
  final ValueChanged<Set<String>> onSelectionChanged;
  final bool multiSelect;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: options.map((option) {
        final selected = selectedValues.contains(option.value);
        return FilterChip(
          label: Text(option.label),
          avatar: option.icon != null ? Icon(option.icon) : null,
          selected: selected,
          onSelected: (_) => _handleTap(option.value, selected),
        );
      }).toList(growable: false),
    );
  }

  void _handleTap(String value, bool isCurrentlySelected) {
    final updated = Set<String>.from(selectedValues);
    if (multiSelect) {
      if (isCurrentlySelected) {
        updated.remove(value);
      } else {
        updated.add(value);
      }
    } else {
      updated
        ..clear()
        ..add(value);
      if (isCurrentlySelected) {
        updated.clear();
      }
    }
    onSelectionChanged(updated);
  }
}
