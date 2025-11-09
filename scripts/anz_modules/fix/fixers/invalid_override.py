"""Fix invalid_override errors by updating parameter types from int to String for ID parameters."""

from __future__ import annotations

import re
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:  # pragma: no cover
    from ..issues import Diagnostic  # pylint: disable=cyclic-import

# Pattern to match parameter declarations with int type and ID-related names
ID_PARAM_PATTERN = re.compile(
    r"\b(required\s+)?int(\?)?\s+((task|session|parent|project|milestone|focus)[Ii]d|id)\b"
)

# Pattern to match function signatures with int return types that should be String
ID_RETURN_PATTERN = re.compile(
    r"\b(int|Future<int>|Stream<int>)\s+(\w+)\s*\([^)]*\)"
)


def _should_fix(path: Path) -> bool:
    """Check if file should be fixed (only test files)."""
    try:
        rel = path.relative_to(Path.cwd())
    except ValueError:
        return False
    parts = rel.parts
    return parts and parts[0] in {"test", "integration_test"}


def _fix_id_parameter_type(match: re.Match[str]) -> str:
    """Replace int parameter type with String for ID parameters."""
    required = match.group(1) or ""
    nullable = match.group(2) or ""
    param_name = match.group(3)
    
    # Convert int to String
    suffix = "?" if nullable else ""
    prefix = f"{required}" if required else ""
    
    if prefix:
        return f"{prefix}String{suffix} {param_name}"
    return f"String{suffix} {param_name}"


def apply_invalid_override_fix(path: Path, diagnostics: list["Diagnostic"]) -> bool:
    """
    Fix invalid_override errors by updating parameter types from int to String.
    
    This fixer handles cases where mock/stub classes override methods with int ID parameters
    but the actual interface uses String ID parameters.
    """
    if not _should_fix(path):
        return False
    
    original = path.read_text(encoding="utf-8")
    lines = original.splitlines()
    changed = False
    
    # Process each diagnostic
    for diag in diagnostics:
        if diag.code != "invalid_override":
            continue
        
        line_idx = diag.line - 1
        if line_idx < 0 or line_idx >= len(lines):
            continue
        
        line = lines[line_idx]
        
        # Check if this line contains an ID parameter with int type
        # Look for patterns like "required int taskId" or "int sessionId"
        if ID_PARAM_PATTERN.search(line):
            # Replace int with String for ID parameters
            new_line = ID_PARAM_PATTERN.sub(_fix_id_parameter_type, line)
            if new_line != line:
                lines[line_idx] = new_line
                changed = True
                continue
        
        # Also check the message to understand what needs to be fixed
        # The message typically says something like:
        # "'_StubTaskService.markCompleted' ('Future<void> Function({bool autoCompleteParent, required int taskId})') 
        #  isn't a valid override of 'TaskService.markCompleted' ('Future<void> Function({bool autoCompleteParent, required String taskId})')"
        
        # If the line contains a function signature, we might need to look at multiple lines
        # For now, we focus on the specific line mentioned in the diagnostic
    
    if changed:
        path.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")
        return True
    
    return False
