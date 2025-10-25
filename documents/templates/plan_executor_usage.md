# Plan 执行器使用说明

## 概述

Plan 执行器是一个自动化工具，用于执行完整的 plan 流程，包括：
1. 更新规范YAML文件
2. 创建/修改测试用例
3. 实现代码
4. 运行验证
5. 执行pre-commit检查

## 文件结构

```
documents/templates/
├── plan_executor.py                # 主执行器
├── error_logging_helper.py         # 错误日志记录工具
└── plan_executor_usage.md          # 使用说明（本文件）

documents/plan-logs/                # 错误日志目录
└── plan_error_*.json               # 错误日志文件
```

## 使用方法

### 1. 基本使用

```bash
# 执行plan流程
python documents/templates/plan_executor.py documents/plan/251025-1-plan.yaml
```

### 2. 参数说明

- `plan_file`: plan配置文件路径（必需）
- 日志目录默认为 `documents/plan-logs`
- 最大重试次数为3次

### 3. 执行流程

#### 3.1 配置文件加载
- 加载指定的plan YAML配置文件
- 验证配置文件格式和内容

#### 3.2 YAML文件更新
- 根据plan文档更新规范YAML文件
- 修改现有的YAML文件
- 更新架构索引文件

#### 3.3 测试文件创建/修改
- 创建新的测试文件
- 修改现有的测试文件
- 创建配置测试文件

#### 3.4 代码实现
- 实现新的组件和页面
- 修改现有的组件和页面
- 更新相关逻辑

#### 3.5 验证执行
- 运行所有测试用例
- 执行代码分析
- 检查测试覆盖率

#### 3.6 pre-commit检查
- 运行pre-commit检查
- 处理pre-commit错误
- 记录pre-commit结果

## 错误处理机制

### 1. 错误日志记录

所有错误都会记录到 `documents/plan-logs` 目录，日志格式：

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

### 2. 重试机制

- 每个步骤最多重试3次
- 重试间隔根据错误类型调整
- 连续相同错误会触发自动退出

### 3. 自动退出条件

- 重试次数达到3次
- 连续3次相同错误
- 严重系统错误

## 配置要求

### 1. Plan 配置文件

必须基于 `plan_template.yaml` 生成，包含：

```yaml
yaml_specification_updates:
  updates: []

testing_plan:
  existing_tests:
    tests: []
  new_tests:
    tests: []
  configuration_tests:
    tests: []

implementation_plan:
  new_files: []
  modified_files: []

execution_tracking:
  overall_status: "pending"
  current_phase: "yaml_updates"
  phases: []
```

### 2. 环境要求

- Python 3.7+
- Flutter 环境
- pre-commit（可选，用于代码检查）

## 使用示例

### 1. 执行完整的plan流程

```bash
# 1. 确保在正确的项目目录
cd /path/to/granoflow

# 2. 执行plan流程
python documents/templates/plan_executor.py documents/plan/251025-1-plan.yaml

# 3. 查看执行结果
echo "执行完成，检查错误日志："
ls -la documents/plan-logs/
```

### 2. 查看错误日志

```bash
# 查看最新的错误日志
ls -t documents/plan-logs/*.json | head -1 | xargs cat | jq .

# 查看所有错误日志摘要
python documents/templates/error_logging_helper.py
```

### 3. 手动处理pre-commit

```bash
# 如果pre-commit检查失败，可以手动处理
pre-commit run --all-files

# 或者运行修复
pre-commit run --all-files --hook-stage manual
```

## 故障排除

### 1. 常见错误

#### 测试相关错误
- **错误**: `Test failed: expected true but got false`
- **原因**: 测试用例逻辑错误
- **解决**: 检查测试用例和实现代码

#### 代码分析错误
- **错误**: `error: unused import`
- **原因**: 未使用的导入
- **解决**: 删除未使用的导入

#### pre-commit错误
- **错误**: `pre-commit check failed`
- **原因**: 代码质量问题
- **解决**: 修复代码质量问题

### 2. 日志分析

```bash
# 分析错误日志
python -c "
from documents.templates.error_logging_helper import StepDoneErrorLogger
logger = StepDoneErrorLogger()
print('错误日志摘要:')
import json
print(json.dumps(logger.get_log_summary(), indent=2, ensure_ascii=False))
"
```

### 3. 手动恢复

如果自动执行失败，可以手动执行各个步骤：

```bash
# 1. 手动更新YAML文件
# 根据plan配置文件手动创建/修改YAML文件

# 2. 手动创建/修改测试文件
# 根据plan配置文件手动创建/修改测试文件

# 3. 手动实现代码
# 根据plan配置文件手动实现代码

# 4. 手动运行验证
flutter test
flutter analyze

# 5. 手动运行pre-commit
pre-commit run --all-files
```

## 注意事项

1. **确保在正确的项目目录**：执行前必须切换到项目根目录
2. **检查配置文件格式**：确保plan配置文件格式正确
3. **监控错误日志**：定期检查plan-logs目录中的错误日志
4. **备份重要文件**：执行前备份重要的配置文件
5. **测试环境**：确保Flutter测试环境正常
6. **权限检查**：确保有足够的文件读写权限
7. **pre-commit配置**：确保pre-commit配置正确