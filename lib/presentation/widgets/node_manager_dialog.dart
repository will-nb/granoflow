import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/node.dart';
import '../../core/providers/node_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../generated/l10n/app_localizations.dart';
import 'gradient_page_scaffold.dart';
import 'tri_state_checkbox.dart';
import 'input_decoration_builder.dart';

/// 全屏节点管理弹窗组件
/// 
/// Things3 风格的内联编辑体验
/// - 底部输入框始终显示（即使列表为空）
/// - 点击节点标题直接在列表中编辑
/// - 支持连续添加节点
class NodeManagerDialog extends ConsumerStatefulWidget {
  const NodeManagerDialog({
    super.key,
    required this.taskId,
  });

  final String taskId;

  @override
  ConsumerState<NodeManagerDialog> createState() => _NodeManagerDialogState();
}

class _NodeManagerDialogState extends ConsumerState<NodeManagerDialog> {
  String? _editingNodeId;
  bool _isAddingNode = false;
  String? _currentParentId; // null = 根节点
  final TextEditingController _addNodeController = TextEditingController();
  final FocusNode _addNodeFocusNode = FocusNode();
  final GlobalKey _inputFieldKey = GlobalKey();
  final Map<String, TextEditingController> _editingControllers = {};
  final Map<String, FocusNode> _editingFocusNodes = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 监听底部输入框焦点变化，用于触发动画
    _addNodeFocusNode.addListener(_onBottomInputFocusChange);
    // 延迟检查，确保 provider 已经初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialState();
    });
  }

  void _onBottomInputFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _checkInitialState() {
    final nodesAsync = ref.read(taskNodesProvider(widget.taskId));
    nodesAsync.whenData((nodes) {
      if (nodes.isEmpty && mounted) {
        setState(() {
          _isAddingNode = true;
        });
        // 自动聚焦输入框
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _addNodeFocusNode.requestFocus();
        });
      }
    });
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
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToInputField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _inputFieldKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.0,
        );
      }
    });
  }

  void _handleSaveAndClose() {
    // NodeManagerDialog 的内容是自动保存的，直接关闭即可
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final nodesAsync = ref.watch(taskNodesProvider(widget.taskId));
    
    // 根据节点列表状态动态计算标题
    final title = nodesAsync.maybeWhen(
      data: (nodes) => nodes.isEmpty
          ? l10n.nodeAddButton
          : l10n.nodeEditButton,
      orElse: () => l10n.nodeEditButton,
    );

    return PopScope(
      canPop: true,
      child: GradientPageScaffold(
        fullScreen: true,
        body: Column(
          children: [
            // 顶部栏
            _buildTopBar(context, theme, colorScheme, l10n, title),
            // 主体：节点列表 + 底部输入框
            Expanded(
              child: nodesAsync.when(
                data: (nodes) => _buildContent(context, nodes, theme, colorScheme, l10n),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
    String title,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // 保存并关闭按钮
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _handleSaveAndClose,
              tooltip: l10n.commonSave,
            ),
            // 标题
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // 占位，保持标题居中
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Node> nodes,
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final visibleNodes = nodes.where((n) => n.status != NodeStatus.deleted || true).toList();

    return Container(
      color: colorScheme.surface,
      child: Column(
        children: [
          // 可滚动的节点列表
          Expanded(
            child: visibleNodes.isEmpty
                ? const SizedBox.shrink()
                : ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _buildNodesTree(context, visibleNodes, theme, colorScheme, l10n),
                      // 底部输入框占位，确保输入框在滚动时可见
                      SizedBox(height: _isAddingNode ? 0 : 80),
                    ],
                  ),
          ),
          // 底部统一输入框（始终显示）
          _buildBottomInputField(context, theme, colorScheme, l10n),
        ],
      ),
    );
  }

  Widget _buildNodesTree(
    BuildContext context,
    List<Node> nodes,
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final rootNodes = nodes.where((n) => n.parentId == null).toList();
    rootNodes.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

    if (rootNodes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: rootNodes.map((node) => _buildNodeItem(context, node, nodes, 0, theme, colorScheme, l10n)).toList(),
    );
  }

  Widget _buildNodeItem(
    BuildContext context,
    Node node,
    List<Node> allNodes,
    int depth,
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final children = allNodes.where((n) => n.parentId == node.id).toList();
    children.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 节点瓦片（内联编辑或普通显示）
        _editingNodeId == node.id
            ? _buildEditingNodeTile(context, node, depth, theme, colorScheme, l10n)
            : _buildNormalNodeTile(context, node, depth, theme, colorScheme, l10n),
        // 子节点
        if (children.isNotEmpty)
          ...children.map((child) => _buildNodeItem(context, child, allNodes, depth + 1, theme, colorScheme, l10n)),
      ],
    );
  }

  Widget _buildNormalNodeTile(
    BuildContext context,
    Node node,
    int depth,
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final isDeleted = node.status == NodeStatus.deleted;
    final isFinished = node.status == NodeStatus.finished;

    // 根据主题模式确定 Card 背景色
    final cardColor = theme.brightness == Brightness.light
        ? colorScheme.surface
        : colorScheme.surfaceContainerHigh;

    return Dismissible(
      key: Key('node_${node.id}'),
      direction: DismissDirection.horizontal,
      background: Container(
        color: colorScheme.primary,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: Icon(
          Icons.check,
          color: colorScheme.onPrimary,
        ),
      ),
      secondaryBackground: Container(
        color: colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(
          Icons.delete,
          color: colorScheme.onError,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // 右滑：完成
          await _updateNodeStatus(node.id, NodeStatus.finished);
          return false;
        } else if (direction == DismissDirection.endToStart) {
          // 左滑：删除
          await _updateNodeStatus(node.id, NodeStatus.deleted);
          return false;
        }
        return false;
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: cardColor,
        margin: EdgeInsets.only(
          left: depth * 24.0 + 16.0,
          right: 16.0,
          top: 8.0,
          bottom: 8.0,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _editingNodeId = node.id;
                _isAddingNode = false;
                _currentParentId = null;
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
              }
              // 自动聚焦
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _editingFocusNodes[node.id]?.requestFocus();
              });
            },
            splashColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            highlightColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                  children: [
                    // 三态复选框
                    TriStateCheckbox(
                      value: _nodeStatusToTriState(node.status),
                      onChanged: (newState) {
                        _updateNodeStatus(node.id, _triStateToNodeStatus(newState));
                      },
                    ),
                    const SizedBox(width: 12),
                    // 节点标题
                    Expanded(
                      child: Text(
                        node.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          decoration: isDeleted || isFinished
                              ? TextDecoration.lineThrough
                              : null,
                          color: isDeleted
                              ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                              : null,
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
                          _scrollToInputField();
                        });
                      },
                      tooltip: l10n.nodeAddButton,
                    ),
                  ],
                ),
              ),
          ),
        ),
      ),
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
    }

    final focusNode = _editingFocusNodes[node.id]!;

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
        taskId: widget.taskId,
        title: title,
        parentId: null,
      );
      
      // Things3 风格：创建后清空输入框但保持焦点，支持连续添加
      if (mounted) {
        setState(() {
          _addNodeController.clear();
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _addNodeFocusNode.requestFocus();
          _scrollToInputField();
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
        taskId: widget.taskId,
        title: title,
        parentId: parentId,
      );
      
      // Things3 风格：创建后清空输入框但保持焦点，支持连续添加
      if (mounted) {
        setState(() {
          _addNodeController.clear();
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _addNodeFocusNode.requestFocus();
          _scrollToInputField();
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
      ref.invalidate(taskNodesProvider(widget.taskId));
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

  Future<void> _updateNodeStatus(String nodeId, NodeStatus status) async {
    try {
      final nodeService = await ref.read(nodeServiceProvider.future);
      if (status == NodeStatus.deleted) {
        // 删除节点时，所有子节点也会一起删除
        await nodeService.deleteNode(nodeId);
      } else if (status == NodeStatus.finished) {
        // 完成节点时，所有子节点也会一起完成
        await nodeService.updateNodeStatusWithChildren(nodeId, status);
      } else {
        // 其他状态（如 pending）使用普通更新
        await nodeService.updateNodeStatus(nodeId, status);
      }
      ref.invalidate(taskNodesProvider(widget.taskId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update node: $e')),
        );
      }
    }
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
}

