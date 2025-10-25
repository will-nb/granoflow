# 执行器系统总结

## 系统概述

本执行器系统提供了一套完整的自动化工作流程，包括：
- Preview 生成
- Plan 执行
- Step 执行
- Step-Done 执行

## 核心组件

### 1. 执行器

| 执行器 | 文件 | 用途 | 重试次数 | 日志文件 |
|--------|------|------|----------|----------|
| Plan 执行器 | `plan_executor.py` | 执行 plan 流程 | 3次 | `plan_error_*.json` |
| Step-Done 执行器 | `step_done_executor.py` | 执行 step-done 流程 | 5次 | `step_done_error_*.json` |
| Git 提交处理 | `git_commit_helper.py` | 处理 Git 提交 | 5次 | 集成到其他执行器 |
| 错误日志记录 | `error_logging_helper.py` | 记录错误日志 | - | 所有执行器共用 |

### 2. 模板文件

| 模板 | 文件 | 用途 | 基于 |
|------|------|------|------|
| Preview 模板 | `preview_template.yaml` | 生成预览文档 | 用户需求 |
| Plan 模板 | `plan_template.yaml` | 生成计划文档 | Preview 文档 |
| Step 模板 | `step_template.yaml` | 生成步骤文档 | Preview 文档 |
| Step-Done 模板 | `step_done_template.yaml` | 生成完成文档 | Step 文档 |

### 3. 使用指南

| 指南 | 文件 | 用途 | 内容 |
|------|------|------|------|
| 综合使用指南 | `executor_guide.md` | 详细介绍所有执行器 | 完整工作流程和故障排除 |
| 快速开始指南 | `quick_start.md` | 快速了解和使用 | 基本用法和常见问题 |
| Plan 使用说明 | `plan_executor_usage.md` | Plan 执行器详细说明 | 专门针对 Plan 执行器 |
| Step-Done 使用说明 | `step_done_executor_usage.md` | Step-Done 执行器详细说明 | 专门针对 Step-Done 执行器 |

## 工作流程

### 1. 完整流程

```
用户需求 → Preview 生成 → Plan 生成 → Plan 执行 → Step 生成 → Step 执行 → 用户测试 → Step-Done 执行
```

### 2. 各阶段说明

#### 2.1 Preview 生成
- **触发**: 用户提到 "preview"
- **输出**: 详细设计文档
- **内容**: 新建文件、修改文件、调用关系

#### 2.2 Plan 生成
- **触发**: 用户提到 "plan"
- **输出**: 实施计划文档
- **内容**: YAML更新、测试计划、实现计划、执行跟踪

#### 2.3 Plan 执行
- **触发**: 执行 `plan_executor.py`
- **流程**: YAML更新 → 测试创建 → 代码实现 → 验证 → pre-commit检查
- **重试**: 最多3次

#### 2.4 Step 生成
- **触发**: 用户提到具体代码实现需求
- **输出**: 代码实现计划文档
- **内容**: 代码实现步骤、验证计划

#### 2.5 Step 执行
- **触发**: 用户确认 step 文档后
- **流程**: 代码实现 → 用户测试
- **特点**: 不涉及 YAML 和测试

#### 2.6 Step-Done 执行
- **触发**: 用户执行 "step-done" 命令
- **流程**: YAML更新 → 测试创建 → 验证 → Git提交
- **重试**: 最多5次

## 错误处理机制

### 1. 统一日志目录
- 所有执行器都使用 `documents/plan-logs` 目录
- 日志文件格式：`{executor_name}_error_YYYYMMDD_HHMMSS.json`

### 2. 错误日志格式
```json
{
  "timestamp": "错误发生时间",
  "step_name": "当前步骤名称",
  "error_content": "具体报错内容",
  "estimated_cause": "估计的错误原因",
  "solution_attempted": "尝试的解决方式",
  "failure_manifestation": "失败的具体表现",
  "excluded_possibilities": "排除的可能性",
  "retry_count": "重试次数",
  "max_retries": "最大重试次数",
  "status": "failed|retrying|skipped"
}
```

### 3. 重试机制
- **Plan 执行器**: 最多重试3次
- **Step-Done 执行器**: 最多重试5次
- **Git 提交处理**: 最多重试5次

### 4. 自动退出条件
- 重试次数达到最大值
- 连续3次相同错误
- 严重系统错误

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
│   ├── error_logging_helper.py
│   ├── preview_template.yaml
│   ├── plan_template.yaml
│   ├── step_template.yaml
│   ├── step_done_template.yaml
│   ├── README.md
│   ├── executor_guide.md
│   ├── quick_start.md
│   ├── plan_executor_usage.md
│   ├── step_done_executor_usage.md
│   └── SUMMARY.md
├── plan-logs/
│   ├── plan_error_*.json
│   └── step_done_error_*.json
└── plan/
    ├── YYMMDD-N-preview.yaml
    ├── YYMMDD-N-plan.yaml
    ├── YYMMDD-N-step.yaml
    └── YYMMDD-N-step-done.yaml
```

## 使用方法

### 1. 基本使用

```bash
# 执行 plan 流程
python documents/templates/plan_executor.py documents/plan/251025-1-plan.yaml

# 执行 step-done 流程
python documents/templates/step_done_executor.py documents/plan/251025-1-step-done.yaml

# 手动处理 Git 提交
python documents/templates/git_commit_helper.py
```

### 2. 查看结果

```bash
# 查看错误日志
ls -la documents/plan-logs/

# 查看最新的错误日志
ls -t documents/plan-logs/*.json | head -1 | xargs cat | jq .

# 查看错误日志摘要
python documents/templates/error_logging_helper.py
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
8. **pre-commit 检查**: plan 执行完成后自动运行 pre-commit 检查
9. **Git 提交处理**: step-done 执行完成后自动处理 git 提交
10. **用户测试确认**: step 完成后必须等待用户手工测试通过