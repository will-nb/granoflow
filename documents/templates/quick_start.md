# 快速开始指南

## 概述

本指南帮助您快速了解和使用各种执行器，包括基本用法、常见问题和解决方案。

## 快速开始

### 1. 环境准备

```bash
# 确保在正确的项目目录
cd /path/to/granoflow

# 检查 Python 环境
python --version

# 检查 Flutter 环境
flutter --version

# 检查 Git 状态
git status
```

### 2. 基本使用

#### 2.1 执行 Plan 流程
```bash
# 执行 plan 流程
python documents/templates/plan_executor.py documents/plan/251025-1-plan.yaml
```

#### 2.2 执行 Step-Done 流程
```bash
# 执行 step-done 流程
python documents/templates/step_done_executor.py documents/plan/251025-1-step-done.yaml
```

#### 2.3 手动处理 Git 提交
```bash
# 手动处理 Git 提交
python documents/templates/git_commit_helper.py
```

### 3. 查看结果

```bash
# 查看错误日志
ls -la documents/plan-logs/

# 查看最新的错误日志
ls -t documents/plan-logs/*.json | head -1 | xargs cat | jq .

# 查看错误日志摘要
python documents/templates/error_logging_helper.py
```

## 常见问题

### 1. 执行器无法启动

**问题**: `python: command not found`

**解决方案**:
```bash
# 检查 Python 是否安装
which python
which python3

# 使用 python3 替代 python
python3 documents/templates/plan_executor.py documents/plan/251025-1-plan.yaml
```

### 2. 配置文件格式错误

**问题**: `json.decoder.JSONDecodeError`

**解决方案**:
```bash
# 检查 YAML 文件格式
python -c "import yaml; yaml.safe_load(open('documents/plan/251025-1-plan.yaml'))"

# 修复 YAML 文件格式
# 使用在线 YAML 验证工具或编辑器
```

### 3. 权限问题

**问题**: `Permission denied`

**解决方案**:
```bash
# 检查文件权限
ls -la documents/templates/

# 修改文件权限
chmod +x documents/templates/*.py

# 检查目录权限
ls -la documents/plan-logs/
```

### 4. 依赖问题

**问题**: `ModuleNotFoundError`

**解决方案**:
```bash
# 安装缺失的模块
pip install pyyaml

# 或者使用项目依赖
pip install -r requirements.txt
```

## 故障排除

### 1. 检查日志

```bash
# 查看所有错误日志
ls -la documents/plan-logs/

# 查看特定类型的错误日志
ls -la documents/plan-logs/plan_error_*.json
ls -la documents/plan-logs/step_done_error_*.json

# 查看最新的错误日志
ls -t documents/plan-logs/*.json | head -1 | xargs cat | jq .
```

### 2. 手动执行

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

### 3. 重置环境

```bash
# 清理错误日志
rm -rf documents/plan-logs/*.json

# 重置 Git 状态
git status
git reset --hard HEAD

# 重新开始
python documents/templates/plan_executor.py documents/plan/251025-1-plan.yaml
```

## 最佳实践

### 1. 执行前检查

- ✅ 确保在正确的项目目录
- ✅ 检查配置文件格式
- ✅ 确保环境正常
- ✅ 备份重要文件

### 2. 执行中监控

- ✅ 监控错误日志
- ✅ 检查执行状态
- ✅ 及时处理错误

### 3. 执行后验证

- ✅ 检查执行结果
- ✅ 验证功能正常
- ✅ 清理临时文件

## 获取帮助

### 1. 查看详细文档

- `documents/templates/README.md` - 完整的使用说明
- `documents/templates/executor_guide.md` - 执行器综合使用指南
- `documents/templates/plan_executor_usage.md` - Plan 执行器详细说明
- `documents/templates/step_done_executor_usage.md` - Step-Done 执行器详细说明

### 2. 检查错误日志

```bash
# 查看错误日志摘要
python documents/templates/error_logging_helper.py

# 查看特定错误日志
cat documents/plan-logs/plan_error_20250125_143000.json | jq .
```

### 3. 手动调试

```bash
# 手动运行各个步骤
python documents/templates/git_commit_helper.py
python documents/templates/error_logging_helper.py
```

## 注意事项

1. **统一日志目录**: 所有执行器都使用 `documents/plan-logs` 目录
2. **错误日志格式**: 使用 JSON 格式，包含中文错误描述
3. **重试机制**: 不同执行器有不同的重试次数
4. **自动退出**: 达到最大重试次数后自动退出
5. **日志记录**: 所有操作都记录到日志文件
6. **环境要求**: 确保所有必要的环境都已安装
7. **权限检查**: 确保有足够的文件读写权限