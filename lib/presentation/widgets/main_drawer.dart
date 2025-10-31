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
import '../../core/providers/app_providers.dart';

/// 主抽屉组件
/// 显示页面导航选项和标签分组，由主菜单按钮控制
class MainDrawer extends ConsumerWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundImage = isDarkMode
        ? 'assets/images/background.dark.webp'
        : 'assets/images/background.light.webp';

    return Drawer(
      child: Column(
        children: [
          // 美化的 Drawer Header，使用背景图片，覆盖系统状态栏
          Container(
            height: 70 + MediaQuery.of(context).padding.top, // 添加状态栏高度
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
                // 内容区域 - 使用 SafeArea 确保内容不被状态栏遮挡
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                      SizedBox(
                        height: 20.0, // 从 24.0 减少到 20.0
                        width: 20.0,  // 从 24.0 减少到 20.0
                        child: const AppLogo(
                          size: 20.0, // 从 24.0 减少到 20.0
                          showText: false,
                          variant: AppLogoVariant.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 10), // 从 12 减少到 10
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                l10n.homeGreeting,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                  height: 1.1, // 减少行高以节省空间
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                      color: Colors.black.withValues(alpha: 0.5),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 0.5), // 进一步减少间距
                            Flexible(
                              child: Text(
                                l10n.homeTagline,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.2,
                                  height: 1.1, // 减少行高以节省空间
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 1),
                                      blurRadius: 1,
                                      color: Colors.black.withValues(alpha: 0.3),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 可滚动的内容区域
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
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
                
                // 项目预览区域
                const Divider(height: 1),
                buildProjectsSection(context, ref),
                
                // 标签分组展示
                const Divider(height: 1),
                _buildTagsSection(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建标签分组区域
  Widget _buildTagsSection(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // 减少垂直间距
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
          const SizedBox(height: 8), // 从 16 减少到 8
          
          // 场景标签组
          _buildTagGroup(
            context,
            ref,
            title: '场景',
            kind: TagKind.context,
          ),
          const SizedBox(height: 8), // 从 16 减少到 8
          
          // 四象限标签组（紧急度 + 重要性）
          _buildQuadrantTagGroup(context, ref),
          const SizedBox(height: 8), // 从 16 减少到 8
          
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
          padding: const EdgeInsets.only(left: 4, bottom: 4), // 从 8 减少到 4
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
            spacing: 6, // 从 8 减少到 6
            runSpacing: 6, // 从 8 减少到 6
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
          padding: const EdgeInsets.only(left: 4, bottom: 4), // 从 8 减少到 4
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
          spacing: 6, // 从 8 减少到 6
          runSpacing: 6, // 从 8 减少到 6
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

  /// 构建项目预览区域
  Widget buildProjectsSection(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 区域标题
          Row(
            children: [
              Text(
                '最近项目',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/projects');
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '查看全部',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // 项目列表
          projectsAsync.when(
            data: (projects) {
              if (projects.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '暂无项目',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }
              
              // 只显示前3个项目
              final displayProjects = projects.take(3).toList();
              return Column(
                children: displayProjects.map((project) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/projects');
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                project.title,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (project.dueAt != null)
                              Text(
                                _formatProjectDueDate(project.dueAt!),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                '加载失败',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化项目截止日期
  String _formatProjectDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    
    if (difference < 0) {
      return '已逾期';
    } else if (difference == 0) {
      return '今天';
    } else if (difference == 1) {
      return '明天';
    } else if (difference <= 7) {
      return '${difference}天后';
    } else {
      return '${dueDate.month}/${dueDate.day}';
    }
  }

  // 以后需要添加链接时，取消注释并实现这个方法
  // void _handleTagTap(BuildContext context, Tag tag) {
  //   Navigator.of(context).pop();
  //   context.go('/tasks?tag=${tag.slug}');
  // }
}
