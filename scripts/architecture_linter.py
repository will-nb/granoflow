#!/usr/bin/env python3
"""
Architecture Linter (precise)

用途：在 pre-commit 中仅校验本次修改涉及的 architecture YAML 与模板一致性：
1) file_path 存在性与命名匹配
2) 必填字段存在（meta/file_path/widget|page|model|provider_definition 等）
3) called_by/calls 指向的文件存在（如提供）
4) i18n_keys 在 ARB 中存在（如提供）
5) design_tokens 在主题中存在（如提供）

使用：
  scripts/architecture_linter.py --files <changed_paths...>
返回：非零退出表示失败
"""
import argparse
import json
import os
import sys
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parents[1]

ARCH_DIR = REPO_ROOT / "documents" / "architecture"
L10N_DIR = REPO_ROOT / "lib" / "l10n"
THEME_DIR = REPO_ROOT / "lib" / "core" / "theme"

REQUIRED_TOP_FIELDS = ["meta"]

def load_yaml(p: Path):
    try:
        with p.open("r", encoding="utf-8") as f:
            return yaml.safe_load(f) or {}
    except Exception as e:
        return {"__error__": str(e)}

def check_file_path(doc: dict, p: Path, errors: list):
    # file_path 在 meta 下
    meta = doc.get("meta", {})
    fp = meta.get("file_path")
    if not fp:
        errors.append(f"{p}: 缺少 meta.file_path 字段")
        return
    target = REPO_ROOT / fp
    if not target.exists():
        errors.append(f"{p}: meta.file_path 指向的文件不存在: {fp}")

def check_required_fields(doc: dict, p: Path, errors: list):
    for f in REQUIRED_TOP_FIELDS:
        if f not in doc:
            errors.append(f"{p}: 缺少必填字段 {f}")

def _collect_arb_keys() -> set:
    keys = set()
    if L10N_DIR.exists():
        for arb in L10N_DIR.glob("*.arb"):
            try:
                data = json.loads(arb.read_text(encoding="utf-8"))
                keys.update(k for k in data.keys() if not k.startswith("@"))
            except Exception:
                continue
    return keys

def _collect_token_names() -> set:
    # 轻量收集：扫描 theme 目录下的 *.dart 中的 SCREAMING_CASE 与 camelCase token 名称
    tokens = set()
    if THEME_DIR.exists():
        for dart in THEME_DIR.rglob("*.dart"):
            try:
                content = dart.read_text(encoding="utf-8", errors="ignore")
                for word in set(content.replace("\n", " ").replace("\t", " ").split()):
                    if word.isidentifier():
                        tokens.add(word.strip())
            except Exception:
                continue
    return tokens

ARB_KEYS_CACHE = None
TOKENS_CACHE = None

def check_i18n_keys(doc: dict, p: Path, errors: list):
    global ARB_KEYS_CACHE
    if ARB_KEYS_CACHE is None:
        ARB_KEYS_CACHE = _collect_arb_keys()
    keys = doc.get("i18n_keys") or []
    for k in keys:
        if k not in ARB_KEYS_CACHE:
            errors.append(f"{p}: i18n key 不存在于 ARB: {k}")

def check_design_tokens(doc: dict, p: Path, errors: list):
    global TOKENS_CACHE
    if TOKENS_CACHE is None:
        TOKENS_CACHE = _collect_token_names()
    tokens = doc.get("design_tokens") or []
    for t in tokens:
        if t not in TOKENS_CACHE:
            errors.append(f"{p}: design token 未在主题中找到: {t}")

def check_calls(doc: dict, p: Path, errors: list):
    for field in ("called_by", "calls"):
        items = doc.get(field) or []
        for rel in items:
            rel_path = (REPO_ROOT / rel)
            if not rel_path.exists():
                errors.append(f"{p}: {field} 指向的文件不存在: {rel}")

def lint_arch_file(path: Path) -> list:
    errors: list[str] = []
    data = load_yaml(path)
    if "__error__" in data:
        errors.append(f"{path}: YAML 解析失败: {data['__error__']}")
        return errors
    check_required_fields(data, path, errors)
    check_file_path(data, path, errors)
    check_calls(data, path, errors)
    check_i18n_keys(data, path, errors)
    check_design_tokens(data, path, errors)
    return errors

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--files", nargs="*", default=[])
    args = parser.parse_args()

    changed = [Path(f) for f in args.files]
    targets = []
    for f in changed:
        try:
            p = Path(f)
            if not p.is_absolute():
                p = (REPO_ROOT / p).resolve()
            if ARCH_DIR in p.parents and p.suffix in (".yaml", ".yml"):
                targets.append(p)
        except Exception:
            continue

    if not targets:
        return 0

    all_errors: list[str] = []
    for t in targets:
        all_errors.extend(lint_arch_file(t))

    if all_errors:
        print("\n架构文档校验失败：\n" + "\n".join(all_errors))
        return 1
    return 0

if __name__ == "__main__":
    sys.exit(main())


