# 已完成/已归档/回收站页面统一展示设计方案

## 一、概述

本文档描述已完成、已归档、回收站三个页面的统一展示要求，包括UI样式统一、信息展示增强、筛选功能扩展等。

## 二、需求清单

### 2.1 UI样式统一
- **问题**：回收站列表当前有Card背景色，与其他两个页面不一致
- **要求**：去掉回收站的Card背景色，三个页面列表展示风格完全一致

### 2.2 标签展示（只读）
- **要求**：如果任务原本有标签，应该展示标签，但不可修改
- **场景**：已完成、已归档、回收站三个页面都需要支持

### 2.3 项目/里程碑展示（只读）
- **要求**：如果任务原本属于某个项目或里程碑，应该展示项目和里程碑信息，但不可修改
- **场景**：已完成、已归档、回收站三个页面都需要支持

### 2.4 时间显示格式
- **要求**：不显示截止日期（dueAt），分别显示：
  - 已完成页面：完成时间（endedAt）
  - 已归档页面：归档时间（archivedAt）
  - 回收站页面：删除时间（updatedAt，作为删除时间的近似值）
- **格式要求**：按地区格式显示日期和时间，精确到分钟
  - 示例：`2025-11-03 14:30` 或 `2025年11月3日 14:30`（根据locale自动适配）

### 2.5 标签筛选功能
- **要求**：提供和Inbox页面一致的标签筛选功能
- **范围**：已完成、已归档、回收站三个页面都需要支持
- **筛选类型**：
  - 场景标签（Context Tags）
  - 紧急度标签（Urgency Tags）
  - 重要度标签（Importance Tags）

### 2.6 项目筛选功能
- **要求**：新增按项目筛选功能，可以在全部页面（包括Inbox）中复用
- **功能**：
  - 支持筛选属于特定项目的任务
  - 支持筛选属于特定里程碑的任务
  - 支持"无项目"选项（筛选不属于任何项目的任务）
  - 支持组合筛选（项目 + 标签）

## 三、技术设计

### 3.1 UI样式统一

#### 3.1.1 当前状态
- **已完成页面**：使用 `Padding` 包裹，无Card背景
- **已归档页面**：使用 `Padding` 包裹，无Card背景
- **回收站页面**：使用 `Card` 包裹，有背景色（`surfaceContainerHighest.withValues(alpha: 0.4)`）

#### 3.1.2 修改方案
- **文件**：`lib/presentation/completion_management/widgets/trashed_task_tile.dart`
- **修改**：移除 `Card` 组件，改为 `Padding`，与已完成和已归档页面保持一致
- **修改位置**：第95-103行

```dart
// 修改前
child: Card(
  margin: EdgeInsets.zero,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  elevation: 0,
  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
  child: taskContent,
)

// 修改后
child: Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  child: taskContent,
)
```

### 3.2 标签展示（只读）

#### 3.2.1 现有组件
- **`ModernTag`**：现代化标签组件，支持只读模式
- **`buildModernTag`**：工具函数，用于从slug构建标签
- **位置**：`lib/presentation/widgets/modern_tag.dart`、`lib/presentation/tasks/utils/tag_utils.dart`

#### 3.2.2 实现方案
- **新建组件**：`ReadOnlyTagChip` 或直接使用 `ModernTag`（`onTap: null`）
- **集成位置**：
  - `CompletedTaskTile` 第60-65行
  - `ArchivedTaskTile` 第58-63行
  - `TrashedTaskTile` 第59-64行

```dart
// 标签展示代码示例
...task.tags.map((slug) {
  final tagWidget = buildModernTag(context, slug);
  if (tagWidget == null) return const SizedBox.shrink();
  return tagWidget; // 已经是只读的
}).toList(),
```

### 3.3 项目/里程碑展示（只读）

#### 3.3.1 现有组件
- **`InlineProjectMilestoneDisplay`**：显示项目/里程碑信息，当前支持点击编辑
- **`taskProjectHierarchyProvider`**：StreamProvider，提供任务的项目/里程碑层级信息
- **位置**：`lib/presentation/widgets/inline_project_milestone_display.dart`

#### 3.3.2 实现方案
- **方案A（推荐）**：修改 `InlineProjectMilestoneDisplay`，增加 `readOnly` 参数
- **方案B**：新建 `ReadOnlyProjectMilestoneDisplay` 组件
- **集成位置**：三个Tile组件的任务内容区域

```dart
// 只读项目/里程碑展示示例
final hierarchyAsync = ref.watch(taskProjectHierarchyProvider(task.id));
hierarchyAsync.when(
  data: (hierarchy) {
    if (hierarchy == null) return const SizedBox.shrink();
    return InlineProjectMilestoneDisplay(
      project: hierarchy.project,
      milestone: hierarchy.milestone,
      readOnly: true, // 新增参数
    );
  },
  loading: () => const SizedBox.shrink(),
  error: (_, __) => const SizedBox.shrink(),
)
```

### 3.4 时间显示格式

#### 3.4.1 当前实现
- **`CompletionTimeDisplay`**：使用相对时间（如"2天前"、"刚刚"）
- **位置**：`lib/presentation/completion_management/widgets/completion_time_display.dart`

#### 3.4.2 修改方案
- **选项1**：修改 `CompletionTimeDisplay`，增加 `format` 参数（`relative` 或 `absolute`）
- **选项2**：新建 `AbsoluteTimeDisplay` 组件
- **推荐**：选项1，通过参数控制显示格式

```dart
// 修改 CompletionTimeDisplay，增加 format 参数
class CompletionTimeDisplay extends StatelessWidget {
  const CompletionTimeDisplay({
    super.key,
    required this.dateTime,
    this.style,
    this.format = TimeDisplayFormat.relative, // 新增参数
  });

  final DateTime? dateTime;
  final TextStyle? style;
  final TimeDisplayFormat format; // 新增枚举

  // 绝对时间格式：使用 DateFormat.yMd().add_Hm() 或 yMMMd().add_Hm()
}

enum TimeDisplayFormat {
  relative, // 相对时间（当前实现）
  absolute, // 绝对时间（新需求）
}
```

**日期时间格式示例**：
- 中文：`2025年11月3日 14:30`
- 英文：`Nov 3, 2025 14:30`
- 使用 `intl` 包的 `DateFormat` 根据locale自动适配

### 3.5 标签筛选功能扩展

#### 3.5.1 当前实现
- **`InboxFilterState`**：筛选状态类
- **`InboxFilterNotifier`**：筛选状态管理
- **`InboxTagFilterStrip`**：筛选UI组件
- **位置**：
  - `lib/core/providers/app_providers.dart`（Provider）
  - `lib/presentation/inbox/widgets/inbox_tag_filter_strip.dart`（UI组件）

#### 3.5.2 扩展方案
- **重构为通用组件**：
  - 重命名 `InboxFilterState` → `TaskFilterState`
  - 重命名 `InboxFilterNotifier` → `TaskFilterNotifier`
  - 重命名 `InboxTagFilterStrip` → `TaskTagFilterStrip`
- **创建页面特定的Provider**：
  - `completedTasksFilterProvider`（StateNotifierProvider）
  - `archivedTasksFilterProvider`（StateNotifierProvider）
  - `trashedTasksFilterProvider`（StateNotifierProvider）
- **修改Repository方法**：为分页查询方法添加筛选参数

```dart
// Repository 方法签名修改
Future<List<Task>> listCompletedTasks({
  required int limit,
  required int offset,
  String? contextTag,
  String? priorityTag,
  String? urgencyTag,
  String? importanceTag,
});

// Provider 使用筛选
final completedTasksPaginationProvider = StateNotifierProvider<
    CompletedTasksPaginationNotifier, CompletedTasksPaginationState>((ref) {
  return CompletedTasksPaginationNotifier(ref);
});

class CompletedTasksPaginationNotifier {
  Future<void> loadInitial() async {
    final filter = ref.watch(completedTasksFilterProvider);
    final tasks = await _repository.listCompletedTasks(
      limit: _pageSize,
      offset: 0,
      contextTag: filter.contextTag,
      priorityTag: filter.priorityTag,
      urgencyTag: filter.urgencyTag,
      importanceTag: filter.importanceTag,
    );
  }
}
```

### 3.6 项目筛选功能

#### 3.6.1 数据模型扩展
- **`TaskFilterState`** 扩展：
```dart
@immutable
class TaskFilterState {
  const TaskFilterState({
    this.contextTag,
    this.priorityTag,
    this.urgencyTag,
    this.importanceTag,
    this.projectId,      // 新增：项目ID筛选
    this.milestoneId,    // 新增：里程碑ID筛选
    this.showNoProject,  // 新增：是否只显示无项目任务
  });

  final String? contextTag;
  final String? priorityTag;
  final String? urgencyTag;
  final String? importanceTag;
  final String? projectId;     // 新增
  final String? milestoneId;   // 新增
  final bool showNoProject;    // 新增：true 表示只显示不属于任何项目的任务
}
```

#### 3.6.2 UI组件扩展
- **`TaskTagFilterStrip`** 扩展为 **`TaskFilterStrip`**：
  - 保留标签筛选UI
  - 新增项目筛选UI区域
  - 项目筛选UI：
    - 横向滚动的项目列表
    - 每个项目显示为可点击的Chip
    - 支持"无项目"选项
    - 如果选中项目，显示里程碑筛选（如果有里程碑）

```dart
// 项目筛选UI示例
Widget _buildProjectFilter(BuildContext context, WidgetRef ref, TaskFilterState filter) {
  final projectsAsync = ref.watch(activeProjectsProvider);
  
  return projectsAsync.when(
    data: (projects) {
      final widgets = <Widget>[];
      
      // "无项目"选项
      widgets.add(
        ModernTag(
          label: '无项目', // 或 l10n.noProject
          selected: filter.showNoProject,
          onTap: () => ref.read(filterProvider.notifier).toggleShowNoProject(),
        ),
      );
      
      // 项目列表
      widgets.addAll(
        projects.map((project) => ModernTag(
          label: project.title,
          selected: filter.projectId == project.projectId,
          onTap: () => ref.read(filterProvider.notifier).setProjectId(
            filter.projectId == project.projectId ? null : project.projectId,
          ),
        )),
      );
      
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: widgets),
      );
    },
    loading: () => const SizedBox.shrink(),
    error: (_, __) => const SizedBox.shrink(),
  );
}
```

#### 3.6.3 Repository层扩展
- **所有分页查询方法**添加项目筛选参数：
```dart
Future<List<Task>> listCompletedTasks({
  required int limit,
  required int offset,
  String? contextTag,
  String? priorityTag,
  String? urgencyTag,
  String? importanceTag,
  String? projectId,      // 新增
  String? milestoneId,    // 新增
  bool? showNoProject,    // 新增
});
```

- **查询逻辑**：
```dart
// IsarTaskRepository 实现
@override
Future<List<Task>> listCompletedTasks({...}) async {
  QueryBuilder<TaskEntity, TaskEntity, QWhere> query = _isar.taskEntitys
      .filter()
      .statusEqualTo(TaskStatus.completedActive);
  
  // 项目筛选
  if (showNoProject == true) {
    query = query.projectIdIsNull();
  } else if (projectId != null && projectId.isNotEmpty) {
    query = query.projectIdEqualTo(projectId);
    if (milestoneId != null && milestoneId.isNotEmpty) {
      query = query.milestoneIdEqualTo(milestoneId);
    }
  }
  
  final allTasks = await query.findAll();
  // ... 标签筛选逻辑（在内存中筛选）
  // ... 排序和分页逻辑
}
```

### 3.7 页面布局调整

#### 3.7.1 筛选UI位置
- **位置**：页面顶部，AppBar下方
- **组件**：`TaskFilterStrip`（包含标签筛选和项目筛选）
- **布局**：可折叠设计（复用 `InboxFilterCollapsible` 模式）

```dart
// 页面结构示例
CustomScrollView(
  slivers: [
    SliverToBoxAdapter(
      child: TaskFilterCollapsible(
        filterProvider: completedTasksFilterProvider, // 页面特定
        showProjectFilter: true, // 是否显示项目筛选
      ),
    ),
    // ... 任务列表
  ],
)
```

#### 3.7.2 任务Tile布局
- **第一行**：任务标题
- **第二行**：
  - 标签（只读）
  - 项目/里程碑信息（只读）
  - 时间显示（绝对格式，精确到分钟）
- **布局**：使用 `Wrap`，自动换行

## 四、实施计划

### 阶段1：UI样式统一和只读展示
1. ✅ 移除回收站Card背景色
2. ✅ 实现标签只读展示（三个Tile组件）
3. ✅ 实现项目/里程碑只读展示（三个Tile组件）
4. ✅ 修改时间显示格式为绝对时间（精确到分钟）

### 阶段2：筛选功能基础
1. ✅ 重构 `InboxFilterState` → `TaskFilterState`（通用化）
2. ✅ 重构 `InboxFilterNotifier` → `TaskFilterNotifier`（通用化）
3. ✅ 重构 `InboxTagFilterStrip` → `TaskTagFilterStrip`（通用化）
4. ✅ 创建页面特定的筛选Provider

### 阶段3：标签筛选功能
1. ✅ 为Repository的分页方法添加标签筛选参数
2. ✅ 实现Repository层的标签筛选逻辑
3. ✅ 更新PaginationNotifier使用筛选条件
4. ✅ 在三个页面集成标签筛选UI

### 阶段4：项目筛选功能
1. ✅ 扩展 `TaskFilterState` 支持项目筛选
2. ✅ 扩展 `TaskFilterNotifier` 支持项目筛选操作
3. ✅ 实现项目筛选UI组件
4. ✅ 为Repository的分页方法添加项目筛选参数
5. ✅ 实现Repository层的项目筛选逻辑
6. ✅ 更新PaginationNotifier使用项目筛选条件
7. ✅ 在四个页面（Inbox + 三个完成页面）集成项目筛选UI

### 阶段5：Inbox页面复用
1. ✅ 更新Inbox页面使用新的通用筛选组件和Provider
2. ✅ 确保向后兼容

## 五、文件清单

### 5.1 修改的文件
- `lib/presentation/completion_management/widgets/completed_task_tile.dart`
- `lib/presentation/completion_management/widgets/archived_task_tile.dart`
- `lib/presentation/completion_management/widgets/trashed_task_tile.dart`
- `lib/presentation/completion_management/widgets/completion_time_display.dart`
- `lib/presentation/completion_management/completed_page.dart`
- `lib/presentation/completion_management/archived_page.dart`
- `lib/presentation/completion_management/trash_page.dart`
- `lib/presentation/widgets/inline_project_milestone_display.dart`
- `lib/core/providers/app_providers.dart`（筛选Provider）
- `lib/data/repositories/task_repository.dart`（筛选查询）
- `lib/presentation/inbox/widgets/inbox_tag_filter_strip.dart`（重构为通用组件）
- `lib/presentation/inbox/inbox_page.dart`（使用新组件）

### 5.2 新建的文件
- `lib/presentation/widgets/task_filter_strip.dart`（通用筛选UI组件）
- `lib/presentation/widgets/task_filter_collapsible.dart`（可折叠筛选区域）

### 5.3 测试文件
- `test/data/repositories/task_repository_filter_test.dart`（筛选逻辑测试）
- `test/presentation/widgets/task_filter_strip_test.dart`（筛选UI测试）

## 六、注意事项

### 6.1 向后兼容
- Inbox页面现有的筛选功能必须保持正常工作
- 重构筛选组件时，确保Inbox页面平滑迁移

### 6.2 性能考虑
- 项目筛选在数据库层实现（使用Isar索引）
- 标签筛选在数据库层或内存层实现（根据数据量选择）
- 筛选条件变化时，分页状态需要重置（offset=0）

### 6.3 用户体验
- 筛选UI应该可以折叠，节省屏幕空间
- 活动筛选条件应该高亮显示
- 提供"清除所有筛选"的快捷按钮

### 6.4 国际化
- 时间格式根据系统locale自动适配
- 筛选选项文本需要国际化支持

## 七、验收标准

### 7.1 UI样式
- [ ] 三个页面列表样式完全一致（无背景色差异）
- [ ] 标签正确显示且为只读状态
- [ ] 项目/里程碑正确显示且为只读状态
- [ ] 时间显示为绝对格式，精确到分钟，符合地区格式

### 7.2 筛选功能
- [ ] 三个页面都支持标签筛选（场景、紧急度、重要度）
- [ ] 三个页面都支持项目筛选
- [ ] 四个页面（Inbox + 三个完成页面）筛选功能一致
- [ ] 筛选条件可以组合使用
- [ ] 筛选后分页正确工作

### 7.3 性能
- [ ] 筛选操作响应时间 < 200ms
- [ ] 大数据量下（1000+任务）筛选性能可接受
- [ ] 筛选条件变化时，分页正确重置

### 7.4 兼容性
- [ ] Inbox页面功能不受影响
- [ ] 旧数据（无标签、无项目）正确显示
- [ ] 国际化正确工作

