#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re
import sys
import threading
import subprocess
from pathlib import Path
from typing import List, Tuple, Dict
from concurrent.futures import ThreadPoolExecutor, as_completed

_HERE = Path(__file__).resolve()
# 优先通过 pubspec.yaml 向上定位项目根；否则退回到固定层级（parents[3]）
_CANDIDATES = list(_HERE.parents)
_FALLBACK = _HERE.parents[3] if len(_HERE.parents) >= 4 else _HERE.parent.parent
ROOT = next((p for p in _CANDIDATES if (p / 'pubspec.yaml').exists()), _FALLBACK)
TEST_DIR = ROOT / "test"

WARNING_RE = re.compile(r"\bwarning\b", re.IGNORECASE)
ERROR_RE = re.compile(r"\berror\b|^Error:", re.IGNORECASE | re.MULTILINE)
FAIL_HINT_RE = re.compile(r"(Some tests failed| -\d+:|\bFAIL\b)", re.IGNORECASE)


def _find_test_files() -> List[Path]:
    if not TEST_DIR.exists():
        return []
    return sorted(p for p in TEST_DIR.rglob("*.dart") if p.name.endswith("_test.dart"))


def _run_one(rel_path: Path, timeout_sec: int = 600) -> Tuple[str, bool, Dict[str, List[str]]]:
    """
    返回: (相对路径字符串, 是否通过, 摘要dict: warnings/errors/fails)
    """
    cmd = ["flutter", "test", str(rel_path), "-r", "expanded"]
    try:
        proc = subprocess.run(
            cmd,
            cwd=str(ROOT),
            text=True,
            capture_output=True,
            timeout=timeout_sec,
        )
        out = (proc.stdout or "") + "\n" + (proc.stderr or "")
    except subprocess.TimeoutExpired as e:
        out = (e.stdout or "") + "\n" + (e.stderr or "")
        out += f"\n[ANZ] Timeout after {timeout_sec}s for {rel_path}\n"

    warnings = [ln for ln in out.splitlines() if WARNING_RE.search(ln)]
    errors = [ln for ln in out.splitlines() if ERROR_RE.search(ln)]
    fails: List[str] = []
    # 测试通过：要么所有测试都通过，要么所有测试都被跳过
    ok = (("All tests passed" in out) or ("All tests skipped" in out)) and ("Some tests failed" not in out)

    if (not ok) or FAIL_HINT_RE.search(out):
        for ln in out.splitlines():
            if "══" in ln or "Expected" in ln or "Test failed" in ln or "Failure" in ln:
                fails.append(ln)

    try:
        ok = ok and (proc.returncode == 0)  # type: ignore[name-defined]
    except Exception:
        ok = False

    summary = {
        "warnings": warnings[:200],
        "errors": errors[:200],
        "fails": fails[:80],
    }
    return (str(rel_path), ok, summary)


def _dedup(lines: List[str], limit: int = 200) -> List[str]:
    seen = set()
    out: List[str] = []
    for ln in lines:
        k = ln.strip()
        if not k:
            continue
        if k in seen:
            continue
        seen.add(k)
        out.append(ln)
        if len(out) >= limit:
            break
    return out


def main() -> int:
    files = _find_test_files()
    if not files:
        print("No tests found under test/")
        return 0

    total = len(files)
    default_workers = max(2, min(6, (os.cpu_count() or 4)))
    max_workers = int(os.getenv("ANZ_TEST_WORKERS", str(default_workers)))

    print(f"[ANZ] Found {total} test files under test/. Running in parallel with {max_workers} workers...")

    all_warnings: List[str] = []
    all_errors: List[str] = []
    failed_files: List[str] = []
    fail_snippets: Dict[str, List[str]] = {}

    lock = threading.Lock()
    done = 0

    rel_files = [f.relative_to(ROOT) for f in files]

    with ThreadPoolExecutor(max_workers=max_workers) as ex:
        futures = [ex.submit(_run_one, rel) for rel in rel_files]
        for fut in as_completed(futures):
            rel, ok, summary = fut.result()
            with lock:
                done += 1
                print(f"{done}/{total} done")

                all_warnings.extend(summary["warnings"])
                all_errors.extend(summary["errors"])
                if not ok or summary["fails"]:
                    failed_files.append(rel)
                    fail_snippets[rel] = summary["fails"]

    print("\n===== Test Summary (Parallel) =====")
    print(f"Total files: {total}")
    print(f"Failed files: {len(failed_files)}")
    if failed_files:
        for rel in sorted(failed_files):
            print(f"  • {rel}")

    dedup_errors = _dedup(all_errors, limit=200)
    dedup_warnings = _dedup(all_warnings, limit=200)

    print("\n- Errors (dedup, up to 200):")
    if dedup_errors:
        for ln in dedup_errors:
            print(f"  {ln}")
    else:
        print("  (none)")

    print("\n- Warnings (dedup, up to 200):")
    if dedup_warnings:
        for ln in dedup_warnings:
            print(f"  {ln}")
    else:
        print("  (none)")

    if fail_snippets:
        print("\n- Failure snippets:")
        for rel, lines in fail_snippets.items():
            if not lines:
                continue
            print(f"  [{rel}]")
            for ln in lines[:50]:
                print(f"    {ln}")

    print("===== End Summary =====\n")
    return 1 if failed_files else 0


if __name__ == "__main__":
    sys.exit(main())


