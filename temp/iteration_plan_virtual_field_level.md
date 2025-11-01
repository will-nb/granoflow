# 迭代蓝图：使用 Provider 实现任务 Level 虚拟字段

## 目标

将任务层级（level）作为虚拟字段，通过 Riverpod Provider 实现，让 level 在 UI 中像普通字段一样使用（`levelMap[task.id]`），同时消除对 `taskMap` 的依赖。

## 核心设计

### 虚拟字段实现方式

使用 `FutureProvider` 创建 `inboxTaskLevelMapProvider`：
- 监听 `inboxTasksProvider` 的变化
- 自动计算所有任务的 level
- 返回 `Map<int, int>` (taskId -> level)
- 在 UI 中使用：`levelMap[task.id]` 就像访问 `task.title` 一样自然

## 修改清单

### 1. 创建虚拟字段 Provider

**文件**: `lib/core/providers/app_providers.dart`

**修改内容**:
```dart
/// Provider for getting task level map (虚拟字段)
/// 
/// 返回 taskId -> level 的映射，level 是计算属性（虚拟字段）
/// 自动响应 inboxTasksProvider 的变化
/// 
/// 使用方式：
/// ```dart
/// final levelMapAsync = ref.watch(inboxTaskLevelMapProvider);
/// return levelMapAsync.when(
///   data: (levelMap) {
///     final taskLevel = levelMap[task.id] ?? 1;
///     // ...
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (_, __) => SizedBox.shrink(),
/// );
/// ```
final inboxTaskLevelMapProvider = FutureProvider<Map<int, int>>((ref) async {
  final tasksAsync = ref.watch(inboxTasksProvider);
  final tasks = await tasksAsync.future;
  final taskRepository = ref.watch(taskRepositoryProvider);
  final levelMap = <int, int>{};
  
  // 批量计算所有任务的 level
  for (final task in tasks) {
    final depth = await calculateHierarchyDepth(task, taskRepository);
    levelMap[task.id] = depth + 1;
  }
  
  return levelMap;
});
```

**依赖**: 需要导入 `calculateHierarchyDepth` from `../../presentation/tasks/utils/hierarchy_utils.dart`

---

### 2. 删除已废弃的同步方法

**文件**: `lib/presentation/tasks/utils/hierarchy_utils.dart`

**修改内容**:
- 删除 `calculateTaskDepthSync` 方法（第 54-92 行）
- 保留 `calculateHierarchyDepth` 异步方法
- 保留 `getTaskLevel` 异步方法（已修改为接受 repository）

---

### 3. 修改 inbox_task_list.dart - 使用虚拟字段

**文件**: `lib/presentation/inbox/views/inbox_task_list.dart`

#### 3.1 在 build 方法中获取 levelMap

**位置**: `build` 方法开始处（约第 419 行）

**修改内容**:
```dart
@override
Widget build(BuildContext context) {
  if (_tasks.isEmpty) {
    return const SizedBox.shrink();
  }

  // 获取虚拟字段 level map
  final levelMapAsync = ref.watch(inboxTaskLevelMapProvider);

  // 使用 AsyncValue.when 处理异步加载
  return levelMapAsync.when(
    data: (levelMap) {
      // 所有后续代码都在这个闭包中
      // 现在可以使用 levelMap[task.id] 访问 level
      
      final filteredTasks = _tasks
          .where((task) => task.status != TaskStatus.trashed)
          .toList();
      
      // ... 其余代码保持不变，但使用 levelMap 替代 getTaskLevel
    },
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, stackTrace) {
      debugPrint('Error loading level map: $error');
      return const SizedBox.shrink();
    },
  );
}
```

#### 3.2 修改 transform getter 使用 levelMap

**位置**: 第 591-610 行

**修改内容**:
```dart
transform: () {
  if (!dragState.isDragging ||
      dragState.hoveredInsertionIndex == null) {
    return null;
  }

  // 使用虚拟字段 levelMap 替代 getTaskLevel
  final draggedTask = dragState.draggedTask;
  if (draggedTask == null) {
    return null;
  }
  
  final draggedTaskLevel = levelMap[draggedTask.id] ?? 1;
  final draggedTaskParentId = draggedTask.parentId;

  final currentTaskLevel = levelMap[task.id] ?? 1;
  final currentTaskParentId = task.parentId;
  
  // ... 其余代码保持不变
}(),
```

**删除**: 移除 `taskMap` 的构建代码（第 597-598 行）

#### 3.3 修改 onDragStarted 使用 levelMap

**位置**: 第 780-785 行

**修改内容**:
```dart
onDragStarted: () {
  // 使用虚拟字段 levelMap 替代 getTaskLevel
  final taskLevel = levelMap[task.id] ?? 1;

  // 获取展开状态管理器
  final expandedNotifier = ref.read(
    inboxExpandedTaskIdProvider.notifier,
  );
  // ... 其余代码保持不变
},
```

**删除**: 移除 `taskMap` 的构建代码（第 781-784 行）

#### 3.4 修改 _getAllChildTaskIds 使用 repository

**位置**: 第 164-180 行

**修改内容**:
```dart
/// 递归获取任务的所有子任务 ID
///
/// [task] 要查找子任务的任务
/// [taskRepository] 任务仓库，用于查询子任务
/// 返回该任务的所有子任务 ID 集合（递归包含子任务的子任务）
Future<Set<int>> _getAllChildTaskIds(
  Task task,
  TaskRepository taskRepository,
) async {
  final result = <int>{};

  // 使用 repository 查找直接子任务
  final directChildren = await taskRepository.listChildren(task.id);
  final normalChildren = directChildren
      .where((t) => !isProjectOrMilestone(t))
      .toList();

  // 递归处理每个子任务
  for (final child in normalChildren) {
    result.add(child.id);
    // 递归获取子任务的子任务
    result.addAll(await _getAllChildTaskIds(child, taskRepository));
  }

  return result;
}
```

**修改调用处**:
- 第 797 行：`await _getAllChildTaskIds(task, taskRepository)`，需要 `async/await`
- 第 816 行：同样需要修改

**注意**: 由于变为异步，`onDragStarted` 需要改为 `async`，但 `onDragStarted` 的类型是 `VoidCallback`（同步）。需要：
- 方案 A: 使用 `Future<void>` 回调（如果 `InboxTaskTile` 支持）
- 方案 B: 在 build 时预先计算所有任务的子任务列表并缓存

**推荐方案 B**: 创建另一个 provider `inboxTaskChildrenMapProvider`，返回 `Map<int, Set<int>>`（taskId -> 子任务ID集合）

#### 3.5 修改 _isMovedOutOfExpandedArea 使用 repository

**位置**: 第 348-415 行

**修改内容**:
```dart
/// 检查子任务是否移动出父任务的扩展区
///
/// [task] 被拖拽的子任务
/// [hoveredTaskId] 当前悬停的任务 ID（如果是任务表面）
/// [hoveredInsertionIndex] 当前悬停的插入位置索引（如果是插入间隔）
/// [flattenedTasks] 扁平化任务列表
/// [taskRepository] 任务仓库，用于查找父任务
/// 返回 Future<bool>，true 如果移动出扩展区
Future<bool> _isMovedOutOfExpandedArea(
  Task task,
  int? hoveredTaskId,
  int? hoveredInsertionIndex,
  List<FlattenedTaskNode> flattenedTasks,
  TaskRepository taskRepository,
) async {
  if (task.parentId == null) {
    return false; // 根任务不存在扩展区
  }

  // 使用 repository 查找父任务
  final parentTask = await taskRepository.findById(task.parentId!);
  if (parentTask == null) {
    return false;
  }
  
  // ... 其余代码保持不变
}
```

**修改调用处**:
- 第 705 行：`await _isMovedOutOfExpandedArea(...)`
- 第 935 行：`await _isMovedOutOfExpandedArea(...)`

**注意**: 这些调用在同步回调中，需要处理异步问题。

**解决方案**: 由于 `onHover` 回调可能不支持异步，可以：
- 方案 A: 在 build 时预先查找所有需要的父任务并缓存
- 方案 B: 由于 `filteredTasks` 已经包含所有任务，可以直接查找：`filteredTasks.firstWhere((t) => t.id == task.parentId)`

**推荐方案 B**: 使用 `filteredTasks` 而不是 repository，因为数据已经在内存中

#### 3.6 修改 _convertFlattenedIndexToRootInsertionIndex 使用 repository

**位置**: 第 190-231 行

**修改内容**:
```dart
/// 将扁平化列表索引转换为根任务插入索引
///
/// [flattenedIndex] 扁平化列表索引
/// [flattenedTasks] 扁平化任务列表
/// [taskIdToIndex] 任务 ID 到根任务索引的映射
/// [rootTasks] 根任务列表
/// [filteredTasks] 所有任务列表（用于查找父任务）
/// 返回根任务插入索引
int _convertFlattenedIndexToRootInsertionIndex(
  int flattenedIndex,
  List<FlattenedTaskNode> flattenedTasks,
  Map<int, int> taskIdToIndex,
  List<Task> rootTasks,
  List<Task> filteredTasks, // 保留这个参数，用于查找父任务
) {
  // ... 前面的代码保持不变
  
  // 如果是子任务，找到它的根父任务
  // 使用 filteredTasks 查找父任务（数据已在内存中）
  Task? currentTask = task;
  while (currentTask != null && currentTask.parentId != null) {
    final parent = filteredTasks.firstWhere(
      (t) => t.id == currentTask.parentId,
      orElse: () => throw StateError('Parent task not found'),
    );
    final parentRootIndex = taskIdToIndex[parent.id];
    if (parentRootIndex != null) {
      // 找到根父任务，返回它的索引 + 1（插入到它之后）
      return parentRootIndex + 1;
    }
    currentTask = parent;
  }
  
  // ... 其余代码
}
```

**删除**: 移除 `taskMap` 的构建代码（第 217 行）

---

### 4. 修改 inbox_drag_target.dart

**文件**: `lib/presentation/inbox/inbox_drag_target.dart`

**位置**: 第 144-148 行

**修改内容**:
```dart
// 不是兄弟（不同级别）：根据向右拖动情况决定
// 使用异步方法计算层级深度
final taskRepository = ref.read(taskRepositoryProvider);

final beforeDepth = await calculateHierarchyDepth(beforeTask!, taskRepository);
final afterDepth = await calculateHierarchyDepth(afterTask!, taskRepository);
```

**删除**: 
- 移除 `allTasks` 的获取（第 144 行）
- 移除 `taskMap` 的构建（第 145 行）
- 移除 `calculateTaskDepthSync` 的调用（第 147-148 行）

**注意**: 这个方法已经在 `async` 上下文中（`onPerform`），所以可以直接使用 `await`

---

### 5. 移除所有构建 taskMap 的代码

**需要删除的代码位置**:

1. `inbox_task_list.dart` 第 598 行: `final taskMap = {for (final t in filteredTasks) t.id: t};`
2. `inbox_task_list.dart` 第 702-704 行: taskMap 构建
3. `inbox_task_list.dart` 第 782-784 行: taskMap 构建
4. `inbox_task_list.dart` 第 932-934 行: taskMap 构建
5. `inbox_drag_target.dart` 第 144-145 行: allTasks 和 taskMap 构建

**注意**: 第 217 行的 taskMap 构建需要保留，但改为使用 `filteredTasks` 直接查找

---

### 6. 处理异步回调问题

#### 问题 1: `onDragStarted` 是同步回调，但 `_getAllChildTaskIds` 变为异步

**解决方案**: 创建 `inboxTaskChildrenMapProvider`

**文件**: `lib/core/providers/app_providers.dart`

```dart
/// Provider for getting task children map (虚拟字段)
/// 
/// 返回 taskId -> Set<子任务ID> 的映射
/// 自动响应 inboxTasksProvider 的变化
final inboxTaskChildrenMapProvider = FutureProvider<Map<int, Set<int>>>((ref) async {
  final tasksAsync = ref.watch(inboxTasksProvider);
  final tasks = await tasksAsync.future;
  final taskRepository = ref.watch(taskRepositoryProvider);
  final childrenMap = <int, Set<int>>{};
  
  // 为每个任务查找所有子任务
  for (final task in tasks) {
    final children = await taskRepository.listChildren(task.id);
    final normalChildren = children
        .where((t) => !isProjectOrMilestone(t))
        .map((t) => t.id)
        .toSet();
    
    // 递归添加子任务的子任务
    final allChildren = <int>{...normalChildren};
    for (final childId in normalChildren) {
      final childChildren = await _getAllDescendants(childId, taskRepository);
      allChildren.addAll(childChildren);
    }
    
    childrenMap[task.id] = allChildren;
  }
  
  return childrenMap;
});

/// 辅助函数：递归获取所有后代任务 ID
Future<Set<int>> _getAllDescendants(
  int taskId,
  TaskRepository taskRepository,
) async {
  final result = <int>{};
  final children = await taskRepository.listChildren(taskId);
  final normalChildren = children.where((t) => !isProjectOrMilestone(t));
  
  for (final child in normalChildren) {
    result.add(child.id);
    result.addAll(await _getAllDescendants(child.id, taskRepository));
  }
  
  return result;
}
```

**在 `inbox_task_list.dart` 中使用**:
```dart
final childrenMapAsync = ref.watch(inboxTaskChildrenMapProvider);

return childrenMapAsync.when(
  data: (childrenMap) {
    // 在 onDragStarted 中使用：
    // final childTaskIds = childrenMap[task.id] ?? <int>{};
    // ...
  },
  // ...
);
```

#### 问题 2: `_isMovedOutOfExpandedArea` 需要查找父任务

**解决方案**: 使用 `filteredTasks` 直接查找（数据已在内存中）

---

## 修改顺序

1. ✅ 创建 `inboxTaskLevelMapProvider`（虚拟字段）
2. ✅ 删除 `calculateTaskDepthSync` 方法
3. ✅ 修改 `inbox_drag_target.dart`（简单，已在异步上下文中）
4. ✅ 修改 `inbox_task_list.dart` 的 build 方法，使用 levelMap
5. ✅ 修改 transform getter 使用 levelMap
6. ✅ 修改 onDragStarted 使用 levelMap
7. ✅ 创建 `inboxTaskChildrenMapProvider`（处理子任务查找）
8. ✅ 修改 `_getAllChildTaskIds` 的调用处使用 childrenMap
9. ✅ 修改 `_isMovedOutOfExpandedArea` 使用 filteredTasks 查找父任务
10. ✅ 修改 `_convertFlattenedIndexToRootInsertionIndex` 使用 filteredTasks
11. ✅ 移除所有 taskMap 构建代码
12. ✅ 测试验证

## 注意事项

1. **性能考虑**: `inboxTaskLevelMapProvider` 会为所有任务计算 level，可能需要优化（批量查询）
2. **异步加载**: UI 需要使用 `AsyncValue.when` 处理加载和错误状态
3. **数据一致性**: levelMap 会自动响应 `inboxTasksProvider` 的变化，保持数据同步
4. **向后兼容**: 确保所有使用 level 的地方都使用虚拟字段，不再依赖 taskMap

## 测试要点

1. ✅ 任务列表正常显示
2. ✅ 拖拽排序功能正常
3. ✅ 子任务拖拽功能正常
4. ✅ 向左拖拽升级功能正常（2级→1级，3级→2级）
5. ✅ 展开/收缩功能正常
6. ✅ 让位动画正常
7. ✅ 性能测试（大量任务时的计算性能）

