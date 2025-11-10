# 种子导入问题修复迭代计划

## 问题总结

1. **项目重复导入**：项目列表里出现了10个项目（应该是更少的数量）
2. **任务未导入**：tasks一个也没有
3. **标签筛选抖动**：筛选标签点开不断抖动但标签内容是有的

## 修复策略

采用 TDD（测试驱动开发）方式：
1. 先运行集成测试，记录失败情况
2. 根据测试失败信息修复代码
3. 再次运行测试验证修复
4. 重复步骤 2-3 直到所有测试通过

## 迭代步骤

### 迭代 1：初始测试和问题诊断
- [ ] 运行 `scripts/anz test:macos`
- [ ] 记录所有失败的测试用例
- [ ] 分析错误信息，确定根本原因
- [ ] 列出需要修复的具体问题

### 迭代 2：修复任务导入问题
- [ ] 实现 `ObjectBoxTaskRepository.findBySlug()` 方法
- [ ] 在任务导入时添加 seedSlug 检查逻辑
- [ ] 添加详细日志输出
- [ ] 运行测试验证修复

### 迭代 3：修复项目重复导入问题
- [ ] 检查项目 seedSlug 检查逻辑是否正确
- [ ] 确保 ProjectUpdate.seedSlug 正确更新
- [ ] 运行测试验证修复

### 迭代 4：修复标签筛选抖动问题
- [ ] 检查标签筛选相关的 Provider 状态管理
- [ ] 检查是否有无限重建问题
- [ ] 修复状态更新逻辑
- [ ] 运行测试验证修复

### 迭代 5：最终验证
- [ ] 运行所有集成测试
- [ ] 确保所有测试通过
- [ ] 手动验证应用功能正常

## 测试文件

1. `integration_test/seed_import_duplicate_test.dart`
   - 测试项目不会重复导入
   - 测试任务能正确导入
   - 测试任务不会重复导入

2. `integration_test/tag_filter_stability_test.dart`
   - 测试标签筛选不会导致 UI 抖动
   - 测试筛选状态保持稳定

## 执行命令

```bash
# 运行集成测试
scripts/anz test:macos

# 如果测试失败，查看详细错误信息
flutter test integration_test/seed_import_duplicate_test.dart -d macos --verbose
flutter test integration_test/tag_filter_stability_test.dart -d macos --verbose
```

## 注意事项

1. 每次修改后都要运行测试验证
2. 如果测试失败，仔细分析错误信息
3. 添加必要的日志输出以便调试
4. 确保修复不会引入新的问题
