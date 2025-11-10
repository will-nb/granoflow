# `scripts/anz_modules/fix/issues.py` 安全性分析

## 安全机制检查

### ✅ **1. 备份机制（存在）**

**位置：** `backup_file()` 函数（第131-136行）

```python
def backup_file(path: Path) -> Path:
    rel = path.relative_to(REPO_ROOT)
    backup_path = BACKUP_ROOT / rel
    backup_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, backup_path)
    return backup_path
```

**行为：**
- ✅ 在修改文件前，会先备份到 `.tmp/anz_fix_backup/` 目录
- ✅ 保持原始目录结构
- ✅ 使用 `shutil.copy2()` 保留元数据

**安全性：** ✅ **安全** - 所有修改的文件都有备份

---

### ⚠️ **2. 自动回滚机制（已禁用）**

**位置：** `verify_changes()` 函数（第302-389行）

```python
# Rollback if original errors still exist
if remaining_codes:
    print(f"[anz:fix] ⚠️  {rel}: {len(remaining_codes)} error code(s) still present")
    files_with_remaining.append(path)
    # Don't auto-rollback, let AI decide
    # restore_file(backup_path, path)  # ← 被注释掉了
    # changed_files.remove(path)
```

**行为：**
- ⚠️ **自动回滚已被禁用** - 即使修复失败或引入新错误，也不会自动恢复
- ✅ 备份文件仍然保留，可以手动恢复
- ✅ 脚本会报告哪些文件有问题

**安全性：** ⚠️ **部分安全** - 需要手动恢复，但备份存在

---

### ✅ **3. 验证机制（存在）**

**位置：** `verify_changes()` 函数

**行为：**
- ✅ 修复后重新运行 `dart analyze`
- ✅ 比较修复前后的错误数量
- ✅ 报告修复统计（fixed, remaining, new）
- ✅ 列出有问题的文件

**安全性：** ✅ **安全** - 会验证修复效果

---

### ✅ **4. 文件范围限制（存在）**

**位置：** `FIXERS` 字典和 `predicate` 函数（第227-262行）

**行为：**
- ✅ 只修复注册在 `FIXERS` 字典中的错误类型
- ✅ 每个修复器都有 `predicate` 函数限制文件范围
- ✅ 例如：`_is_test_file` 只修复测试文件
- ✅ 例如：`_is_objectbox_repository` 只修复特定文件

**示例：**
```python
FIXERS = {
    "invalid_override": (invalid_override.apply_invalid_override_fix, _is_test_file),
    "uri_does_not_exist": (import_remap.apply_import_remap, lambda _: True),
    # ...
}
```

**安全性：** ✅ **安全** - 有明确的修复范围限制

---

### ✅ **5. 清理机制（存在）**

**位置：** `cleanup_backup()` 函数和 `main()` 函数末尾

**行为：**
- ✅ 验证完成后清理备份文件
- ✅ 如果备份目录为空，会删除整个备份目录
- ⚠️ **注意**：如果脚本异常退出，备份可能保留

**安全性：** ✅ **安全** - 正常流程会清理备份

---

### ✅ **6. Dry-run 模式（存在）**

**位置：** `main()` 函数（第394行）

```python
parser.add_argument("--dry-run", action="store_true", help="Only list supported issues without applying fixes.")
```

**行为：**
- ✅ 使用 `--dry-run` 参数可以预览会修复哪些文件
- ✅ 不会实际修改任何文件

**安全性：** ✅ **安全** - 可以安全预览

---

## 潜在风险分析

### ⚠️ **风险 1：自动回滚被禁用**

**问题：**
- 如果修复引入了新错误，文件不会自动恢复
- 需要手动使用 `git checkout` 或手动恢复备份

**缓解措施：**
- ✅ 备份文件仍然存在（在 `.tmp/anz_fix_backup/`）
- ✅ 脚本会明确报告哪些文件有问题
- ✅ 可以使用 `git status` 查看修改

**建议：**
- 运行脚本前先 `git commit` 保存当前状态
- 或者手动恢复备份：`cp .tmp/anz_fix_backup/path/to/file.dart lib/path/to/file.dart`

---

### ⚠️ **风险 2：修复器可能引入新错误**

**问题：**
- 某些修复器（如 `undefined_getter`）可能引入新错误
- 脚本不会自动回滚

**缓解措施：**
- ✅ 脚本会报告新引入的错误
- ✅ 可以查看修复前后的对比
- ✅ 有问题的修复器已被禁用（如 `undefined_getter`）

**建议：**
- 检查脚本输出中的 "New issues introduced" 警告
- 如果新错误太多，使用 `git checkout` 恢复

---

### ✅ **风险 3：修复范围限制（已缓解）**

**问题：**
- 如果修复器配置错误，可能修复不应该修复的文件

**缓解措施：**
- ✅ 每个修复器都有 `predicate` 函数限制范围
- ✅ 只修复 `dart analyze` 报告的错误
- ✅ 可以查看 "Supported issues to fix" 列表

**建议：**
- 使用 `--dry-run` 先预览
- 检查修复器配置是否符合预期

---

## 移植到其他项目的安全性

### ✅ **安全特性（可移植）**

1. **备份机制** - 通用，适用于任何项目
2. **验证机制** - 通用，适用于任何 Flutter 项目
3. **Dry-run 模式** - 通用，可以安全预览
4. **文件范围限制** - 通用，但需要根据项目调整 `predicate` 函数

### ⚠️ **需要注意的点**

1. **修复器配置** - 需要根据项目调整 `FIXERS` 字典
2. **修复器逻辑** - 某些修复器是项目特定的（如 Isar -> ObjectBox）
3. **自动回滚** - 默认禁用，需要手动恢复

---

## 安全使用建议

### ✅ **推荐流程**

1. **运行前：**
   ```bash
   # 保存当前状态
   git add -A
   git commit -m "chore: save state before running fix script"
   
   # 或者使用 dry-run 预览
   python3 scripts/anz_modules/fix/issues.py --dry-run
   ```

2. **运行中：**
   ```bash
   # 运行修复脚本
   python3 scripts/anz_modules/fix/issues.py
   ```

3. **运行后：**
   ```bash
   # 检查修复结果
   dart analyze
   
   # 如果修复引入了太多新错误，恢复
   git checkout -- lib/ test/
   # 或者手动恢复备份
   cp -r .tmp/anz_fix_backup/* .
   ```

---

## 结论

### ✅ **总体安全性：高**

**原因：**
1. ✅ 有完整的备份机制
2. ✅ 有验证机制
3. ✅ 有文件范围限制
4. ✅ 有 dry-run 模式
5. ⚠️ 自动回滚被禁用（但备份存在，可手动恢复）

### 🔒 **不会造成破坏性修改的条件**

1. ✅ 运行前先 `git commit` 保存状态
2. ✅ 使用 `--dry-run` 预览（可选）
3. ✅ 检查脚本输出中的警告
4. ✅ 如果新错误太多，使用 `git checkout` 恢复

### ⚠️ **可能的风险**

1. ⚠️ 如果修复引入了新错误，需要手动恢复
2. ⚠️ 如果修复器配置错误，可能修复不应该修复的文件
3. ⚠️ 如果脚本异常退出，备份可能保留（但这是好事）

### 📋 **移植到其他项目的建议**

1. ✅ **可以安全移植** - 框架本身是安全的
2. ⚠️ **需要调整配置** - 根据项目调整 `FIXERS` 字典和 `predicate` 函数
3. ⚠️ **需要调整修复器** - 某些修复器是项目特定的，需要重写或禁用
4. ✅ **建议保留备份机制** - 这是最重要的安全特性
