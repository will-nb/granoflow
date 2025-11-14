import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/node.dart';
import '../../data/models/task.dart';
import '../../core/providers/node_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../generated/l10n/app_localizations.dart';
import 'tri_state_checkbox.dart';
import 'input_decoration_builder.dart';

/// 任务节点列表组件（支持交互）
/// 
/// 用于在任务展开内容中显示节点，支持状态切换和编辑
class TaskNodesListReadonly extends ConsumerStatefulWidget {
  const TaskNodesListReadonly({
    super.key,
    required this.task,
  });

  final Task task;

  @override
  ConsumerState<TaskNodesListReadonly> createState() => _TaskNodesListReadonlyState();
}

class _TaskNodesListReadonlyState extends ConsumerState<TaskNodesListReadonly> {
  String? _editingNodeId;
  final Map<String, TextEditingController> _editingControllers = {};
  final Map<String, FocusNode> _editingFocusNodes = {};
  bool _isAddingNode = false;
  String? _currentParentId; // null = 根节点
  final TextEditingController _addNodeController = TextEditingController();
  final FocusNode _addNodeFocusNode = FocusNode();
  final GlobalKey _inputFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _addNodeFocusNode.addListener(_onBottomInputFocusChange);
  }

  void _onBottomInputFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _addNodeFocusNode.removeListener(_onBottomInputFocusChange);
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return nodesAsync.when(
      data: (nodes) {
        // 显示所有节点（包括已删除和已完成的）
        final visibleNodes = nodes.where((n) => n.status != NodeStatus.deleted || true).toList();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 节点列表
            if (visibleNodes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _buildNodesTree(context, visibleNodes),
              ),
            // 底部输入框占位（当不在添加状态时）
            if (!_isAddingNode && visibleNodes.isNotEmpty)
              const SizedBox(height: 8),
            // 底部统一输入框（始终显示）
            _buildBottomInputField(context, theme, colorScheme, l10n),
          ],
        );
      },
      loading: () => _buildBottomInputField(context, theme, colorScheme, l10n),
      error: (_, __) => _buildBottomInputField(context, theme, colorScheme, l10n),
    );
  }

  Widget _buildNodesTree(BuildContext context, List<Node> nodes) {
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
    final isDeleted = node.status == NodeStatus.deleted;
    final isFinished = node.status == NodeStatus.finished;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 节点瓦片（内联编辑或普通显示）
        _editingNodeId == node.id
            ? _buildEditingNodeTile(context, node, depth, theme, colorScheme, l10n)
            : Material(
                color: Colors.transparent,
                child: InkWell(
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
                        // 触发重建以更新焦点状态
                        if (mounted && _editingNodeId == node.id) {
                          setState(() {});
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
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: depth * 24.0 + 16.0,
                      right: 16.0,
                      top: 6.0,
                      bottom: 6.0,
                    ),
                    child: Row(
                      children: [
                        // 三态复选框（可交互）
                        TriStateCheckbox(
                          value: _nodeStatusToTriState(node.status),
                          onChanged: (newState) {
                            final newStatus = _triStateToNodeStatus(newState);
                            _updateNodeStatus(node.id, newStatus);
                          },
                        ),
                        const SizedBox(width: 12),
                        // 节点标题（可点击编辑）
                        Expanded(
                          child: Text(
                            node.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              decoration: isDeleted || isFinished
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isDeleted
                                  ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                              height: 1.4,
                            ),
                          ),
                        ),
                        // 添加子节点按钮
                        IconButton(
                          icon: const Icon(Icons.add, size: 20),
                          onPressed: () {
                            setState(() {
                              _isAddingNode = true;
                              _currentParentId = node.id;
                              _editingNodeId = null;
                              _addNodeController.clear();
                            });
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _addNodeFocusNode.requestFocus();
                            });
                          },
                          tooltip: l10n.nodeAddButton,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        // 子节点
        if (children.isNotEmpty)
          ...children.map((child) => _buildNodeItem(context, child, allNodes, depth + 1)),
      ],
    );
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
        // 触发重建以更新焦点状态
        if (mounted && _editingNodeId == node.id) {
          setState(() {});
        }
      });
    } else {
      // 确保控制器文本与节点标题同步
      if (_editingControllers[node.id]!.text != node.title) {
        _editingControllers[node.id]!.text = node.title;
      }
    }

    final focusNode = _editingFocusNodes[node.id]!;

    return Padding(
      padding: EdgeInsets.only(
        left: depth * 24.0 + 16.0,
        right: 16.0,
        top: 6.0,
        bottom: 6.0,
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: TextField(
            controller: _editingControllers[node.id],
            focusNode: focusNode,
            decoration: InputDecorationBuilder.buildUnderlineInputDecoration(
              context,
              hintText: l10n.nodeTitleHint,
              isFocused: focusNode.hasFocus,
            ),
            style: theme.textTheme.bodyMedium,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveNodeTitle(node.id),
          ),
        ),
      ),
    );
  }

  TriState _nodeStatusToTriState(NodeStatus status) {
    return switch (status) {
      NodeStatus.pending => TriState.pending,
      NodeStatus.finished => TriState.finished,
      NodeStatus.deleted => TriState.deleted,
    };
  }

  NodeStatus _triStateToNodeStatus(TriState state) {
    return switch (state) {
      TriState.pending => NodeStatus.pending,
      TriState.finished => NodeStatus.finished,
      TriState.deleted => NodeStatus.deleted,
    };
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

  Widget _buildBottomInputField(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Focus(
        key: _inputFieldKey,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
            _cancelAddingNode();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: TextField(
            controller: _addNodeController,
            focusNode: _addNodeFocusNode,
            decoration: InputDecorationBuilder.buildUnderlineInputDecoration(
              context,
              hintText: l10n.nodeTitleHint,
              isFocused: _addNodeFocusNode.hasFocus,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => _handleSubmitNode(value),
            onTap: () {
              // 点击底部输入框时，重置为添加根节点模式
              if (_currentParentId != null) {
                setState(() {
                  _currentParentId = null;
                  _isAddingNode = true;
                });
              }
            },
            onTapOutside: (_) {
              if (_addNodeController.text.trim().isEmpty) {
                _cancelAddingNode();
              }
            },
          ),
        ),
      ),
    );
  }

  void _cancelAddingNode() {
    setState(() {
      _isAddingNode = false;
      _currentParentId = null;
      _addNodeController.clear();
    });
    _addNodeFocusNode.unfocus();
  }

  Future<void> _handleSubmitNode(String value) async {
    final title = value.trim();
    if (title.isEmpty) {
      _cancelAddingNode();
      return;
    }

    if (_currentParentId == null) {
      await _createRootNode(title);
    } else {
      await _createChildNode(_currentParentId!, title);
    }
  }

  Future<void> _createRootNode(String title) async {
    try {
      final nodeService = await ref.read(nodeServiceProvider.future);
      await nodeService.createNode(
        taskId: widget.task.id,
        title: title,
        parentId: null,
      );
      
      // 刷新节点列表
      ref.invalidate(taskNodesProvider(widget.task.id));
      
      // Things3 风格：创建后清空输入框但保持焦点，支持连续添加
      if (mounted) {
        setState(() {
          _addNodeController.clear();
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _addNodeFocusNode.requestFocus();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create node: $e')),
        );
        _cancelAddingNode();
      }
    }
  }

  Future<void> _createChildNode(String parentId, String title) async {
    try {
      final nodeService = await ref.read(nodeServiceProvider.future);
      await nodeService.createNode(
        taskId: widget.task.id,
        title: title,
        parentId: parentId,
      );
      
      // 刷新节点列表
      ref.invalidate(taskNodesProvider(widget.task.id));
      
      // Things3 风格：创建后清空输入框但保持焦点，支持连续添加
      if (mounted) {
        setState(() {
          _addNodeController.clear();
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _addNodeFocusNode.requestFocus();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create node: $e')),
        );
        _cancelAddingNode();
      }
    }
  }

  Future<void> _updateNodeStatus(String nodeId, NodeStatus status) async {
    try {
      final nodeService = await ref.read(nodeServiceProvider.future);
      
      // 获取当前节点状态
      final nodes = await ref.read(taskNodesProvider(widget.task.id).future);
      final currentNode = nodes.firstWhere((n) => n.id == nodeId);
      final currentStatus = currentNode.status;
      
      // 根据新状态和当前状态决定调用哪个方法
      if (status == NodeStatus.deleted) {
        // 删除节点时，所有子节点也会一起删除
        await nodeService.deleteNode(nodeId);
      } else if (status == NodeStatus.finished) {
        // 完成节点时，所有子节点也会一起完成
        await nodeService.updateNodeStatusWithChildren(nodeId, status);
      } else if (status == NodeStatus.pending && currentStatus == NodeStatus.deleted) {
        // 如果当前是 deleted 状态，且新状态是 pending，则还原节点
        await nodeService.restoreNode(nodeId);
      } else {
        // 其他情况（如 pending -> pending，或 finished -> pending）使用普通更新
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
}

