import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../data/models/tag.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/modern_tag.dart';
import '../../widgets/tag_data.dart';

class InboxTagFilterStrip extends ConsumerWidget {
  const InboxTagFilterStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(inboxFilterProvider);
    final contextTagsAsync = ref.watch(contextTagOptionsProvider);
    final urgencyTagsAsync = ref.watch(urgencyTagOptionsProvider);
    final importanceTagsAsync = ref.watch(importanceTagOptionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        contextTagsAsync.when(
          data: (tags) => _buildContextTags(context, ref, filter, tags),
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => ErrorBanner(message: '$error'),
        ),
        const SizedBox(height: 8),
        urgencyTagsAsync.when(
          data: (urgencyTags) => importanceTagsAsync.when(
            data: (importanceTags) => _buildPriorityTags(
              context,
              ref,
              filter,
              urgencyTags,
              importanceTags,
            ),
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => ErrorBanner(message: '$error'),
          ),
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => ErrorBanner(message: '$error'),
        ),
      ],
    );
  }

  Widget _buildContextTags(
    BuildContext context,
    WidgetRef ref,
    InboxFilterState filter,
    List<Tag> tags,
  ) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }
    final tagDataList = tags
        .map((tag) => TagData.fromTagWithLocalization(tag, context))
        .toList(growable: false);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tagDataList.map((tagData) {
          final isSelected = filter.contextTag == tagData.slug;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ModernTag(
              label: tagData.label,
              color: tagData.color,
              icon: tagData.icon,
              prefix: tagData.prefix,
              selected: isSelected,
              variant: TagVariant.dot,
              size: TagSize.medium,
              showCheckmark: false,
              onTap: () {
                ref
                    .read(inboxFilterProvider.notifier)
                    .setContextTag(isSelected ? null : tagData.slug);
              },
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  Widget _buildPriorityTags(
    BuildContext context,
    WidgetRef ref,
    InboxFilterState filter,
    List<Tag> urgencyTags,
    List<Tag> importanceTags,
  ) {
    final l10n = AppLocalizations.of(context);
    final widgets = <Widget>[];

    widgets.addAll(
      urgencyTags.map((tag) {
        final tagData = TagData.fromTagWithLocalization(tag, context);
        final isSelected = filter.urgencyTag == tagData.slug;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ModernTag(
            label: tagData.label,
            color: tagData.color,
            icon: tagData.icon,
            prefix: tagData.prefix,
            selected: isSelected,
            variant: TagVariant.dot,
            size: TagSize.medium,
            showCheckmark: false,
            onTap: () {
              ref
                  .read(inboxFilterProvider.notifier)
                  .setUrgencyTag(isSelected ? null : tagData.slug);
            },
          ),
        );
      }),
    );

    widgets.addAll(
      importanceTags.map((tag) {
        final tagData = TagData.fromTagWithLocalization(tag, context);
        final isSelected = filter.importanceTag == tagData.slug;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ModernTag(
            label: tagData.label,
            color: tagData.color,
            icon: tagData.icon,
            prefix: tagData.prefix,
            selected: isSelected,
            variant: TagVariant.dot,
            size: TagSize.medium,
            showCheckmark: false,
            onTap: () {
              ref
                  .read(inboxFilterProvider.notifier)
                  .setImportanceTag(isSelected ? null : tagData.slug);
            },
          ),
        );
      }),
    );

    if (filter.hasFilters) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ActionChip(
            label: Text(l10n.inboxFilterReset),
            avatar: Icon(
              Icons.clear_all,
              size: 16,
              color: Theme.of(context).colorScheme.error,
            ),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            onPressed: () => ref.read(inboxFilterProvider.notifier).reset(),
          ),
        ),
      );
    }

    if (widgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: widgets),
    );
  }
}

