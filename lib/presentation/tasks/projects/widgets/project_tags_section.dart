import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../widgets/modern_tag.dart';
import '../../../widgets/modern_tag_group.dart';
import '../../../widgets/tag_data.dart';

/// 项目标签选择区域组件
/// 用于在项目创建表单中选择优先级和执行标签
class ProjectTagsSection extends ConsumerWidget {
  const ProjectTagsSection({
    super.key,
    required this.selectedUrgencyTag,
    required this.selectedImportanceTag,
    required this.executionTag,
    required this.onSelectionChanged,
  });

  final String? selectedUrgencyTag;
  final String? selectedImportanceTag;
  final String? executionTag;

  final void Function({
    String? urgencyTag,
    String? importanceTag,
    String? executionTag,
  }) onSelectionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urgencyTagsAsync = ref.watch(urgencyTagOptionsProvider);
    final importanceTagsAsync = ref.watch(importanceTagOptionsProvider);
    final executionTagsAsync = ref.watch(executionTagOptionsProvider);

    return urgencyTagsAsync.when(
      data: (urgencyTags) => importanceTagsAsync.when(
        data: (importanceTags) => executionTagsAsync.when(
          data: (executionTags) {
            final allTags = [
              ...urgencyTags,
              ...importanceTags,
              ...executionTags,
            ];
            final tagData = allTags
                .map((tag) => TagData.fromTagWithLocalization(tag, context))
                .toList(growable: false);
            final selectedTags = <String>{
              if (selectedUrgencyTag != null) selectedUrgencyTag!,
              if (selectedImportanceTag != null) selectedImportanceTag!,
              if (executionTag != null) executionTag!,
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
                    executionTag: null,
                  );
                } else {
                  final slug = selected.first;
                  if (urgencyTags.any((tag) => tag.slug == slug)) {
                    onSelectionChanged(
                      urgencyTag: slug,
                      importanceTag: null,
                      executionTag: null,
                    );
                  } else if (importanceTags.any((tag) => tag.slug == slug)) {
                    onSelectionChanged(
                      importanceTag: slug,
                      urgencyTag: null,
                      executionTag: null,
                    );
                  } else if (executionTags.any((tag) => tag.slug == slug)) {
                    onSelectionChanged(
                      executionTag: slug,
                      urgencyTag: null,
                      importanceTag: null,
                    );
                  }
                }
              },
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => const Text('加载标签失败'),
        ),
        loading: () => const CircularProgressIndicator(),
        error: (_, __) => const Text('加载标签失败'),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const Text('加载标签失败'),
    );
  }
}

