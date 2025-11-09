#!/usr/bin/env python3
"""
统计 dart analyze 结果，输出错误分类和统计信息。

用法:
    python3 analyze_stats.py <analyze_json_file>
    python3 analyze_stats.py <analyze_json_file> --group-by code
    python3 analyze_stats.py <analyze_json_file> --group-by file
"""

import argparse
import json
import sys
from collections import defaultdict
from pathlib import Path
from typing import Dict, List


def load_analyze_results(file_path: Path) -> List[dict]:
    """加载 analyze JSON 结果文件"""
    try:
        content = file_path.read_text(encoding="utf-8")
        data = json.loads(content)
    except (json.JSONDecodeError, OSError) as exc:
        print(f"[analyze:stats] Error loading file: {exc}", file=sys.stderr)
        sys.exit(1)

    diagnostics: List[dict] = []
    if isinstance(data, list):
        for entry in data:
            if entry.get("type") != "lint":
                continue
            diagnostics.extend(entry.get("diagnostics", []))
    elif isinstance(data, dict):
        diagnostics.extend(data.get("diagnostics", []))
    else:
        print(f"[analyze:stats] Unexpected JSON structure", file=sys.stderr)
        sys.exit(1)

    return diagnostics


def get_file_path(diag: dict) -> str:
    """从诊断信息中提取文件路径"""
    location = diag.get("location", {})
    file_path = location.get("file", "")
    if file_path:
        try:
            # 转换为相对路径
            return str(Path(file_path).relative_to(Path.cwd()))
        except (ValueError, OSError):
            return file_path
    return ""


def group_by_code(diagnostics: List[dict]) -> Dict[str, List[dict]]:
    """按错误代码分组"""
    groups: Dict[str, List[dict]] = defaultdict(list)
    for diag in diagnostics:
        code = diag.get("code", "unknown")
        groups[code].append(diag)
    return groups


def group_by_file(diagnostics: List[dict]) -> Dict[str, List[dict]]:
    """按文件路径分组"""
    groups: Dict[str, List[dict]] = defaultdict(list)
    for diag in diagnostics:
        file_path = get_file_path(diag)
        if file_path:
            groups[file_path].append(diag)
    return groups


def group_by_severity(diagnostics: List[dict]) -> Dict[str, List[dict]]:
    """按严重程度分组"""
    groups: Dict[str, List[dict]] = defaultdict(list)
    for diag in diagnostics:
        severity = diag.get("severity", "UNKNOWN")
        groups[severity].append(diag)
    return groups


def print_summary(diagnostics: List[dict]) -> None:
    """打印总体统计"""
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
    print()


def print_code_stats(diagnostics: List[dict]) -> None:
    """打印按错误代码分组的统计"""
    by_code = group_by_code(diagnostics)
    by_severity = group_by_severity(diagnostics)

    # 按出现次数排序
    sorted_codes = sorted(
        by_code.items(),
        key=lambda x: len(x[1]),
        reverse=True
    )

    print(f"[analyze:stats] Top error codes:")
    for idx, (code, diags) in enumerate(sorted_codes[:20], 1):
        # 统计每个代码的文件分布
        files = set(get_file_path(d) for d in diags if get_file_path(d))
        file_dirs = set(Path(f).parts[0] for f in files if f)
        
        # 统计严重程度
        error_count = sum(1 for d in diags if d.get("severity") == "ERROR")
        warning_count = sum(1 for d in diags if d.get("severity") == "WARNING")
        info_count = sum(1 for d in diags if d.get("severity") == "INFO")
        
        severity_str = ""
        if error_count > 0:
            severity_str += f"E:{error_count} "
        if warning_count > 0:
            severity_str += f"W:{warning_count} "
        if info_count > 0:
            severity_str += f"I:{info_count}"
        
        dirs_str = ", ".join(sorted(file_dirs)[:3])
        if len(file_dirs) > 3:
            dirs_str += ", ..."
        
        print(f"  {idx}. {code}: {len(diags)} ({severity_str}) - {dirs_str}")
    print()


def print_file_stats(diagnostics: List[dict]) -> None:
    """打印按文件分组的统计"""
    by_file = group_by_file(diagnostics)
    
    # 按错误数量排序
    sorted_files = sorted(
        by_file.items(),
        key=lambda x: len(x[1]),
        reverse=True
    )

    print(f"[analyze:stats] Top files with issues:")
    for idx, (file_path, diags) in enumerate(sorted_files[:20], 1):
        codes = set(d.get("code", "unknown") for d in diags)
        codes_str = ", ".join(sorted(codes)[:3])
        if len(codes) > 3:
            codes_str += ", ..."
        print(f"  {idx}. {file_path}: {len(diags)} issues ({codes_str})")
    print()


def main() -> int:
    parser = argparse.ArgumentParser(
        description="统计 dart analyze 结果"
    )
    parser.add_argument(
        "json_file",
        type=Path,
        help="analyze JSON 结果文件路径"
    )
    parser.add_argument(
        "--group-by",
        choices=["code", "file", "severity"],
        default="code",
        help="分组方式（默认: code）"
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="显示所有统计信息"
    )

    args = parser.parse_args()

    if not args.json_file.exists():
        print(f"[analyze:stats] File not found: {args.json_file}", file=sys.stderr)
        return 1

    diagnostics = load_analyze_results(args.json_file)
    
    if not diagnostics:
        print("[analyze:stats] No diagnostics found in file.")
        return 0

    print_summary(diagnostics)

    if args.all or args.group_by == "code":
        print_code_stats(diagnostics)
    
    if args.all or args.group_by == "file":
        print_file_stats(diagnostics)

    if args.all or args.group_by == "severity":
        by_severity = group_by_severity(diagnostics)
        print(f"[analyze:stats] By severity:")
        for severity in ["ERROR", "WARNING", "INFO"]:
            if severity in by_severity:
                print(f"  {severity}: {len(by_severity[severity])}")
        print()

    return 0


if __name__ == "__main__":
    sys.exit(main())
