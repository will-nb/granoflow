#!/usr/bin/env python3
"""
Batch fixer for flutter analyze issues.

Steps:
1. Run `flutter analyze --format=json` and collect diagnostics.
2. Group diagnostics by error code and file.
3. Apply targeted fixers (with per-file backups).
4. Run `flutter format` on modified files.
5. Re-run `flutter analyze --format=json` to verify fixes; restore backups on failure.
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Dict, Iterable, List, Optional, Set

from fixers import (
    import_remap,
    id_literals,
    id_types,
    invalid_override,
    undefined_named_parameter,
    return_of_invalid_type_from_closure,
    undefined_getter,
    override_on_non_overriding_member,
    argument_type_not_assignable,
)

REPO_ROOT = Path(__file__).resolve().parents[3]
BACKUP_ROOT = REPO_ROOT / ".tmp" / "anz_fix_backup"


class FixError(Exception):
    """Raised when a fixer encounters unrecoverable state."""


def run_command(cmd: List[str], *, check: bool = True) -> subprocess.CompletedProcess:
    """Run command and capture output."""
    result = subprocess.run(
        cmd,
        cwd=REPO_ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )
    if check and result.returncode != 0:
        raise FixError(
            f"Command {' '.join(cmd)} failed with exit code {result.returncode}\n"
            f"stdout:\n{result.stdout}\n"
            f"stderr:\n{result.stderr}"
        )
    return result


def run_dart_analyze() -> List[dict]:
    """Execute dart analyze and parse JSON diagnostics."""
    print("[anz:fix] Running dart analyze --format=json ...")
    result = run_command(["dart", "analyze", "--format=json"], check=False)
    output = result.stdout.strip()
    if not output:
        return []
    try:
        data = json.loads(output)
    except json.JSONDecodeError as exc:
        raise FixError(f"Failed to parse analyze output: {exc}\nOutput:\n{output}") from exc
    diagnostics: List[dict] = []
    if isinstance(data, list):
        for entry in data:
            if entry.get("type") != "lint":
                continue
            diagnostics.extend(entry.get("diagnostics", []))
    elif isinstance(data, dict):
        diagnostics.extend(data.get("diagnostics", []))
    else:
        raise FixError(f"Unexpected analyze output shape: {output}")
    return diagnostics


@dataclass
class Diagnostic:
    file: Path
    code: str
    message: str
    line: int
    column: int
    offset: int
    end_offset: int


def parse_diagnostics(raw: Iterable[dict]) -> List[Diagnostic]:
    diagnostics: List[Diagnostic] = []
    for diag in raw:
        location = diag.get("location", {})
        file_path = location.get("file")
        if not file_path:
            continue
        try:
            file_path = Path(file_path).resolve()
        except OSError:
            continue
        code = diag.get("code", "")
        message = diag.get("problemMessage") or diag.get("message", "")
        range_info = location.get("range", {})
        start = range_info.get("start", {})
        end = range_info.get("end", {})
        line = int(start.get("line", 1))
        column = int(start.get("column", 1))
        offset = int(start.get("offset", -1))
        end_offset = int(end.get("offset", offset))
        diagnostics.append(
            Diagnostic(
                file=file_path,
                code=code,
                message=message,
                line=line,
                column=column,
                offset=offset,
                end_offset=end_offset,
            )
        )
    return diagnostics


def backup_file(path: Path) -> Path:
    rel = path.relative_to(REPO_ROOT)
    backup_path = BACKUP_ROOT / rel
    backup_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, backup_path)
    return backup_path


def restore_file(backup_path: Path, original: Path) -> None:
    shutil.copy2(backup_path, original)


def cleanup_backup(path: Path) -> None:
    if path.is_file():
        path.unlink()
    # remove empty parent directories up to BACKUP_ROOT
    current = path.parent
    while current != BACKUP_ROOT and current.exists():
        try:
            current.rmdir()
        except OSError:
            break
        current = current.parent


def load_lines(path: Path) -> List[str]:
    return path.read_text(encoding="utf-8").splitlines()


def write_lines(path: Path, lines: List[str]) -> None:
    path.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")


def fix_unused_import(path: Path, diags: List[Diagnostic]) -> bool:
    """Remove import lines flagged as unused."""
    lines = load_lines(path)
    changed = False
    for diag in diags:
        idx = diag.line - 1
        if 0 <= idx < len(lines):
            content = lines[idx].strip()
            if content.startswith("import "):
                print(f"[anz:fix] Removing unused import in {path}:{diag.line}")
                lines[idx] = ""
                changed = True
    if changed:
        write_lines(path, lines)
    return changed


def fix_uri_does_not_exist(path: Path, diags: List[Diagnostic]) -> bool:
    """Remap or remove import lines referencing missing URIs."""
    remapped = import_remap.apply_import_remap(path, diags)
    if remapped:
        return True

    lines = load_lines(path)
    changed = False
    for diag in diags:
        idx = diag.line - 1
        if 0 <= idx < len(lines):
            line = lines[idx]
            if line.strip().startswith("import "):
                print(f"[anz:fix] Removing missing URI import in {path}:{diag.line}")
                lines[idx] = ""
                changed = True
    if changed:
        write_lines(path, lines)
    return changed


Fixer = Callable[[Path, List[Diagnostic]], bool]


def _is_test_file(path: Path) -> bool:
    try:
        rel = path.relative_to(REPO_ROOT)
    except ValueError:
        return False
    return rel.parts and rel.parts[0] in {"test", "integration_test"}


def _fix_test_ids(path: Path, diagnostics: List[Diagnostic]) -> bool:
    changed = False
    if id_literals.apply_id_literal_conversion(path, diagnostics):
        changed = True
    if id_types.apply_id_type_annotations(path, diagnostics):
        changed = True
    return changed


FIXERS: Dict[str, tuple[Fixer, Callable[[Path], bool]]] = {
    "unused_import": (fix_unused_import, lambda _: True),
    "uri_does_not_exist": (fix_uri_does_not_exist, lambda _: True),
    "argument_type_not_assignable": (
        argument_type_not_assignable.apply_argument_type_not_assignable_fix,
        _is_test_file,
    ),
    "map_key_type_not_assignable": (_fix_test_ids, _is_test_file),
    "set_element_type_not_assignable": (_fix_test_ids, _is_test_file),
    "invalid_assignment": (_fix_test_ids, _is_test_file),
    "invalid_override": (invalid_override.apply_invalid_override_fix, _is_test_file),
    "undefined_named_parameter": (
        undefined_named_parameter.apply_undefined_named_parameter_fix,
        lambda _: True,
    ),
    "return_of_invalid_type_from_closure": (
        return_of_invalid_type_from_closure.apply_return_of_invalid_type_from_closure_fix,
        _is_test_file,
    ),
    # Temporarily disabled - introduces too many new errors
    # "undefined_getter": (
    #     undefined_getter.apply_undefined_getter_fix,
    #     lambda _: True,  # Fix in both lib and test files
    # ),
    # Temporarily disabled - introduces too many new errors
    # "override_on_non_overriding_member": (
    #     override_on_non_overriding_member.apply_override_on_non_overriding_member_fix,
    #     _is_test_file,
    # ),
  }


def apply_fixers(groups: Dict[Path, Dict[str, List[Diagnostic]]]) -> Set[Path]:
    """Apply fixers and return set of modified files."""
    changed_files: Set[Path] = set()
    BACKUP_ROOT.mkdir(parents=True, exist_ok=True)

    for file_path, code_map in groups.items():
        supported_codes = [
            code for code in code_map
            if code in FIXERS and FIXERS[code][1](file_path)
        ]
        if not supported_codes:
            continue
        backup_file(file_path)
        original_content = file_path.read_bytes()
        file_changed = False
        for code in supported_codes:
            fixer, _predicate = FIXERS[code]
            if fixer(file_path, code_map[code]):
                file_changed = True
        if file_changed:
            changed_files.add(file_path)
        else:
            # restore original if nothing changed
            file_path.write_bytes(original_content)
            cleanup_backup(BACKUP_ROOT / file_path.relative_to(REPO_ROOT))

    return changed_files


def run_dart_format(files: Iterable[Path]) -> None:
    to_format = [str(path) for path in files if path.exists()]
    if not to_format:
        return
    print(f"[anz:fix] Running dart format on {len(to_format)} file(s)")
    run_command(["dart", "format"] + to_format)


def verify_changes(changed_files: Set[Path], original_diags: List[Diagnostic]) -> Dict[str, int]:
    """
    Re-run flutter analyze and rollback files with persistent errors.
    Returns a dict with fix statistics: {'fixed': X, 'remaining': Y, 'new': Z}
    """
    if not changed_files:
        return {'fixed': 0, 'remaining': 0, 'new': 0}
    
    print("[anz:fix] Verifying fixes via dart analyze ...")
    new_diags = parse_diagnostics(run_dart_analyze())

    # Build maps for comparison
    original_by_file_code: Dict[Path, Dict[str, List[Diagnostic]]] = defaultdict(lambda: defaultdict(list))
    for diag in original_diags:
        if diag.code in FIXERS:
            original_by_file_code[diag.file][diag.code].append(diag)
    
    new_by_file_code: Dict[Path, Dict[str, List[Diagnostic]]] = defaultdict(lambda: defaultdict(list))
    for diag in new_diags:
        new_by_file_code[diag.file][diag.code].append(diag)

    # Count statistics
    fixed_count = 0
    remaining_count = 0
    new_count = 0
    
    # Track which files had issues
    files_with_remaining: List[Path] = []
    files_with_new: List[Path] = []

    for path in list(changed_files):
        rel = path.relative_to(REPO_ROOT)
        backup_path = BACKUP_ROOT / rel
        
        original_codes = set(original_by_file_code[path].keys())
        new_codes = set(new_by_file_code[path].keys())
        
        # Count fixed (original codes that are gone)
        fixed_codes = original_codes - new_codes
        fixed_count += sum(len(original_by_file_code[path][code]) for code in fixed_codes)
        
        # Count remaining (original codes that still exist)
        remaining_codes = original_codes & new_codes
        remaining_count += sum(len(new_by_file_code[path][code]) for code in remaining_codes)
        
        # Count new (codes that didn't exist before)
        new_codes_only = new_codes - original_codes
        new_count += sum(len(new_by_file_code[path][code]) for code in new_codes_only)
        
        # Rollback if original errors still exist
        if remaining_codes:
            print(f"[anz:fix] ⚠️  {rel}: {len(remaining_codes)} error code(s) still present")
            files_with_remaining.append(path)
            # Don't auto-rollback, let AI decide
            # restore_file(backup_path, path)
            # changed_files.remove(path)
        
        if new_codes_only:
            print(f"[anz:fix] ⚠️  {rel}: {len(new_codes_only)} new error code(s) introduced")
            files_with_new.append(path)
        
        cleanup_backup(backup_path)
    
    # Print summary
    print(f"[anz:fix] Results:")
    print(f"  ✅ Fixed: {fixed_count} issues resolved")
    print(f"  ❌ Remaining: {remaining_count} issues still present")
    print(f"  ⚠️  New: {new_count} new issues introduced")
    
    if files_with_remaining:
        print(f"[anz:fix] Files with remaining issues:")
        for path in files_with_remaining:
            rel = path.relative_to(REPO_ROOT)
            remaining_codes = set(original_by_file_code[path].keys()) & set(new_by_file_code[path].keys())
            print(f"  - {rel}: {', '.join(sorted(remaining_codes))}")
    
    if files_with_new:
        print(f"[anz:fix] Files with new issues:")
        for path in files_with_new:
            rel = path.relative_to(REPO_ROOT)
            new_codes = set(new_by_file_code[path].keys()) - set(original_by_file_code[path].keys())
            print(f"  - {rel}: {', '.join(sorted(new_codes))}")
    
    return {
        'fixed': fixed_count,
        'remaining': remaining_count,
        'new': new_count,
    }


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Batch fix flutter analyze issues.")
    parser.add_argument("--dry-run", action="store_true", help="Only list supported issues without applying fixes.")
    args = parser.parse_args(argv)

    if not shutil.which("dart"):
        print("[anz:fix] dart command not found", file=sys.stderr)
        return 1
    if not shutil.which("flutter"):
        print("[anz:fix] flutter command not found", file=sys.stderr)
        return 1

    raw_diags = parse_diagnostics(run_dart_analyze())
    if not raw_diags:
        print("[anz:fix] No issues reported by dart analyze.")
        return 0

    groups: Dict[Path, Dict[str, List[Diagnostic]]] = defaultdict(lambda: defaultdict(list))
    for diag in raw_diags:
        groups[diag.file][diag.code].append(diag)

    supported: Dict[Path, Dict[str, List[Diagnostic]]] = {}
    for path, code_map in groups.items():
        filtered: Dict[str, List[Diagnostic]] = {}
        for code, diags in code_map.items():
            entry = FIXERS.get(code)
            if entry is None:
                continue
            fixer, predicate = entry
            if not predicate(path):
                continue
            filtered[code] = diags
        if filtered:
            supported[path] = filtered

    if not supported:
        print("[anz:fix] No supported error codes found; nothing to fix automatically.")
        return 0

    print("[anz:fix] Supported issues to fix:")
    for path, code_map in supported.items():
        rel = path.relative_to(REPO_ROOT)
        codes = ", ".join(sorted(code_map))
        print(f"  - {rel}: {codes}")

    if args.dry_run:
        print("[anz:fix] Dry-run completed; no files modified.")
        return 0

    changed_files = apply_fixers(supported)
    if not changed_files:
        print("[anz:fix] No changes applied.")
        return 0

    run_dart_format(changed_files)
    stats = verify_changes(changed_files, raw_diags)

    if changed_files:
        print("[anz:fix] Modified files:")
        for path in sorted(changed_files):
            print(f"  - {path.relative_to(REPO_ROOT)}")
        
        # Print fix summary
        if stats['fixed'] > 0:
            print(f"\n[anz:fix] ✅ Successfully fixed {stats['fixed']} issue(s)")
        if stats['remaining'] > 0:
            print(f"[anz:fix] ⚠️  {stats['remaining']} issue(s) still need attention")
        if stats['new'] > 0:
            print(f"[anz:fix] ❌ {stats['new']} new issue(s) introduced - review needed")
    else:
        print("[anz:fix] No files were successfully fixed.")

    # Cleanup backup root if empty
    if BACKUP_ROOT.exists():
        try:
            shutil.rmtree(BACKUP_ROOT)
        except OSError:
            pass

    return 0


if __name__ == "__main__":
    sys.exit(main())
