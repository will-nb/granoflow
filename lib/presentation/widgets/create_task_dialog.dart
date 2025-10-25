import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateTaskDialog extends ConsumerStatefulWidget {
  const CreateTaskDialog({super.key});

  @override
  ConsumerState<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends ConsumerState<CreateTaskDialog> {
  final _titleController = TextEditingController();
  String _selectedTag = '工作'; // 默认标签
  String _selectedParent = '根任务'; // 默认父任务

  final List<String> _availableTags = ['工作', '学习', '生活', '娱乐'];
  final List<String> _availableParents = ['根任务', '项目A', '项目B'];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
              // 标题
              Text(
                '创建新任务',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // 任务标题输入
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: '任务标题',
                  hintText: '请输入任务标题',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.title),
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 16),

              // 标签选择
              const Text(
                '标签',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _availableTags.map((tag) {
                  final isSelected = tag == _selectedTag;
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedTag = tag);
                      }
                    },
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    checkmarkColor: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : null,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 父任务选择
              DropdownButtonFormField<String>(
                initialValue: _selectedParent,
                decoration: InputDecoration(
                  labelText: '上级任务',
                  hintText: '选择上级任务',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.account_tree),
                ),
                items: _availableParents.map((parent) {
                  return DropdownMenuItem(
                    value: parent,
                    child: Text(parent),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedParent = value);
                  }
                },
              ),
              const SizedBox(height: 24),

              // 按钮行
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _createTask,
                      icon: const Icon(Icons.send),
                      label: const Text('创建任务'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
    );
  }

  void _createTask() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入任务标题')),
      );
      return;
    }

    // TODO: 实现实际的任务创建逻辑
    // 这里暂时只是关闭弹窗
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('任务 "$title" 已创建')),
    );
  }
}