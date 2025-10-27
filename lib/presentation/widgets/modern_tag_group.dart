import 'package:flutter/material.dart';

import 'modern_tag.dart';
import 'tag_data.dart';

/// 标签组容器
/// 
/// 管理多个标签的布局和选择逻辑
class ModernTagGroup extends StatelessWidget {
  const ModernTagGroup({
    super.key,
    required this.tags,
    required this.selectedTags,
    required this.onSelectionChanged,
    this.multiSelect = false,
    this.variant = TagVariant.pill,
    this.size = TagSize.medium,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
  });

  /// 标签数据列表
  final List<TagData> tags;
  
  /// 已选中的标签 slugs
  final Set<String> selectedTags;
  
  /// 选择变化回调
  final ValueChanged<Set<String>> onSelectionChanged;
  
  /// 是否支持多选
  final bool multiSelect;
  
  /// 标签变体
  final TagVariant variant;
  
  /// 标签尺寸
  final TagSize size;
  
  /// 标签间距
  final double spacing;
  
  /// 行间距
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: tags.map((tagData) {
        final isSelected = selectedTags.contains(tagData.slug);
        return ModernTag(
          label: tagData.label,
          color: tagData.color,
          icon: tagData.icon,
          prefix: tagData.prefix,
          selected: isSelected,
          variant: variant,
          size: size,
          onTap: () => _handleTap(tagData.slug, isSelected),
        );
      }).toList(),
    );
  }

  /// 处理标签点击，支持单选和多选
  void _handleTap(String slug, bool isCurrentlySelected) {
    final updated = Set<String>.from(selectedTags);
    if (multiSelect) {
      if (isCurrentlySelected) {
        updated.remove(slug);
      } else {
        updated.add(slug);
      }
    } else {
      updated.clear();
      if (!isCurrentlySelected) {
        updated.add(slug);
      }
    }
    onSelectionChanged(updated);
  }
}

