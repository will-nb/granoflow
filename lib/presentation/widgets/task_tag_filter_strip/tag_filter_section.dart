import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/models/tag.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../modern_tag.dart';
import '../tag_data.dart';

/// 标签筛选区域组件
/// 包含场景标签和优先级标签的筛选
class TagFilterSection extends ConsumerWidget {
  const TagFilterSection({
    super.key,
    required this.filterProvider,
  });

  final StateNotifierProvider<TaskFilterNotifier, TaskFilterState>
      filterProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(filterProvider);
    final contextTagsAsync = ref.watch(contextTagOptionsProvider);
    final urgencyTagsAsync = ref.watch(urgencyTagOptionsProvider);
    final importanceTagsAsync = ref.watch(importanceTagOptionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 场景标签筛选
        contextTagsAsync.when(
          data: (tags) => _buildContextTags(context, ref, filter, tags),
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 8),
        // 紧急度和重要度标签筛选
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
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildContextTags(
    BuildContext context,
    WidgetRef ref,
    TaskFilterState filter,
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
                ref.read(filterProvider.notifier).setContextTag(
                      isSelected ? null : tagData.slug,
                    );
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
    TaskFilterState filter,
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
              ref.read(filterProvider.notifier).setUrgencyTag(
                    isSelected ? null : tagData.slug,
                  );
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
              ref.read(filterProvider.notifier).setImportanceTag(
                    isSelected ? null : tagData.slug,
                  );
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
            onPressed: () => ref.read(filterProvider.notifier).reset(),
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

