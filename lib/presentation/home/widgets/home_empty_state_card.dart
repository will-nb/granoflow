import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

enum HomeEmptyStateCardVariant { primary, embedded }

class HomeEmptyStateCard extends StatelessWidget {
  const HomeEmptyStateCard({
    super.key,
    required this.title,
    required this.description,
    required this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.maxWidth,
    this.variant = HomeEmptyStateCardVariant.primary,
  });

  final String title;
  final String description;
  final String primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final double? maxWidth;
  final HomeEmptyStateCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final padding = switch (variant) {
      HomeEmptyStateCardVariant.primary => const EdgeInsets.all(32),
      HomeEmptyStateCardVariant.embedded => const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 20,
      ),
    };

    final double baseIllustrationHeight = switch (variant) {
      HomeEmptyStateCardVariant.primary => 220,
      HomeEmptyStateCardVariant.embedded => 160,
    };

    final BorderRadius borderRadius = switch (variant) {
      HomeEmptyStateCardVariant.primary => BorderRadius.circular(28),
      HomeEmptyStateCardVariant.embedded => BorderRadius.circular(20),
    };

    final BoxDecoration decoration = switch (variant) {
      HomeEmptyStateCardVariant.primary => BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.35),
            colorScheme.secondaryContainer.withValues(alpha: 0.25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius,
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      HomeEmptyStateCardVariant.embedded => BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: borderRadius,
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
    };

    final Widget primaryButton = FilledButton(
      onPressed: onPrimaryAction,
      child: Text(primaryActionLabel),
    );

    final Widget? secondaryButton = (secondaryActionLabel != null && onSecondaryAction != null)
        ? TextButton(onPressed: onSecondaryAction, child: Text(secondaryActionLabel!))
        : null;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: DecoratedBox(
            decoration: decoration,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: variant == HomeEmptyStateCardVariant.primary ? 12 : 6,
                sigmaY: variant == HomeEmptyStateCardVariant.primary ? 12 : 6,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool hasTightHeight = constraints.maxHeight.isFinite;
                  final double resolvedIllustrationHeight = () {
                    if (!hasTightHeight) {
                      return baseIllustrationHeight;
                    }
                    final double estimatedBodyHeight = variant == HomeEmptyStateCardVariant.primary
                        ? 200
                        : 160;
                    final double available =
                        constraints.maxHeight - padding.vertical - estimatedBodyHeight;
                    if (available.isFinite) {
                      return math.max(120, math.min(baseIllustrationHeight, available)).toDouble();
                    }
                    return baseIllustrationHeight;
                  }();

                  final column = Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Image.asset(
                          'assets/images/homepage_empty_data.png',
                          height: resolvedIllustrationHeight,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      Text(
                        title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        description,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        children: [primaryButton, if (secondaryButton != null) secondaryButton],
                      ),
                    ],
                  );

                  if (hasTightHeight) {
                    return SingleChildScrollView(
                      padding: padding,
                      physics: const BouncingScrollPhysics(),
                      child: column,
                    );
                  }

                  return Padding(padding: padding, child: column);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
