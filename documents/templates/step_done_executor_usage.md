# Step-Done 执行器使用说明

## 概述

Step-Done 执行器是一个自动化工具，用于执行完整的 step-done 流程，包括：
1. 更新规范YAML文件
2. 创建测试用例
3. 运行验证
4. 处理Git提交（包含错误处理和重试机制）

## 文件结构

```
documents/templates/
├── step_done_executor.py          # 主执行器
├── git_commit_helper.py           # Git提交处理工具
├── error_logging_helper.py        # 错误日志记录工具
└── step_done_executor_usage.md    # 使用说明（本文件）

documents/plan-logs/               # 错误日志目录
└── step_done_error_*.json         # 错误日志文件
```

## 使用方法

### 1. 基本使用

```bash
# 执行step-done流程
python documents/templates/step_done_executor.py documents/plan/251025-1-step-done.yaml
```

### 2. 参数说明

- `step_done_file`: step-done配置文件路径（必需）
- 日志目录默认为 `documents/plan-logs`
- 最大重试次数为5次

### 3. 执行流程

#### 3.1 配置文件加载
- 加载指定的step-done YAML配置文件
- 验证配置文件格式和内容

#### 3.2 YAML文件更新
- 根据step文档中的代码实现生成新的YAML文件
- 修改现有的YAML文件
- 更新架构索引文件

#### 3.3 测试文件创建
- 创建单元测试文件
- 创建组件测试文件
- 创建集成测试文件

#### 3.4 验证执行
- 运行YAML一致性验证
- 执行所有测试用例
- 检查测试覆盖率

#### 3.5 Git提交处理
- 检查上次提交时间
- 决定是否运行pre-commit
- 执行git提交
- 处理错误和重试

## 错误处理机制

### 1. 错误日志记录

所有错误都会记录到 `documents/plan-logs` 目录，日志格式：

```json
{
  "timestamp": "2025-01-25 14:30:00",
  "step_name": "git_commit",
  "error_content": "fatal: not a git repository",
  "estimated_cause": "当前目录不是git仓库",
  "solution_attempted": "检查当前目录，切换到正确的git仓库目录",
  "failure_manifestation": "git命令执行失败，提示不是git仓库",
  "excluded_possibilities": "排除了权限问题和网络问题",
  "retry_count": 1,
  "max_retries": 5,
  "status": "retrying"
}
```

### 2. 重试机制

- 每个步骤最多重试5次
- 重试间隔根据错误类型调整
- 连续相同错误会触发自动退出

### 3. 自动退出条件

- 重试次数达到5次
- 连续3次相同错误
- 严重系统错误

## 配置要求

### 1. Step-Done 配置文件

必须基于 `step_done_template.yaml` 生成，包含：

```yaml
yaml_updates:
  new_yaml_files:
    files: []
  modified_yaml_files:
    files: []
  architecture_updates:
    files: []

test_creation:
  unit_tests:
    tests: []
  widget_tests:
    tests: []
  integration_tests:
    tests: []

verification:
  yaml_consistency:
    steps: []
  test_execution:
    steps: []
  coverage_check:
    steps: []
```

### 2. 环境要求

- Python 3.7+
- Git 仓库
- Flutter 环境（用于测试）
- pre-commit（可选，用于代码检查）

## 使用示例

### 1. 执行完整的step-done流程

```bash
# 1. 确保在正确的git仓库目录
cd /path/to/granoflow

# 2. 执行step-done流程
python documents/templates/step_done_executor.py documents/plan/251025-1-step-done.yaml

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

### 3. 手动处理Git提交

```bash
# 如果自动提交失败，可以手动处理
python documents/templates/git_commit_helper.py
```

## 故障排除

### 1. 常见错误

#### Git相关错误
- **错误**: `fatal: not a git repository`
- **原因**: 当前目录不是git仓库
- **解决**: 切换到正确的git仓库目录

#### 权限相关错误
- **错误**: `Permission denied`
- **原因**: 文件权限不足
- **解决**: 检查文件权限，使用 `chmod` 修改

#### 依赖相关错误
- **错误**: `ModuleNotFoundError`
- **原因**: 缺少Python依赖
- **解决**: 安装缺失的模块

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
# 根据step-done配置文件手动创建/修改YAML文件

# 2. 手动创建测试文件
# 根据step-done配置文件手动创建测试文件

# 3. 手动运行验证
flutter test
flutter analyze

# 4. 手动提交
git add .
git commit -m "feat: 基于step-done的YAML和测试补充"
```

## 注意事项

1. **确保在正确的git仓库目录**：执行前必须切换到项目根目录
2. **检查配置文件格式**：确保step-done配置文件格式正确
3. **监控错误日志**：定期检查plan-logs目录中的错误日志
4. **备份重要文件**：执行前备份重要的配置文件
5. **测试环境**：确保Flutter测试环境正常
6. **权限检查**：确保有足够的文件读写权限