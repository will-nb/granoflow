import 'package:flutter/material.dart';

import '../../data/models/tag.dart';
import 'modern_tag.dart';
import 'modern_tag_group.dart';
import 'tag_data.dart';

/// 标签面板
/// 
/// 用于展示和选择上下文标签和优先级标签
class TagPanel extends StatelessWidget {
  const TagPanel({
    super.key,
    required this.contextTags,
    required this.priorityTags,
    required this.localeName,
    required this.selectedContext,
    required this.selectedPriority,
    required this.onContextChanged,
    required this.onPriorityChanged,
  });

  /// 上下文标签列表
  final List<Tag> contextTags;
  
  /// 优先级标签列表
  final List<Tag> priorityTags;
  
  /// 当前语言环境（用于标签本地化）
  final String localeName;
  
  /// 已选中的上下文标签
  final String? selectedContext;
  
  /// 已选中的优先级标签
  final String? selectedPriority;
  
  /// 上下文标签变化回调
  final ValueChanged<String?> onContextChanged;
  
  /// 优先级标签变化回调
  final ValueChanged<String?> onPriorityChanged;

  @override
  Widget build(BuildContext context) {
    // 转换为 TagData
    final contextTagData = contextTags
        .map((tag) => TagData.fromTag(tag, localeName))
        .toList();
    final priorityTagData = priorityTags
        .map((tag) => TagData.fromTag(tag, localeName))
        .toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ModernTagGroup(
          tags: contextTagData,
          selectedTags: {if (selectedContext != null) selectedContext!},
          onSelectionChanged: (values) {
            onContextChanged(values.isEmpty ? null : values.first);
          },
          variant: TagVariant.pill,
          size: TagSize.medium,
          multiSelect: false,
        ),
        const SizedBox(height: 12),
        ModernTagGroup(
          tags: priorityTagData,
          selectedTags: {if (selectedPriority != null) selectedPriority!},
          onSelectionChanged: (values) {
            onPriorityChanged(values.isEmpty ? null : values.first);
          },
          variant: TagVariant.pill,
          size: TagSize.medium,
          multiSelect: false,
        ),
      ],
    );
  }
}
