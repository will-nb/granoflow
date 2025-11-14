import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/node.dart';
import '../../data/models/task.dart';
import '../../core/providers/node_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../generated/l10n/app_localizations.dart';
import '../widgets/utils/node_editor_helper.dart';
import 'dismissible_node_tile.dart';

/// 任务节点列表组件
class TaskNodesList extends ConsumerStatefulWidget {
  const TaskNodesList({
    super.key,
    required this.task,
  });

  final Task task;

  @override
  ConsumerState<TaskNodesList> createState() => _TaskNodesListState();
}

class _TaskNodesListState extends ConsumerState<TaskNodesList> {
  bool _isCollapsed = false;
  String? _editingNodeId;
  final Map<String, TextEditingController> _editingControllers = {};
  final Map<String, FocusNode> _editingFocusNodes = {};

  @override
  Widget build(BuildContext context) {
    final nodesAsync = ref.watch(taskNodesProvider(widget.task.id));

    return nodesAsync.when(
      data: (nodes) {
        // 过滤掉已删除的节点（根据设计，已删除的节点应该显示，但这里先显示所有节点）
        final visibleNodes = nodes.where((n) => n.status != NodeStatus.deleted || true).toList();
        
        // 如果节点列表为空，显示空状态
        if (visibleNodes.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 折叠/展开按钮（如果有子节点）
            if (_hasChildren(visibleNodes))
              _buildCollapseButton(context),
            // 分隔线
            if (visibleNodes.isNotEmpty)
              const Divider(height: 24),
            // 节点树
            if (!_isCollapsed)
              _buildNodesTree(context, visibleNodes),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCollapseButton(BuildContext context) {
    return IconButton(
      icon: Icon(_isCollapsed ? Icons.expand_more : Icons.expand_less),
      onPressed: () {
        setState(() {
          _isCollapsed = !_isCollapsed;
        });
      },
    );
  }

  bool _hasChildren(List<Node> nodes) {
    return nodes.any((n) => n.parentId != null);
  }

  Widget _buildNodesTree(BuildContext context, List<Node> nodes) {
    // 构建根节点列表
    final rootNodes = nodes.where((n) => n.parentId == null).toList();
    rootNodes.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

    if (rootNodes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: rootNodes.map((node) => _buildNodeItem(context, node, nodes, 0)).toList(),
    );
  }

  Widget _buildNodeItem(BuildContext context, Node node, List<Node> allNodes, int depth) {
    final children = allNodes.where((n) => n.parentId == node.id).toList();
    children.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 节点瓦片（内联编辑或普通显示）
        _editingNodeId == node.id
            ? _buildEditingNodeTile(context, node, depth, theme, colorScheme, l10n)
            : DismissibleNodeTile(
                node: node,
                depth: depth,
                onTap: () {
                  setState(() {
                    _editingNodeId = node.id;
                  });
                  // 初始化编辑控制器
                  if (!_editingControllers.containsKey(node.id)) {
                    _editingControllers[node.id] = TextEditingController(text: node.title);
                    _editingFocusNodes[node.id] = FocusNode();
                    _editingFocusNodes[node.id]!.addListener(() {
                      if (!_editingFocusNodes[node.id]!.hasFocus && _editingNodeId == node.id) {
                        _saveNodeTitle(node.id);
                      }
                    });
                  } else {
                    // 更新控制器文本为最新值
                    _editingControllers[node.id]!.text = node.title;
                  }
                  // 自动聚焦
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _editingFocusNodes[node.id]?.requestFocus();
                  });
                },
                onAddChild: () async {
                  await NodeEditorHelper.showNodeEditor(
                    context,
                    ref,
                    taskId: widget.task.id,
                    parentId: node.id,
                  );
                },
                onStatusChange: (status) => _updateNodeStatus(node.id, status),
              ),
        // 子节点
        if (children.isNotEmpty)
          ...children.map((child) => _buildNodeItem(context, child, allNodes, depth + 1)),
      ],
    );
  }


  @override
  void dispose() {
    for (final controller in _editingControllers.values) {
      controller.dispose();
    }
    for (final focusNode in _editingFocusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _updateNodeStatus(String nodeId, NodeStatus status) async {
    try {
      final nodeService = await ref.read(nodeServiceProvider.future);
      if (status == NodeStatus.deleted) {
        await nodeService.deleteNode(nodeId);
      } else {
        await nodeService.updateNodeStatus(nodeId, status);
      }
      // 刷新节点列表
      ref.invalidate(taskNodesProvider(widget.task.id));
    } catch (e) {
      // 错误处理
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update node: $e')),
        );
      }
    }
  }

  Widget _buildEditingNodeTile(
    BuildContext context,
    Node node,
    int depth,
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    if (!_editingControllers.containsKey(node.id)) {
      _editingControllers[node.id] = TextEditingController(text: node.title);
      _editingFocusNodes[node.id] = FocusNode();
      _editingFocusNodes[node.id]!.addListener(() {
        if (!_editingFocusNodes[node.id]!.hasFocus && _editingNodeId == node.id) {
          _saveNodeTitle(node.id);
        }
      });
    } else {
      // 确保控制器文本与节点标题同步
      if (_editingControllers[node.id]!.text != node.title) {
        _editingControllers[node.id]!.text = node.title;
      }
    }

    return Padding(
      padding: EdgeInsets.only(
        left: depth * 24.0 + 16.0,
        right: 16.0,
        top: 8.0,
        bottom: 8.0,
      ),
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
            setState(() {
              _editingNodeId = null;
            });
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: _editingControllers[node.id],
          focusNode: _editingFocusNodes[node.id],
          decoration: InputDecoration(
            hintText: l10n.nodeTitleHint,
            border: UnderlineInputBorder(
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 1.5,
              ),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 1.5,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            isDense: true,
          ),
          style: theme.textTheme.bodyMedium,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _saveNodeTitle(node.id),
        ),
      ),
    );
  }

  Future<void> _saveNodeTitle(String nodeId) async {
    final controller = _editingControllers[nodeId];
    if (controller == null) return;

    final newTitle = controller.text.trim();
    if (newTitle.isEmpty) {
      setState(() {
        _editingNodeId = null;
      });
      return;
    }

    try {
      final nodeService = await ref.read(nodeServiceProvider.future);
      await nodeService.updateNodeTitle(nodeId, newTitle);
      ref.invalidate(taskNodesProvider(widget.task.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update node: $e')),
        );
      }
    }

    if (mounted) {
      setState(() {
        _editingNodeId = null;
      });
    }
  }
}

