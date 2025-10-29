import 'package:flutter/material.dart';
import 'tag_data.dart';

/// 标签组信息
class TagGroup {
  const TagGroup({
    required this.title,
    required this.tags,
  });

  final String title;
  final List<TagData> tags;
}

/// 按标签组分组的菜单，支持同组互斥选择
class TagGroupedMenu extends StatelessWidget {
  const TagGroupedMenu({
    super.key,
    required this.tagGroups,
    required this.onTagSelected,
  });

  final List<TagGroup> tagGroups;
  final ValueChanged<String> onTagSelected;

  @override
  Widget build(BuildContext context) {
    if (tagGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < tagGroups.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          _TagGroupSection(
            group: tagGroups[i],
            onTagSelected: onTagSelected,
          ),
        ],
      ],
    );
  }
}

class _TagGroupSection extends StatelessWidget {
  const _TagGroupSection({
    required this.group,
    required this.onTagSelected,
  });

  final TagGroup group;
  final ValueChanged<String> onTagSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            group.title,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...group.tags.map((tagData) => ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Icon(
                tagData.icon,
                size: 20,
                color: tagData.color,
              ),
              title: Text(
                tagData.label,
                style: theme.textTheme.bodyMedium,
              ),
              onTap: () {
                Navigator.pop(context);
                onTagSelected(tagData.slug);
              },
            )),
      ],
    );
  }
}
