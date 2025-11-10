# Realm 迁移影响评估

## 1. 概述

从 ObjectBox 改为 Realm 的重大调整影响评估。

## 2. 主要变化点

### 2.1 依赖包变化

**ObjectBox → Realm:**
- `objectbox: ^4.0.0` → `realm: ^20.2.0`
- `objectbox_flutter_libs: ^4.0.0` → 不需要（Realm 内置）
- `objectbox_generator: ^4.0.0` → 不需要（Realm 使用代码生成，但方式不同）

**影响：**
- ✅ Realm 支持 String 作为主键（`@PrimaryKey()` 支持 String）
- ✅ Realm 不需要单独的 flutter_libs 包
- ⚠️ Realm 的代码生成方式可能不同（需要确认）

### 2.2 实体定义方式变化

**ObjectBox:**
```dart
@Entity()
class TaskEntity {
  @Id()
  int obxId = 0;
  
  @Unique()
  @Index()
  late String id;  // 业务 ID
}
```

**Realm（预期）:**
```dart
@RealmModel()
class _TaskEntity {
  @PrimaryKey()
  late String id;  // 业务 ID，直接作为主键
}
```

**影响：**
- ✅ Realm 支持 String 作为主键，不需要额外的 int id
- ✅ 可以完全放弃 ObjectBox 的 @Id() 限制
- ⚠️ Realm 使用 `@RealmModel()` 注解，语法不同
- ⚠️ Realm 实体类需要以 `_` 开头（代码生成约定）

### 2.3 代码生成方式变化

**ObjectBox:**
- 使用 `build_runner` + `objectbox_generator`
- 生成 `objectbox.g.dart` 和 `objectbox-model.json`
- 命令：`flutter pub run build_runner build --delete-conflicting-outputs`

**Realm（预期）:**
- 使用 Realm 自己的代码生成工具
- 生成方式可能不同（需要确认具体命令）
- 可能不需要 build_runner

**影响：**
- ⚠️ 需要更新 `scripts/anz` 中的代码生成命令
- ⚠️ 需要更新 CI/CD 流程
- ⚠️ 需要更新文档说明

### 2.4 API 使用方式变化

**ObjectBox:**
- `Store` / `Box` / `Query` API
- 需要手动管理 Store 生命周期
- 事务：`store.runInTransaction()`

**Realm（预期）:**
- `Realm` / `RealmResults` / `RealmQuery` API
- Realm 实例管理方式不同
- 事务：`realm.write()` / `realm.writeAsync()`

**影响：**
- ⚠️ DatabaseAdapter 实现需要完全重写
- ⚠️ QueryBuilder 实现需要完全重写
- ⚠️ Repository 实现需要调整（但通过 DatabaseAdapter 抽象层，影响较小）

### 2.5 文件路径和命名变化

**需要调整的文件路径：**
- `lib/data/objectbox/**` → `lib/data/realm/**`
- `lib/data/repositories/objectbox/**` → `lib/data/repositories/realm/**`
- `lib/data/database/objectbox_adapter.dart` → `lib/data/database/realm_adapter.dart`
- `lib/data/database/objectbox_query_builder.dart` → `lib/data/database/realm_query_builder.dart`

**影响：**
- ⚠️ 所有文件路径引用需要更新
- ⚠️ 导入语句需要更新
- ⚠️ 测试文件路径需要更新

### 2.6 事务和并发模型变化

**ObjectBox:**
- 单层事务，不支持嵌套
- 写事务会阻塞读事务

**Realm（预期）:**
- 支持嵌套事务（需要确认）
- 可能有不同的并发模型

**影响：**
- ⚠️ 事务 API 设计可能需要调整
- ⚠️ 并发控制逻辑可能需要调整

### 2.7 查询语法变化

**ObjectBox:**
- 使用链式查询构建器
- `box.query().equal().greaterThan().find()`

**Realm（预期）:**
- 可能有不同的查询语法
- 需要确认是否支持链式构建

**影响：**
- ⚠️ QueryBuilder 抽象层需要重新设计
- ⚠️ Repository 查询逻辑可能需要调整

### 2.8 Stream/监听机制变化

**ObjectBox:**
- 使用 `watch()` 方法监听变化
- 返回 Stream

**Realm（预期）:**
- 可能有不同的监听机制
- 需要确认 Stream 支持方式

**影响：**
- ⚠️ DatabaseAdapter 的 Stream API 可能需要调整
- ⚠️ Repository 的 watch 方法可能需要调整

## 3. 保持不变的部分

### 3.1 业务逻辑层
- ✅ 领域模型（Task/Project/Milestone）的 String id 需求不变
- ✅ Service 层的业务逻辑不变
- ✅ UI 层的使用方式不变

### 3.2 抽象层设计
- ✅ DatabaseAdapter 抽象接口可以保持不变（只需要实现方式改变）
- ✅ QueryBuilder 抽象接口可以保持不变（只需要实现方式改变）
- ✅ Repository 接口可以保持不变

### 3.3 测试策略
- ✅ 分阶段测试策略不变
- ✅ 测试范围划分不变
- ✅ 集成测试要求不变

## 4. 需要调整的文档和配置

### 4.1 迭代蓝图文档
- 所有 "ObjectBox" 改为 "Realm"
- 更新实体定义说明
- 更新代码生成命令
- 更新文件路径
- 更新技术细节说明

### 4.2 pubspec.yaml
- 移除 ObjectBox 依赖
- 添加 Realm 依赖
- 移除 objectbox_generator（如果 Realm 不需要）
- 可能需要调整 build_runner 配置

### 4.3 scripts/anz
- 更新代码生成命令
- 更新 clean 命令
- 更新 diagnose:16kb 命令（如果 Realm 有类似需求）

### 4.4 analysis_options.yaml
- 更新 include 路径：`lib/data/realm/**`

### 4.5 README/docs
- 更新数据库说明
- 更新环境准备步骤
- 更新代码生成命令

## 5. 风险评估

### 5.1 高风险项
1. **API 差异**：Realm 和 ObjectBox 的 API 差异较大，DatabaseAdapter 实现需要完全重写
2. **学习曲线**：团队需要学习 Realm 的使用方式
3. **兼容性**：需要确认 Realm 是否解决 Android 16KB 问题（这是迁移的主要目标）

### 5.2 中风险项
1. **代码生成**：Realm 的代码生成方式可能不同，需要重新配置
2. **事务模型**：事务 API 可能需要调整
3. **查询语法**：查询构建器需要重新实现

### 5.3 低风险项
1. **文件路径**：只是路径变化，影响范围可控
2. **文档更新**：主要是文本替换，工作量可控

## 6. 优势分析

### 6.1 Realm 的优势
1. ✅ **原生支持 String 主键**：不需要混合方案（int + String）
2. ✅ **官方维护**：Realm 是官方 SDK，维护更稳定
3. ✅ **功能丰富**：可能提供更多高级功能
4. ✅ **跨平台支持**：支持所有 Flutter 平台

### 6.2 需要确认的问题
1. ❓ **Android 16KB 兼容性**：Realm 是否解决 Android 16KB 页面大小问题？
2. ❓ **性能**：Realm 的性能是否满足需求？
3. ❓ **代码生成**：Realm 的代码生成方式是否简单？
4. ❓ **学习成本**：团队学习 Realm 的成本如何？

## 7. 建议的调整步骤

1. **第一步：确认 Realm 可行性**
   - 确认 Realm 支持 String 主键
   - 确认 Realm 解决 Android 16KB 问题
   - 确认 Realm 的代码生成方式

2. **第二步：更新迭代蓝图**
   - 将所有 "ObjectBox" 改为 "Realm"
   - 更新技术细节说明
   - 更新文件路径和命名

3. **第三步：创建 Realm 实体示例**
   - 创建一个简单的 Realm 实体示例
   - 验证代码生成流程
   - 验证 String 主键支持

4. **第四步：调整实施计划**
   - 根据 Realm 的特性调整实施步骤
   - 更新验证要求

## 8. 需要用户确认的问题

1. **Realm 是否解决 Android 16KB 问题？**（这是迁移的主要目标）
2. **Realm 的 String 主键支持是否符合需求？**
3. **Realm 的代码生成方式是否可以接受？**
4. **是否有 Realm 的使用经验？**
