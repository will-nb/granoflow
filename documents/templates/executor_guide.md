# 执行器综合使用指南

## 概述

本指南介绍如何使用各种执行器来执行不同的工作流程，包括：
- Preview 生成
- Plan 执行
- Step 执行
- Step-Done 执行

## 执行器列表

### 1. Plan 执行器
- **文件**: `documents/templates/plan_executor.py`
- **用途**: 执行完整的 plan 流程
- **流程**: YAML更新 → 测试创建 → 代码实现 → 验证 → pre-commit检查
- **重试**: 最多3次
- **日志**: `documents/plan-logs/plan_error_*.json`

### 2. Step-Done 执行器
- **文件**: `documents/templates/step_done_executor.py`
- **用途**: 执行 step-done 流程
- **流程**: YAML更新 → 测试创建 → 验证 → Git提交
- **重试**: 最多5次
- **日志**: `documents/plan-logs/step_done_error_*.json`

### 3. Git 提交处理工具
- **文件**: `documents/templates/git_commit_helper.py`
- **用途**: 处理 Git 提交和错误处理
- **功能**: 时间检查、pre-commit、错误重试
- **重试**: 最多5次

### 4. 错误日志记录工具
- **文件**: `documents/templates/error_logging_helper.py`
- **用途**: 记录错误日志
- **功能**: JSON格式错误记录、重试跟踪
- **特点**: 中文错误描述，便于问题排查

## 使用流程

### 1. 完整工作流程

```bash
# 1. 生成 Preview 文档
# 用户提到 "preview" 时，AI 自动生成

# 2. 生成 Plan 文档
# 用户提到 "plan" 时，AI 自动生成

# 3. 执行 Plan 流程
python documents/templates/plan_executor.py documents/plan/251025-1-plan.yaml

# 4. 生成 Step 文档
# 用户提到具体代码实现需求时，AI 自动生成

# 5. 执行 Step 流程
# 用户确认 step 文档后，AI 自动执行代码实现

# 6. 用户手工测试
# 用户测试代码实现

# 7. 执行 Step-Done 流程
python documents/templates/step_done_executor.py documents/plan/251025-1-step-done.yaml
```

### 2. 单独执行流程

#### 2.1 只执行 Plan 流程
```bash
# 执行 plan 流程
python documents/templates/plan_executor.py documents/plan/251025-1-plan.yaml

# 查看执行结果
ls -la documents/plan-logs/
```

#### 2.2 只执行 Step-Done 流程
```bash
# 执行 step-done 流程
python documents/templates/step_done_executor.py documents/plan/251025-1-step-done.yaml

# 查看执行结果
ls -la documents/plan-logs/
```

#### 2.3 手动处理 Git 提交
```bash
# 手动处理 Git 提交
python documents/templates/git_commit_helper.py
```

## 错误处理

### 1. 错误日志查看

```bash
# 查看所有错误日志
ls -la documents/plan-logs/

# 查看最新的错误日志
ls -t documents/plan-logs/*.json | head -1 | xargs cat | jq .

# 查看错误日志摘要
python documents/templates/error_logging_helper.py
```

### 2. 错误日志格式

```json
{
  "timestamp": "2025-01-25 14:30:00",
  "step_name": "run_tests",
  "error_content": "Test failed: expected true but got false",
  "estimated_cause": "测试用例逻辑错误",
  "solution_attempted": "检查测试用例和实现代码",
  "failure_manifestation": "flutter test命令执行失败",
  "excluded_possibilities": "排除了权限问题",
  "retry_count": 1,
  "max_retries": 3,
  "status": "retrying"
}
```

### 3. 重试机制

- **Plan 执行器**: 最多重试3次
- **Step-Done 执行器**: 最多重试5次
- **Git 提交处理**: 最多重试5次

## 配置要求

### 1. 环境要求

- Python 3.7+
- Flutter 环境
- Git 仓库
- pre-commit（可选）

### 2. 目录结构

```
documents/
├── templates/
│   ├── plan_executor.py
│   ├── step_done_executor.py
│   ├── git_commit_helper.py
│   └── error_logging_helper.py
├── plan-logs/
│   ├── plan_error_*.json
│   └── step_done_error_*.json
└── plan/
    ├── YYMMDD-N-preview.yaml
    ├── YYMMDD-N-plan.yaml
    ├── YYMMDD-N-step.yaml
    └── YYMMDD-N-step-done.yaml
```

## 故障排除

### 1. 常见问题

#### 执行器无法启动
- **原因**: Python 环境问题
- **解决**: 检查 Python 版本和依赖

#### 配置文件格式错误
- **原因**: YAML 文件格式不正确
- **解决**: 检查 YAML 文件格式

#### 权限问题
- **原因**: 文件权限不足
- **解决**: 检查文件权限

#### 依赖问题
- **原因**: 缺少必要的依赖包
- **解决**: 安装缺失的依赖

### 2. 手动恢复

如果自动执行失败，可以手动执行各个步骤：

```bash
# 1. 手动更新 YAML 文件
# 根据配置文件手动创建/修改 YAML 文件

# 2. 手动创建/修改测试文件
# 根据配置文件手动创建/修改测试文件

# 3. 手动实现代码
# 根据配置文件手动实现代码

# 4. 手动运行验证
flutter test
flutter analyze

# 5. 手动运行 pre-commit
pre-commit run --all-files

# 6. 手动提交
git add .
git commit -m "feat: 手动提交"
```

## 最佳实践

### 1. 执行前检查

- 确保在正确的项目目录
- 检查配置文件格式
- 确保环境正常
- 备份重要文件

### 2. 执行中监控

- 监控错误日志
- 检查执行状态
- 及时处理错误

### 3. 执行后验证

- 检查执行结果
- 验证功能正常
- 清理临时文件

## 注意事项

1. **统一日志目录**: 所有执行器都使用 `documents/plan-logs` 目录
2. **错误日志格式**: 使用 JSON 格式，包含中文错误描述
3. **重试机制**: 不同执行器有不同的重试次数
4. **自动退出**: 达到最大重试次数后自动退出
5. **日志记录**: 所有操作都记录到日志文件
6. **环境要求**: 确保所有必要的环境都已安装
7. **权限检查**: 确保有足够的文件读写权限