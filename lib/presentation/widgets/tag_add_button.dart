import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../../generated/l10n/app_localizations.dart';
import 'tag_grouped_menu.dart';

/// 添加标签按钮，打开分组菜单选择标签
class TagAddButton extends StatelessWidget {
  const TagAddButton({
    super.key,
    required this.tagGroups,
    required this.onTagSelected,
  });

  final List<TagGroup> tagGroups;
  final ValueChanged<String> onTagSelected;

  bool get _isMobile {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  Future<void> _showTagMenu(BuildContext context) async {
    if (tagGroups.isEmpty) return;

    if (_isMobile) {
      // 移动端使用 BottomSheet
      await showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: TagGroupedMenu(
                tagGroups: tagGroups,
                onTagSelected: onTagSelected,
              ),
            ),
          ),
        ),
      );
    } else {
      // 桌面端使用 PopupMenu
      final RenderBox button = context.findRenderObject() as RenderBox;
      final RenderBox overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox;
      final RelativeRect position = RelativeRect.fromRect(
        Rect.fromPoints(
          button.localToGlobal(Offset.zero, ancestor: overlay),
          button.localToGlobal(
            button.size.bottomRight(Offset.zero),
            ancestor: overlay,
          ),
        ),
        Offset.zero & overlay.size,
      );

      await showMenu(
        context: context,
        position: position,
        items: [
          PopupMenuItem(
            enabled: false,
            padding: EdgeInsets.zero,
            child: SizedBox(
              width: 280,
              child: TagGroupedMenu(
                tagGroups: tagGroups,
                onTagSelected: onTagSelected,
              ),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (tagGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = theme.colorScheme.primary;

    // Minimal 风格：只有图标+文字，无背景
    return InkWell(
      onTap: () => _showTagMenu(context),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              l10n.taskAddTag,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
