import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/node.dart';
import '../../data/models/task.dart';
import '../../core/providers/node_providers.dart';
import '../../core/providers/service_providers.dart';
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
  String? _addingChildNodeId;
  bool _addingRootNode = false;
  final Map<String, TextEditingController> _editingControllers = {};
  final Map<String, FocusNode> _editingFocusNodes = {};
  final TextEditingController _addNodeController = TextEditingController();
  final FocusNode _addNodeFocusNode = FocusNode();

  @override
  void dispose() {
    for (final controller in _editingControllers.values) {
      controller.dispose();
    }
    for (final focusNode in _editingFocusNodes.values) {
      focusNode.dispose();
    }
    _addNodeController.dispose();
    _addNodeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nodesAsync = ref.watch(taskNodesProvider(widget.task.id));

    return nodesAsync.when(
      data: (nodes) {
        // 过滤掉已删除的节点（根据设计，已删除的节点应该显示，但这里先显示所有节点）
        final visibleNodes = nodes.where((n) => n.status != NodeStatus.deleted || true).toList();
        
        // 如果节点列表为空，不显示
        if (visibleNodes.isEmpty && !_addingRootNode) {
          return _buildEmptyState(context);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 折叠/展开按钮（如果有子节点）
            if (_hasChildren(visibleNodes))
              _buildCollapseButton(context),
            // 分隔线
            if (visibleNodes.isNotEmpty || _addingRootNode)
              const Divider(height: 24),
            // 节点树
            if (!_isCollapsed) ...[
              _buildNodesTree(context, visibleNodes),
              // 添加根节点按钮
              if (!_addingRootNode)
                _buildAddRootNodeButton(context),
              // 添加根节点输入框
              if (_addingRootNode)
                _buildAddRootNodeInput(context),
            ],
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return _buildAddRootNodeButton(context);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 节点瓦片
        _editingNodeId == node.id
            ? _buildEditingNodeTile(context, node, depth)
            : DismissibleNodeTile(
                node: node,
                depth: depth,
                onTap: () => _startEditingNode(node),
                onAddChild: () => _startAddingChildNode(node.id),
                onReorder: (oldIndex, newIndex) {
                  // 拖拽排序逻辑（在 ReorderableListView 中处理）
                },
                onStatusChange: (status) => _updateNodeStatus(node.id, status),
              ),
        // 添加子节点输入框
        if (_addingChildNodeId == node.id)
          _buildAddChildNodeInput(context, node, depth + 1),
        // 子节点
        if (children.isNotEmpty)
          ...children.map((child) => _buildNodeItem(context, child, allNodes, depth + 1)),
      ],
    );
  }

  Widget _buildEditingNodeTile(BuildContext context, Node node, int depth) {
    if (!_editingControllers.containsKey(node.id)) {
      _editingControllers[node.id] = TextEditingController(text: node.title);
      _editingFocusNodes[node.id] = FocusNode();
      _editingFocusNodes[node.id]!.addListener(() {
        if (!_editingFocusNodes[node.id]!.hasFocus) {
          _saveNodeTitle(node.id);
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _editingFocusNodes[node.id]?.requestFocus();
      });
    }

    return Padding(
      padding: EdgeInsets.only(
        left: depth * 24.0 + 16.0,
        right: 16.0,
        top: 8.0,
        bottom: 8.0,
      ),
      child: TextField(
        controller: _editingControllers[node.id],
        focusNode: _editingFocusNodes[node.id],
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        onSubmitted: (_) => _saveNodeTitle(node.id),
      ),
    );
  }

  Widget _buildAddChildNodeInput(BuildContext context, Node parentNode, int depth) {
    return Padding(
      padding: EdgeInsets.only(
        left: depth * 24.0 + 16.0,
        right: 16.0,
        top: 8.0,
        bottom: 8.0,
      ),
      child: TextField(
        controller: _addNodeController,
        focusNode: _addNodeFocusNode,
        decoration: InputDecoration(
          hintText: 'Node title', // TODO: 使用 l10n.nodeTitleHint（阶段 7 添加）
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        onSubmitted: (value) => _createChildNode(parentNode.id, value),
      ),
    );
  }

  Widget _buildAddRootNodeButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: OutlinedButton.icon(
        onPressed: () {
          setState(() {
            _addingRootNode = true;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _addNodeFocusNode.requestFocus();
          });
        },
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Add Node'), // TODO: 使用 l10n.nodeAddButton（阶段 7 添加）
      ),
    );
  }

  Widget _buildAddRootNodeInput(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _addNodeController,
        focusNode: _addNodeFocusNode,
        decoration: InputDecoration(
          hintText: 'Node title', // TODO: 使用 l10n.nodeTitleHint（阶段 7 添加）
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        onSubmitted: (value) => _createRootNode(value),
      ),
    );
  }

  void _startEditingNode(Node node) {
    setState(() {
      _editingNodeId = node.id;
    });
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
    } catch (e) {
      // 错误处理
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update node: $e')),
        );
      }
    }

    setState(() {
      _editingNodeId = null;
    });
  }

  void _startAddingChildNode(String parentId) {
    setState(() {
      _addingChildNodeId = parentId;
      _addNodeController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addNodeFocusNode.requestFocus();
    });
  }

  Future<void> _createChildNode(String parentId, String title) async {
    if (title.trim().isEmpty) {
      setState(() {
        _addingChildNodeId = null;
      });
      return;
    }

    try {
      final nodeService = await ref.read(nodeServiceProvider.future);
      await nodeService.createNode(
        taskId: widget.task.id,
        title: title.trim(),
        parentId: parentId,
      );
    } catch (e) {
      // 错误处理
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create node: $e')),
        );
      }
    }

    setState(() {
      _addingChildNodeId = null;
      _addNodeController.clear();
    });
  }

  Future<void> _createRootNode(String title) async {
    if (title.trim().isEmpty) {
      setState(() {
        _addingRootNode = false;
      });
      return;
    }

    try {
      final nodeService = await ref.read(nodeServiceProvider.future);
      await nodeService.createNode(
        taskId: widget.task.id,
        title: title.trim(),
        parentId: null,
      );
    } catch (e) {
      // 错误处理
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create node: $e')),
        );
      }
    }

    setState(() {
      _addingRootNode = false;
      _addNodeController.clear();
    });
  }

  Future<void> _updateNodeStatus(String nodeId, NodeStatus status) async {
    try {
      final nodeService = await ref.read(nodeServiceProvider.future);
      if (status == NodeStatus.deleted) {
        await nodeService.deleteNode(nodeId);
      } else {
        await nodeService.updateNodeStatus(nodeId, status);
      }
    } catch (e) {
      // 错误处理
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update node: $e')),
        );
      }
    }
  }
}

