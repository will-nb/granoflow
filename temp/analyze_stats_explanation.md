# analyze_stats.py 脚本工作原理说明

## 概述

`analyze_stats.py` 脚本用于分析 `dart analyze --format=json` 输出的 JSON 结果，统计错误信息并按不同维度分组展示。

## JSON 结构

`dart analyze --format=json` 输出的 JSON 格式如下：

```json
{
  "version": 1,
  "diagnostics": [
    {
      "code": "invalid_override",
      "severity": "ERROR",
      "type": "COMPILE_TIME_ERROR",
      "location": {
        "file": "/path/to/file.dart",
        "range": {
          "start": {"offset": 2542, "line": 63, "column": 16},
          "end": {"offset": 2555, "line": 63, "column": 29}
        }
      },
      "problemMessage": "错误描述信息...",
      "contextMessages": [...],
      "documentation": "https://dart.dev/diagnostics/invalid_override"
    },
    ...
  ]
}
```

或者可能是数组格式（多个文件的分析结果）：

```json
[
  {
    "type": "lint",
    "diagnostics": [...]
  },
  ...
]
```

## 脚本处理流程

### 1. 加载 JSON 文件 (`load_analyze_results`)

```python
def load_analyze_results(file_path: Path) -> List[dict]:
    # 读取文件内容
    content = file_path.read_text(encoding="utf-8")
    data = json.loads(content)
    
    diagnostics: List[dict] = []
    
    # 处理两种可能的 JSON 格式
    if isinstance(data, list):
        # 数组格式：遍历每个条目，提取 diagnostics
        for entry in data:
            if entry.get("type") != "lint":
                continue
            diagnostics.extend(entry.get("diagnostics", []))
    elif isinstance(data, dict):
        # 字典格式：直接提取 diagnostics 数组
        diagnostics.extend(data.get("diagnostics", []))
    
    return diagnostics
```

**作用**：统一处理两种 JSON 格式，提取所有诊断信息到一个列表中。

### 2. 提取文件路径 (`get_file_path`)

```python
def get_file_path(diag: dict) -> str:
    location = diag.get("location", {})
    file_path = location.get("file", "")
    if file_path:
        # 转换为相对路径（相对于当前工作目录）
        return str(Path(file_path).relative_to(Path.cwd()))
    return ""
```

**作用**：从诊断信息中提取文件路径，并转换为相对路径（更易读）。

### 3. 分组统计

脚本提供三种分组方式：

#### a) 按错误代码分组 (`group_by_code`)

```python
def group_by_code(diagnostics: List[dict]) -> Dict[str, List[dict]]:
    groups: Dict[str, List[dict]] = defaultdict(list)
    for diag in diagnostics:
        code = diag.get("code", "unknown")  # 例如: "invalid_override"
        groups[code].append(diag)
    return groups
```

**作用**：将所有诊断信息按错误代码（如 `invalid_override`、`argument_type_not_assignable`）分组。

#### b) 按文件路径分组 (`group_by_file`)

```python
def group_by_file(diagnostics: List[dict]) -> Dict[str, List[dict]]:
    groups: Dict[str, List[dict]] = defaultdict(list)
    for diag in diagnostics:
        file_path = get_file_path(diag)
        if file_path:
            groups[file_path].append(diag)
    return groups
```

**作用**：将所有诊断信息按文件路径分组。

#### c) 按严重程度分组 (`group_by_severity`)

```python
def group_by_severity(diagnostics: List[dict]) -> Dict[str, List[dict]]:
    groups: Dict[str, List[dict]] = defaultdict(list)
    for diag in diagnostics:
        severity = diag.get("severity", "UNKNOWN")  # ERROR, WARNING, INFO
        groups[severity].append(diag)
    return groups
```

**作用**：将所有诊断信息按严重程度（ERROR、WARNING、INFO）分组。

### 4. 输出统计信息

#### a) 总体统计 (`print_summary`)

```python
def print_summary(diagnostics: List[dict]) -> None:
    by_severity = group_by_severity(diagnostics)
    error_count = len(by_severity.get("ERROR", []))
    warning_count = len(by_severity.get("WARNING", []))
    info_count = len(by_severity.get("INFO", []))
    total = len(diagnostics)
    
    print(f"[analyze:stats] Current issues:")
    print(f"  ERROR: {error_count}")
    print(f"  WARNING: {warning_count}")
    print(f"  INFO: {info_count}")
    print(f"  Total: {total}")
```

**输出示例**：
```
[analyze:stats] Current issues:
  ERROR: 45
  WARNING: 12
  INFO: 8
  Total: 65
```

#### b) 按错误代码统计 (`print_code_stats`)

```python
def print_code_stats(diagnostics: List[dict]) -> None:
    by_code = group_by_code(diagnostics)
    
    # 按出现次数排序
    sorted_codes = sorted(
        by_code.items(),
        key=lambda x: len(x[1]),  # 按每个代码的错误数量排序
        reverse=True
    )
    
    # 输出前 20 个最常见的错误代码
    for idx, (code, diags) in enumerate(sorted_codes[:20], 1):
        # 统计文件分布（哪些目录有这个错误）
        files = set(get_file_path(d) for d in diags)
        file_dirs = set(Path(f).parts[0] for f in files)  # 提取顶层目录
        
        # 统计严重程度分布
        error_count = sum(1 for d in diags if d.get("severity") == "ERROR")
        warning_count = sum(1 for d in diags if d.get("severity") == "WARNING")
        info_count = sum(1 for d in diags if d.get("severity") == "INFO")
        
        # 格式化输出
        print(f"  {idx}. {code}: {len(diags)} (E:{error_count} W:{warning_count} I:{info_count}) - {dirs_str}")
```

**输出示例**：
```
[analyze:stats] Top error codes:
  1. invalid_override: 18 (E:18) - integration_test
  2. argument_type_not_assignable: 15 (E:15) - integration_test, test
  3. uri_does_not_exist: 8 (E:8) - integration_test, lib
  4. undefined_function: 4 (E:4) - lib
  ...
```

#### c) 按文件统计 (`print_file_stats`)

```python
def print_file_stats(diagnostics: List[dict]) -> None:
    by_file = group_by_file(diagnostics)
    
    # 按错误数量排序
    sorted_files = sorted(
        by_file.items(),
        key=lambda x: len(x[1]),
        reverse=True
    )
    
    # 输出前 20 个错误最多的文件
    for idx, (file_path, diags) in enumerate(sorted_files[:20], 1):
        codes = set(d.get("code", "unknown") for d in diags)
        codes_str = ", ".join(sorted(codes)[:3])
        print(f"  {idx}. {file_path}: {len(diags)} issues ({codes_str})")
```

**输出示例**：
```
[analyze:stats] Top files with issues:
  1. integration_test/clock_wave_layout_test.dart: 20 issues (invalid_override, argument_type_not_assignable, ...)
  2. integration_test/fixtures/task_test_data.dart: 5 issues (argument_type_not_assignable, ...)
  ...
```

## 使用示例

### 基本用法

```bash
# 1. 生成 analyze JSON 结果
dart analyze --format=json > .tmp/analyze_before.json

# 2. 统计结果（默认按错误代码分组）
python3 scripts/anz_modules/fix/analyze_stats.py .tmp/analyze_before.json
```

### 按文件分组

```bash
python3 scripts/anz_modules/fix/analyze_stats.py .tmp/analyze_before.json --group-by file
```

### 显示所有统计信息

```bash
python3 scripts/anz_modules/fix/analyze_stats.py .tmp/analyze_before.json --all
```

## 在修复流程中的作用

1. **步骤 1**：AI 运行 `analyze_stats.py` 查看当前错误统计
2. **步骤 2**：AI 根据统计结果选择出现次数最多的错误代码作为修复目标
3. **步骤 4**：修复后再次运行 `analyze_stats.py` 对比修复前后的变化

## 关键数据结构

### Diagnostic 字典结构

每个诊断信息包含以下字段：

- `code`: 错误代码（如 `"invalid_override"`）
- `severity`: 严重程度（`"ERROR"`、`"WARNING"`、`"INFO"`）
- `type`: 错误类型（如 `"COMPILE_TIME_ERROR"`）
- `location`: 位置信息
  - `file`: 文件路径（绝对路径）
  - `range`: 代码范围
    - `start`: 起始位置（offset, line, column）
    - `end`: 结束位置（offset, line, column）
- `problemMessage`: 错误描述
- `contextMessages`: 上下文信息（可选）
- `documentation`: 文档链接（可选）

## 总结

`analyze_stats.py` 脚本的核心功能是：
1. **解析** JSON 格式的 analyze 结果
2. **分组** 按不同维度（代码、文件、严重程度）组织数据
3. **统计** 计算各维度的数量
4. **展示** 以易读的格式输出统计结果

这样 AI 可以快速了解：
- 总共有多少错误
- 哪些错误类型最常见
- 哪些文件错误最多
- 错误的严重程度分布

从而帮助 AI 做出决策：优先修复哪种错误类型。
