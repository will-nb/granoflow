"""Fix override_on_non_overriding_member errors by removing invalid @override annotations."""

from __future__ import annotations

import re
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:  # pragma: no cover
    from ..issues import Diagnostic  # pylint: disable=cyclic-import


def _should_fix(path: Path) -> bool:
    """Check if file should be fixed (only test files)."""
    try:
        rel = path.relative_to(Path.cwd())
    except ValueError:
        return False
    parts = rel.parts
    return parts and parts[0] in {"test", "integration_test"}


def apply_override_on_non_overriding_member_fix(
    path: Path, diagnostics: list["Diagnostic"]
) -> bool:
    """
    Fix override_on_non_overriding_member errors by removing invalid @override annotations.
    
    This fixer handles cases where @override annotations are present but the method
    doesn't actually override a parent class method (usually after method signature changes).
    """
    if not _should_fix(path):
        return False

    original = path.read_text(encoding="utf-8")
    lines = original.splitlines()
    changed = False

    # Process each diagnostic
    for diag in diagnostics:
        if diag.code != "override_on_non_overriding_member":
            continue

        line_idx = diag.line - 1
        if line_idx < 0 or line_idx >= len(lines):
            continue

        # Look backwards for @override annotation
        # Usually it's on the line before the method declaration
        for i in range(line_idx, max(-1, line_idx - 3), -1):
            if i < 0:
                break
            line = lines[i]
            if "@override" in line.lower():
                # Remove the @override line
                lines[i] = ""
                changed = True
                break

    if changed:
        # Remove empty lines and write back
        new_lines = [line for line in lines if line.strip() or not line]
        path.write_text("\n".join(new_lines) + ("\n" if new_lines else ""), encoding="utf-8")
        return True

    return False
