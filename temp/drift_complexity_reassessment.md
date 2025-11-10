# Drift 复杂度重新评估

## 1. 实际查询复杂度分析

### 1.1 当前 Isar 查询模式

从代码分析看，项目中的查询都非常简单：

```dart
// 简单等值查询
.filter().taskIdEqualTo(taskId).findFirst()
.filter().slugEqualTo(slug).findFirst()

// 简单条件查询
.filter().parentIdIsNull().sortBySortIndex().findAll()
.filter().statusEqualTo(status).findAll()

// 简单范围查询
.filter().dueAtBetween(start, end).findAll()
```

**特点：**
- ✅ 都是简单的 filter + sort + find
- ✅ 没有复杂的 JOIN
- ✅ 没有复杂的聚合查询
- ✅ 没有复杂的子查询

### 1.2 Drift 对应的查询

对于这些简单查询，Drift 的写法也很简单：

```dart
// 简单等值查询
select(tasks)..where((t) => t.taskId.equals(taskId)).getSingle()
select(tasks)..where((t) => t.slug.equals(slug)).getSingle()

// 简单条件查询
select(tasks)..where((t) => t.parentId.isNull()).get()
select(tasks)..where((t) => t.status.equals(status)).get()

// 简单范围查询
select(tasks)..where((t) => t.dueAt.isBetweenValues(start, end)).get()
```

**特点：**
- ✅ 类型安全（编译时检查）
- ✅ 语法清晰（链式调用）
- ✅ 与 Isar 的复杂度相当

## 2. 实体定义复杂度重新评估

### 2.1 Drift Table 定义示例

对于简单的实体，Drift 的定义其实并不复杂：

```dart
// Drift Table 定义（约 50-80 行）
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get status => intEnum<TaskStatus>()();
  DateTimeColumn get dueAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get parentId => text().nullable()();
  RealColumn get sortIndex => real()();
  TextColumn get projectId => text().nullable()();
  TextColumn get milestoneId => text().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

// Data 类（约 30-50 行）
class Task extends DataClass implements Insertable<Task> {
  final String id;
  final String title;
  final TaskStatus status;
  final DateTime? dueAt;
  final DateTime createdAt;
  final String? parentId;
  final double sortIndex;
  final String? projectId;
  final String? milestoneId;
  
  // 构造函数和 toJson/fromJson
}
```

**总行数：约 80-130 行/实体**

### 2.2 ObjectBox/Realm 实体定义

```dart
// ObjectBox 实体（约 60-100 行）
@Entity()
class TaskEntity {
  @Id()
  int obxId = 0;
  
  @Unique()
  @Index()
  late String id;
  
  late String title;
  @enumerated
  late TaskStatus status;
  DateTime? dueAt;
  late DateTime createdAt;
  @Index()
  String? parentId;
  double sortIndex = 0;
  @Index()
  String? projectId;
  @Index()
  String? milestoneId;
}
```

**总行数：约 60-100 行/实体**

### 2.3 复杂度对比

| 维度 | Drift | ObjectBox/Realm |
|------|-------|-----------------|
| **定义行数** | 80-130 行 | 60-100 行 |
| **复杂度** | 中等（需要理解 Table 和 Data 类） | 低（只需要注解） |
| **代码生成** | 自动生成 Data 类和查询方法 | 自动生成查询方法 |
| **类型安全** | ✅ 完全类型安全 | ✅ 类型安全 |

**结论：Drift 的实体定义确实更复杂一些，但差距不大（+20-30 行/实体）**

## 3. 迁移工作量重新评估

### 3.1 实体迁移

- **Drift**: 每个实体需要定义 Table 和 Data 类（~100 行）
- **ObjectBox/Realm**: 每个实体只需要注解（~80 行）
- **差距**: +20 行/实体 × 8 个实体 = +160 行

**工作量差距：约 1-2 天**

### 3.2 Repository 迁移

- **Drift**: 查询语法不同，但逻辑相同
- **ObjectBox/Realm**: 查询语法类似 Isar
- **差距**: Drift 需要学习新的查询 API

**工作量差距：约 2-3 天**

### 3.3 学习成本

- **Drift**: 需要理解 Table/Data 类概念和查询 API
- **ObjectBox/Realm**: 与 Isar 相似，学习成本低

**工作量差距：约 2-3 天**

### 3.4 总工作量重新估算

| 方案 | 之前估算 | 重新估算 | 差距 |
|------|---------|---------|------|
| **ObjectBox** | 25-30 天 | 25-30 天 | - |
| **Realm** | 25-30 天 | 25-30 天 | - |
| **Drift** | 30-35 天 | **27-32 天** | **+2-5 天** |

## 4. 重新评估结论

### 4.1 之前的评估问题

1. **高估了实体定义的复杂度**：虽然需要定义 Table 和 Data 类，但代码生成会处理很多细节
2. **高估了查询迁移的复杂度**：对于简单查询，Drift 的语法并不复杂
3. **高估了学习成本**：Drift 的文档和示例很丰富，学习曲线并不陡峭

### 4.2 实际复杂度

**Drift 的迁移复杂度：中等（不是"很麻烦"）**

- ✅ 实体定义：+20 行/实体（可接受）
- ✅ 查询迁移：语法不同但逻辑相同（可接受）
- ✅ 学习成本：需要 2-3 天学习（可接受）
- ✅ 总工作量：+2-5 天（可接受）

### 4.3 优势重新审视

Drift 的优势在简单项目中仍然存在：

1. **String 主键完美支持**：不需要混合方案
2. **类型安全查询**：编译时检查，减少运行时错误
3. **成熟稳定**：SQLite 是业界标准
4. **关系支持**：虽然项目关系简单，但未来扩展更容易

## 5. 修正后的建议

### 5.1 复杂度对比（修正后）

| 方案 | 工作量 | 主键支持 | 学习成本 | 复杂度 |
|------|--------|----------|----------|--------|
| **ObjectBox** | 25-30 天 | ⚠️ 混合方案 | 低 | 低 |
| **Realm** | 25-30 天 | ✅ 完美 | 低 | 低 |
| **Drift** | **27-32 天** | ✅ 完美 | **中** | **中** |

### 5.2 修正后的建议

**Drift 并不是"很麻烦"，只是"稍微复杂一些"**

- ✅ 如果**重视类型安全**和**String 主键完美支持**，Drift 是很好的选择
- ✅ 如果**希望快速迁移**，ObjectBox 或 Realm 更合适
- ✅ 如果**时间充裕**且**希望未来扩展更容易**，可以考虑 Drift

**之前的评估过于保守，Drift 的实际复杂度是可以接受的。**
