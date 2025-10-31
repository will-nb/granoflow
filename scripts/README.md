# Scripts

## test

并行执行 `test/` 目录下的所有 Dart 测试文件（`*_test.dart`）。

特点：
- 吞掉单个文件的中间输出，仅打印粗略进度百分比（非精确）
- 结束时输出汇总：
  - Failed files（失败文件列表）
  - Errors（去重，最多 200 行）
  - Warnings（去重，最多 200 行）
  - Failure snippets（每失败文件最多 50 行片段）
- 进程返回码：有失败文件返回 1，否则返回 0

用法：
```bash
scripts/anz test

# 可选：控制并行度，默认 2~8（与 CPU 数相关）
ANZ_TEST_WORKERS=6 scripts/anz test
```


