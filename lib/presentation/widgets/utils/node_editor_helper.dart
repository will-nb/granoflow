import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../node_editor_dialog.dart';
import '../node_manager_dialog.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/providers/node_providers.dart';
import '../../../generated/l10n/app_localizations.dart';

/// 节点编辑工具类
/// 
/// 统一处理节点编辑弹窗的显示逻辑
/// 参考 RichTextDescriptionEditorHelper 的实现模式
class NodeEditorHelper {
  NodeEditorHelper._();

  /// 显示节点编辑弹窗
  /// 
  /// [context] BuildContext
  /// [ref] WidgetRef（用于访问 NodeService）
  /// [taskId] 任务 ID（必需）
  /// [parentId] 父节点 ID（可选，null 表示根节点，用于添加子节点）
  /// [nodeId] 节点 ID（可选，如果提供则进入编辑模式）
  /// [initialTitle] 初始标题（可选，用于编辑模式）
  /// [title] 弹窗标题（可选，默认从本地化文本读取）
  static Future<void> showNodeEditor(
    BuildContext context,
    WidgetRef ref, {
    required String taskId,
    String? parentId,
    String? nodeId,
    String? initialTitle,
    String? title,
  }) async {
    final l10n = AppLocalizations.of(context);
    // 如果提供了自定义标题，使用自定义标题；否则根据是否有 nodeId 判断
    final dialogTitle = title ??
        (nodeId != null
            ? l10n.nodeEditButton
            : l10n.nodeAddButton);

    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            NodeEditorDialog(
          initialTitle: initialTitle,
          onSave: (title) async {
            final nodeService = await ref.read(nodeServiceProvider.future);
            if (nodeId != null) {
              // 编辑模式：更新节点标题
              await nodeService.updateNodeTitle(nodeId, title);
            } else {
              // 添加模式：创建新节点
              await nodeService.createNode(
                taskId: taskId,
                title: title,
                parentId: parentId,
              );
            }
            // 刷新节点列表
            ref.invalidate(taskNodesProvider(taskId));
          },
          title: dialogTitle,
        ),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        fullscreenDialog: true,
        opaque: true,
      ),
    );
  }

  /// 显示节点管理弹窗（Things3 风格）
  /// 
  /// [context] BuildContext
  /// [ref] WidgetRef（用于访问 NodeService）
  /// [taskId] 任务 ID（必需）
  static Future<void> showNodeManager(
    BuildContext context,
    WidgetRef ref, {
    required String taskId,
  }) async {
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            NodeManagerDialog(taskId: taskId),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        fullscreenDialog: true,
        opaque: true,
      ),
    );
  }
}

