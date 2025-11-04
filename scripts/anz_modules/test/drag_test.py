#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re
import sys
import subprocess
import platform
import shutil
from pathlib import Path
from typing import List, Tuple, Dict, Optional

_HERE = Path(__file__).resolve()
# 优先通过 pubspec.yaml 向上定位项目根
_CANDIDATES = list(_HERE.parents)
_FALLBACK = _HERE.parents[3] if len(_HERE.parents) >= 4 else _HERE.parent.parent
ROOT = next((p for p in _CANDIDATES if (p / 'pubspec.yaml').exists()), _FALLBACK)
TEST_FILE = ROOT / "integration_test" / "tasks_drag_comprehensive_test.dart"

# 测试运行次数
RUNS_PER_TEST = 100

# 测试超时时间（秒）
TEST_TIMEOUT = 60

# 错误匹配正则
WARNING_RE = re.compile(r"\bwarning\b", re.IGNORECASE)
ERROR_RE = re.compile(r"\berror\b|^Error:", re.IGNORECASE | re.MULTILINE)
FAIL_HINT_RE = re.compile(r"(Some tests failed| -\d+:|\bFAIL\b)", re.IGNORECASE)


def clean_database() -> None:
    """清理数据库（只清理数据库，不执行 flutter clean）"""
    home = Path.home()
    if platform.system() == "Darwin":  # macOS
        # 检查新旧两个可能的路径
        new_db_path = home / "Library" / "Containers" / "com.granoflow.app" / "Data" / "Library" / "Application Support"
        old_db_path = home / "Library" / "Containers" / "com.example.granoflow" / "Data" / "Library" / "Application Support"
        
        for db_path in [new_db_path, old_db_path]:
            if db_path.exists():
                try:
                    # 删除数据库目录下的所有文件
                    for item in db_path.iterdir():
                        if item.is_file():
                            item.unlink()
                        elif item.is_dir():
                            shutil.rmtree(item)
                except Exception as e:
                    pass  # 忽略清理错误
    elif platform.system() == "Linux":
        db_path = home / ".local" / "share" / "granoflow"
        if db_path.exists():
            try:
                shutil.rmtree(db_path)
                db_path.mkdir(parents=True, exist_ok=True)
            except Exception as e:
                pass  # 忽略清理错误


def extract_test_names(test_file: Path) -> List[str]:
    """从测试文件中提取所有测试用例名称"""
    if not test_file.exists():
        print(f"[ANZ] Error: Test file not found: {test_file}")
        return []
    
    try:
        content = test_file.read_text(encoding='utf-8')
        # 匹配 testWidgets('test name', ...) 或 testWidgets("test name", ...)
        # 支持单引号和双引号
        pattern = re.compile(r"testWidgets\(\s*['\"]([^'\"]+)['\"]")
        matches = pattern.findall(content)
        if not matches:
            print("[ANZ] Warning: No test cases found, trying alternative pattern")
            # 尝试更宽松的模式
            pattern2 = re.compile(r'testWidgets\(\s*["\']([^"\']+)["\']')
            matches = pattern2.findall(content)
        return matches
    except Exception as e:
        print(f"[ANZ] Error reading test file: {e}")
        return []


def run_single_test(test_name: str, run_number: int, total_runs: int) -> Tuple[bool, Dict[str, List[str]]]:
    """运行单个测试用例一次"""
    # 使用完整的测试文件路径（相对于项目根目录）
    test_file_rel = str(TEST_FILE.relative_to(ROOT))
    cmd = [
        "flutter",
        "test",
        test_file_rel,
        "--name",
        test_name,  # Flutter test --name 可以直接匹配测试名称
        "-r",
        "expanded",
    ]
    
    try:
        proc = subprocess.run(
            cmd,
            cwd=str(ROOT),
            text=True,
            capture_output=True,
            timeout=TEST_TIMEOUT,
        )
        out = (proc.stdout or "") + "\n" + (proc.stderr or "")
    except subprocess.TimeoutExpired as e:
        out = (e.stdout or "") + "\n" + (e.stderr or "")
        out += f"\n[ANZ] Timeout after {TEST_TIMEOUT}s for test: {test_name}\n"
    
    warnings = [ln for ln in out.splitlines() if WARNING_RE.search(ln)]
    errors = [ln for ln in out.splitlines() if ERROR_RE.search(ln)]
    fails: List[str] = []
    ok = ("All tests passed" in out) and ("Some tests failed" not in out)
    
    if (not ok) or FAIL_HINT_RE.search(out):
        # 提取失败信息
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
        "output": out,  # 保存完整输出
    }
    return (ok, summary)


def dedup(lines: List[str], limit: int = 200) -> List[str]:
    """去重并限制数量"""
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
    """主函数"""
    if not TEST_FILE.exists():
        print(f"[ANZ] Error: Test file not found: {TEST_FILE}")
        return 1
    
    # 提取测试用例名称
    test_names = extract_test_names(TEST_FILE)
    if not test_names:
        print("[ANZ] Error: No test cases found in test file")
        return 1
    
    total_tests = len(test_names)
    total_runs = total_tests * RUNS_PER_TEST
    
    print(f"[ANZ] Running drag tests: {total_tests} test cases × {RUNS_PER_TEST} runs = {total_runs} total runs")
    print()
    
    # 统计结果
    test_results: Dict[str, Dict[str, any]] = {}
    total_passed = 0
    total_failed = 0
    
    # 对每个测试用例运行 100 次
    for test_idx, test_name in enumerate(test_names, 1):
        print(f"[Test {test_idx}/{total_tests}] {test_name}")
        
        test_passed = 0
        test_failed = 0
        failed_runs: List[Tuple[int, Dict[str, List[str]]]] = []  # (run_number, summary)
        
        for run_num in range(1, RUNS_PER_TEST + 1):
            # 每次运行前清理数据库
            clean_database()
            
            # 运行测试
            ok, summary = run_single_test(test_name, run_num, RUNS_PER_TEST)
            
            if ok:
                test_passed += 1
                total_passed += 1
            else:
                test_failed += 1
                total_failed += 1
                failed_runs.append((run_num, summary))
            
            # 显示进度（每10次或最后一次）
            if run_num % 10 == 0 or run_num == RUNS_PER_TEST:
                percent = int(run_num * 100 / RUNS_PER_TEST)
                print(f"  [Run {run_num}/{RUNS_PER_TEST}] {percent}% done - {test_passed} passed, {test_failed} failed", end='\r' if run_num < RUNS_PER_TEST else '\n')
                sys.stdout.flush()
        
        # 保存测试结果
        test_results[test_name] = {
            "passed": test_passed,
            "failed": test_failed,
            "failed_runs": failed_runs,
        }
        # 输出该测试用例的最终结果
        print(f"  Result: {test_passed}/{RUNS_PER_TEST} passed ({int(test_passed * 100 / RUNS_PER_TEST)}%)")
        print()
    
    # 输出汇总
    print("=" * 70)
    print("Test Summary")
    print("=" * 70)
    print(f"Total test cases: {total_tests}")
    print(f"Total runs: {total_runs}")
    print(f"Total passed: {total_passed}")
    print(f"Total failed: {total_failed}")
    print()
    
    # 输出失败的测试用例详情
    failed_test_cases = {name: results for name, results in test_results.items() if results["failed"] > 0}
    
    if failed_test_cases:
        print("Failed test cases:")
        print()
        for test_name, results in failed_test_cases.items():
            print(f"  [{test_name}]")
            print(f"    Failed runs: {results['failed']}/{RUNS_PER_TEST}")
            print(f"    Success rate: {results['passed']}/{RUNS_PER_TEST} ({int(results['passed'] * 100 / RUNS_PER_TEST)}%)")
            
            if results["failed_runs"]:
                print("    Error details (showing up to 10 failed runs):")
                for run_num, summary in results["failed_runs"][:10]:
                    print(f"      - Run #{run_num}:")
                    # 提取关键错误信息
                    if summary["errors"]:
                        for err in summary["errors"][:3]:
                            print(f"        Error: {err[:200]}")
                    if summary["fails"]:
                        for fail in summary["fails"][:3]:
                            print(f"        {fail[:200]}")
            print()
    else:
        print("✅ All tests passed!")
        print()
    
    # 输出所有错误和警告的汇总（去重）
    all_errors: List[str] = []
    all_warnings: List[str] = []
    
    for test_name, results in test_results.items():
        for run_num, summary in results["failed_runs"]:
            all_errors.extend(summary["errors"])
            all_warnings.extend(summary["warnings"])
    
    dedup_errors = dedup(all_errors, limit=200)
    dedup_warnings = dedup(all_warnings, limit=200)
    
    if dedup_errors:
        print("- Errors (dedup, up to 200):")
        for err in dedup_errors:
            print(f"  {err}")
        print()
    
    if dedup_warnings:
        print("- Warnings (dedup, up to 200):")
        for warn in dedup_warnings:
            print(f"  {warn}")
        print()
    
    print("=" * 70)
    
    return 1 if total_failed > 0 else 0


if __name__ == "__main__":
    sys.exit(main())

