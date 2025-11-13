import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../../widgets/modern_tag.dart';
import '../../../widgets/modern_tag_group.dart';
import '../../../widgets/tag_data.dart';

/// 项目标签选择区域组件
/// 用于在项目创建表单中选择优先级标签
class ProjectTagsSection extends ConsumerWidget {
  const ProjectTagsSection({
    super.key,
    required this.selectedUrgencyTag,
    required this.selectedImportanceTag,
    required this.onSelectionChanged,
  });

  final String? selectedUrgencyTag;
  final String? selectedImportanceTag;

  final void Function({
    String? urgencyTag,
    String? importanceTag,
  }) onSelectionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final urgencyTagsAsync = ref.watch(urgencyTagOptionsProvider);
    final importanceTagsAsync = ref.watch(importanceTagOptionsProvider);

    return urgencyTagsAsync.when(
      data: (urgencyTags) => importanceTagsAsync.when(
        data: (importanceTags) {
          final allTags = [
            ...urgencyTags,
            ...importanceTags,
          ];
          final tagData = allTags
              .map((tag) => TagData.fromTagWithLocalization(tag, context))
              .toList(growable: false);
          final selectedTags = <String>{
            if (selectedUrgencyTag != null) selectedUrgencyTag!,
            if (selectedImportanceTag != null) selectedImportanceTag!,
          };

          return ModernTagGroup(
            tags: tagData,
            selectedTags: selectedTags,
            multiSelect: false,
            variant: TagVariant.pill,
            size: TagSize.medium,
            onSelectionChanged: (selected) {
              if (selected.isEmpty) {
                onSelectionChanged(
                  urgencyTag: null,
                  importanceTag: null,
                );
              } else {
                final slug = selected.first;
                if (urgencyTags.any((tag) => tag.slug == slug)) {
                  onSelectionChanged(
                    urgencyTag: slug,
                    importanceTag: null,
                  );
                } else if (importanceTags.any((tag) => tag.slug == slug)) {
                  onSelectionChanged(
                    importanceTag: slug,
                    urgencyTag: null,
                  );
                }
              }
            },
          );
        },
        loading: () => const CircularProgressIndicator(),
        error: (_, __) => Text(l10n.loadTagsFailed),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => Text(l10n.loadTagsFailed),
    );
  }
}

