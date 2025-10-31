import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/tag_providers.dart';
import '../../../data/models/tag.dart';
import '../modern_tag.dart';
import '../tag_data.dart';

/// 抽屉标签区域组件
/// 显示标签分组（场景、四象限、执行方式）
class DrawerTagsSection extends ConsumerWidget {
  const DrawerTagsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 区域标题
          Text(
            '标签',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          
          // 场景标签组
          _buildTagGroup(
            context,
            ref,
            title: '场景',
            kind: TagKind.context,
          ),
          const SizedBox(height: 8),
          
          // 四象限标签组（紧急度 + 重要性）
          _buildQuadrantTagGroup(context, ref),
          const SizedBox(height: 8),
          
          // 执行方式标签组
          _buildTagGroup(
            context,
            ref,
            title: '执行方式',
            kind: TagKind.execution,
          ),
        ],
      ),
    );
  }

  /// 构建四象限标签组（合并紧急度和重要性）
  Widget _buildQuadrantTagGroup(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分组小标题
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            '四象限',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ),
        
        // 合并显示紧急度和重要性标签
        _buildQuadrantTagList(context, ref),
      ],
    );
  }

  /// 构建四象限标签列表（紧急度 + 重要性）
  Widget _buildQuadrantTagList(BuildContext context, WidgetRef ref) {
    final urgencyTagsAsync = ref.watch(tagsByKindProvider(TagKind.urgency));
    final importanceTagsAsync = ref.watch(tagsByKindProvider(TagKind.importance));
    
    return urgencyTagsAsync.when(
      data: (urgencyTags) => importanceTagsAsync.when(
        data: (importanceTags) {
          final allTags = [...urgencyTags, ...importanceTags];
          
          if (allTags.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                '暂无标签',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
          }
          
          return Wrap(
            spacing: 6,
            runSpacing: 6,
            children: allTags.map((tag) {
              final tagData = TagData.fromTagWithLocalization(tag, context);
              
              return ModernTag(
                label: tagData.label,
                color: tagData.color,
                icon: tagData.icon,
                prefix: tagData.prefix,
                variant: TagVariant.pill,
                size: TagSize.small,
                selected: false,
                showCheckmark: false,
                // 暂时不添加 onTap，纯展示
                // 以后需要时取消注释：
                // onTap: () => _handleTagTap(context, tag),
              );
            }).toList(),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(8.0),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (error, stack) {
          debugPrint('Error loading importance tags: $error');
          return Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '加载失败',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          );
        },
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(8.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, stack) {
        debugPrint('Error loading urgency tags: $error');
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '加载失败',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        );
      },
    );
  }

  /// 构建单个标签组
  Widget _buildTagGroup(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required TagKind kind,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分组小标题
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ),
        
        // 标签列表
        _buildTagList(context, ref, kind),
      ],
    );
  }

  /// 构建标签列表（使用 Provider）
  Widget _buildTagList(BuildContext context, WidgetRef ref, TagKind kind) {
    final tagsAsync = ref.watch(tagsByKindProvider(kind));
    
    return tagsAsync.when(
      data: (tags) {
        if (tags.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '暂无标签',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }
        
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: tags.map((tag) {
            final tagData = TagData.fromTagWithLocalization(tag, context);
            
            return ModernTag(
              label: tagData.label,
              color: tagData.color,
              icon: tagData.icon,
              prefix: tagData.prefix,
              variant: TagVariant.pill,
              size: TagSize.small,
              selected: false,
              showCheckmark: false,
              // 暂时不添加 onTap，纯展示
              // 以后需要时取消注释：
              // onTap: () => _handleTagTap(context, tag),
            );
          }).toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(8.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, stack) {
        debugPrint('Error loading tags for $kind: $error');
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '加载失败',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        );
      },
    );
  }
}