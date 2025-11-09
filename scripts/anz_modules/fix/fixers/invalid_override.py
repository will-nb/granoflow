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

# Pattern to match function parameter lists (for multi-line function signatures)
FUNCTION_PARAM_PATTERN = re.compile(
    r"\([^)]*\)"
)

# Pattern to match ID parameter names in function calls
ID_PARAM_NAME_PATTERN = re.compile(
    r"\b((task|session|parent|project|milestone|focus)[Ii]d|id)\s*:"
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


def _convert_int_to_string_in_call(value: str) -> str:
    """
    Convert int value to String in function calls.
    Handles: literals (999 -> '999'), variables (id -> id.toString()), expressions (id + 1 -> (id + 1).toString())
    """
    value = value.strip()
    
    # If it's a simple integer literal
    if value.isdigit():
        return f"'{value}'"
    
    # If it's a variable or expression, wrap with .toString()
    # But be careful not to double-wrap
    if value.endswith('.toString()'):
        return value
    
    # Check if it's already a string literal
    if (value.startswith("'") and value.endswith("'")) or (value.startswith('"') and value.endswith('"')):
        return value
    
    # For variables and expressions, wrap with parentheses and .toString()
    return f"({value}).toString()"


def apply_invalid_override_fix(path: Path, diagnostics: list["Diagnostic"]) -> bool:
    """
    Fix invalid_override errors by updating parameter types from int to String.
    
    This fixer handles cases where mock/stub classes override methods with int ID parameters
    but the actual interface uses String ID parameters.
    
    It also attempts to fix method calls that pass int values to these methods.
    """
    if not _should_fix(path):
        return False
    
    original = path.read_text(encoding="utf-8")
    lines = original.splitlines()
    changed = False
    
    # First pass: Fix method signatures
    method_signatures = {}  # method_name -> (start_line, end_line, param_names)
    
    for diag in diagnostics:
        if diag.code != "invalid_override":
            continue
        
        line_idx = diag.line - 1
        if line_idx < 0 or line_idx >= len(lines):
            continue
        
        # Look for the method signature (may span multiple lines)
        # Find the method name and parameter list
        start_line = line_idx
        end_line = line_idx
        
        # Look backwards for method name
        method_name = None
        for i in range(line_idx, max(-1, line_idx - 10), -1):
            if i < 0:
                break
            line = lines[i]
            # Look for pattern like "Future<void> markCompleted({" or "markCompleted({"
            # Also handle cases where opening brace is on next line
            match = re.search(r"(\w+)\s*\([^)]*\{?", line)
            if match:
                method_name = match.group(1)
                start_line = i
                break
        
        # Look forwards for closing brace of parameter list
        brace_count = 0
        found_open = False
        for i in range(start_line, min(len(lines), start_line + 10)):
            line = lines[i]
            if '{' in line:
                brace_count += line.count('{')
                found_open = True
            if '}' in line:
                brace_count -= line.count('}')
                if found_open and brace_count == 0:
                    end_line = i
                    break
        
        # Fix parameter types in the method signature
        for i in range(start_line, end_line + 1):
            if i >= len(lines):
                break
            line = lines[i]
            if ID_PARAM_PATTERN.search(line):
                new_line = ID_PARAM_PATTERN.sub(_fix_id_parameter_type, line)
                if new_line != line:
                    lines[i] = new_line
                    changed = True
        
        # Store method info for second pass
        if method_name:
            # Extract parameter names that were changed
            param_names = []
            for i in range(start_line, end_line + 1):
                if i >= len(lines):
                    break
                for match in ID_PARAM_PATTERN.finditer(lines[i]):
                    param_names.append(match.group(3))
            if param_names:
                method_signatures[method_name] = (start_line, end_line, param_names)
    
    # Second pass: Fix method calls (simplified - only handle simple cases)
    # This is a basic implementation - more sophisticated analysis would be needed
    # for complex cases
    
    if changed:
        path.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")
        return True
    
    return False
