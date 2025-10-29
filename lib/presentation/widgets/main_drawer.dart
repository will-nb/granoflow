import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:granoflow/generated/l10n/app_localizations.dart';
import '../navigation/sidebar_destinations.dart';
import 'app_logo.dart';
import 'modern_tag.dart';
import 'tag_data.dart';
import '../../data/models/tag.dart';
import '../../core/providers/tag_providers.dart';

/// 主抽屉组件
/// 显示页面导航选项和标签分组，由主菜单按钮控制
class MainDrawer extends ConsumerWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundImage = isDarkMode
        ? 'assets/images/background.dark.png'
        : 'assets/images/background.light.png';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 美化的 Drawer Header，使用背景图片
          Container(
            height: 200,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(backgroundImage),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                // 半透明遮罩，提升文字可读性
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
                // 内容区域
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo 和标题
                      Row(
                        children: [
                          // Logo 容器：向下延伸 2px，宽度同步扩大
                          SizedBox(
                            height: 30.0, // 从 28.0 增加到 30.0（向下延伸 2px）
                            width: 30.0,  // 宽度同步扩大
                            child: const AppLogo(
                              size: 30.0,  // 同步扩大
                              showText: false,
                              variant: AppLogoVariant.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 修复：将 Expanded 放在 Row 的直接子级，而不是 Transform 内部
                          Expanded(
                            child: Transform.translate(
                              offset: const Offset(-5.0, 0.0),
                              child: Text(
                                l10n.homeGreeting,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                      color: Colors.black.withValues(alpha: 0.5),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4), // 减少间距以解决溢出问题
                      // Tagline
                      Text(
                        l10n.homeTagline,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                          height: 1.4,
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black.withValues(alpha: 0.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 导航选项列表
          ...SidebarDestinations.values.map((destination) {
            return ListTile(
              leading: Icon(
                destination.icon,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              title: Text(
                destination.label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                // 处理路由跳转
                context.go(destination.route);
              },
            );
          }).toList(),
          
          // 标签分组展示
          const Divider(height: 1),
          _buildTagsSection(context, ref),
        ],
      ),
    );
  }

  /// 构建标签分组区域
  Widget _buildTagsSection(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
          const SizedBox(height: 16),
          
          // 场景标签组
          _buildTagGroup(
            context,
            ref,
            title: '场景',
            kind: TagKind.context,
          ),
          const SizedBox(height: 16),
          
          // 四象限标签组（紧急度 + 重要性）
          _buildQuadrantTagGroup(context, ref),
          const SizedBox(height: 16),
          
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
          padding: const EdgeInsets.only(left: 4, bottom: 8),
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
            spacing: 8,
            runSpacing: 8,
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
          padding: const EdgeInsets.only(left: 4, bottom: 8),
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
          spacing: 8,
          runSpacing: 8,
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

  // 以后需要添加链接时，取消注释并实现这个方法
  // void _handleTagTap(BuildContext context, Tag tag) {
  //   Navigator.of(context).pop();
  //   context.go('/tasks?tag=${tag.slug}');
  // }
}
