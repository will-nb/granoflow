import 'package:flutter/material.dart';

Widget projectSwipeBackground({
  required Color color,
  required IconData icon,
  required String label,
  required Alignment alignment,
}) {
  return Container(
    alignment: alignment,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(24),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

