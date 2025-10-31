import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io' show Platform;
import '../../generated/l10n/app_localizations.dart';
import 'project_milestone_menu.dart';

/// 项目/里程碑选择器按钮
/// 风格与 TagAddButton 一致，支持选择项目或里程碑
class ProjectMilestonePicker extends ConsumerWidget {
  const ProjectMilestonePicker({
    super.key,
    required this.onSelected,
    this.currentParentId,
  });

  /// 选择回调：传入选中的任务ID（项目或里程碑），或 null（表示移出）
  final ValueChanged<int?> onSelected;

  /// 当前任务的父任务ID（如果有）
  final int? currentParentId;

  bool get _isMobile {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  /// Show the project/milestone picker menu
  Future<void> showPickerMenu(BuildContext context, WidgetRef ref) async {
    if (_isMobile) {
      // 移动端使用 BottomSheet
      await showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ProjectMilestoneMenu(
                onSelected: (taskId) {
                  Navigator.pop(context);
                  onSelected(taskId);
                },
                currentParentId: currentParentId,
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
              child: ProjectMilestoneMenu(
                onSelected: (taskId) {
                  Navigator.pop(context);
                  onSelected(taskId);
                },
                currentParentId: currentParentId,
              ),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = theme.colorScheme.primary;

    // Minimal 风格：只有图标+文字，无背景
    return InkWell(
      onTap: () => showPickerMenu(context, ref),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              l10n.taskAddToProject,
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

