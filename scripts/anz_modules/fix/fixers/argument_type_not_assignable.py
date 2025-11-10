"""Fix argument_type_not_assignable errors by converting int to String for ID-related parameters.

This fixer uses offset-based replacement similar to id_literals.py for precision.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:  # pragma: no cover
    from ..issues import Diagnostic  # pylint: disable=cyclic-import


@dataclass(frozen=True)
class Replacement:
    start: int
    end: int
    text: str


def _should_fix(path: Path) -> bool:
    """Check if file should be fixed (only test files)."""
    try:
        rel = path.relative_to(Path.cwd())
    except ValueError:
        return False
    parts = rel.parts
    return parts and parts[0] in {"test", "integration_test"}


def _extract_type_from_message(message: str) -> tuple[str | None, str | None]:
    """
    Extract source and target types from error message.
    
    Message format: "The argument type 'int' can't be assigned to the parameter type 'String'."
    or "The argument type 'String' can't be assigned to the parameter type 'int?'."
    """
    # Pattern: The argument type 'TYPE1' can't be assigned to the parameter type 'TYPE2'.
    match = re.search(
        r"The argument type '([^']+)' can't be assigned to the parameter type '([^']+)'",
        message,
    )
    if match:
        return match.group(1), match.group(2)
    return None, None


def _is_id_related_type(type_str: str) -> bool:
    """Check if type is ID-related (String, int, String?, int?, Set, Map)."""
    return type_str in {
        "String",
        "int",
        "String?",
        "int?",
        "Set<int>",
        "Set<String>",
        "Set<int?>",
        "Set<String?>",
    } or "Map<int" in type_str or "Map<String" in type_str


def _is_id_related_context(content: str, offset: int) -> bool:
    """
    Check if the error is in an ID-related context.
    Look for ID-related parameter names or patterns near the error location.
    """
    # Look at context around the offset (100 chars before and after)
    start = max(0, offset - 100)
    end = min(len(content), offset + 100)
    context = content[start:end]
    
    # Common ID-related parameter names and patterns
    id_patterns = [
        r"\bid\s*[:=]",
        r"\bparentId\s*[:=]",
        r"\btaskId\s*[:=]",
        r"\bprojectId\s*[:=]",
        r"\bmilestoneId\s*[:=]",
        r"\bsessionId\s*[:=]",
        r"\brootTaskId\s*[:=]",
        r"\btransferToTaskId\s*[:=]",
        r"Task\s*\(",
        r"Project\s*\(",
        r"Milestone\s*\(",
        r"FocusSession\s*\(",
        r"Preference\s*\(",
        r"MetricSnapshot\s*\(",
        r"_createTask\s*\(",
        r"_buildTask\s*\(",
        r"_task\s*\(",
    ]
    
    for pattern in id_patterns:
        if re.search(pattern, context, re.IGNORECASE):
            return True
    return False


def _collect_replacements(
    content: str, diagnostics: list["Diagnostic"]
) -> list[Replacement]:
    """Collect replacements for argument_type_not_assignable errors."""
    replacements: list[Replacement] = []
    
    for diag in diagnostics:
        if diag.code != "argument_type_not_assignable":
            continue
            
        if diag.offset < 0 or diag.end_offset <= diag.offset:
            continue
        
        # Extract types from error message
        source_type, target_type = _extract_type_from_message(diag.message)
        if not source_type or not target_type:
            continue
        
        # Only fix ID-related type mismatches
        if not (_is_id_related_type(source_type) and _is_id_related_type(target_type)):
            continue
        
        # Check if it's in an ID-related context
        if not _is_id_related_context(content, diag.offset):
            continue
        
        # Get the fragment at the error location
        fragment = content[diag.offset : diag.end_offset]
        stripped = fragment.strip()
        
        # Strategy 1: int literal -> String literal
        # Example: id: 1 -> id: '1'
        if source_type in {"int", "int?"} and target_type in {"String", "String?"}:
            if stripped.isdigit():
                # Simple int literal
                replacements.append(
                    Replacement(diag.offset, diag.end_offset, f"'{stripped}'")
                )
            elif stripped.startswith("{") and stripped.endswith("}"):
                # Set or Map literal: {1, 2} or {1: 0, 2: 1}
                if "Set" in target_type:
                    # Set literal: convert all numbers
                    new_fragment = re.sub(r"\b(\d+)\b", r"'\1'", stripped)
                    replacements.append(
                        Replacement(diag.offset, diag.end_offset, new_fragment)
                    )
                elif "Map" in target_type:
                    # Map literal: convert only keys (numbers before :)
                    new_fragment = re.sub(r"(\d+)\s*:", r"'\1':", stripped)
                    replacements.append(
                        Replacement(diag.offset, diag.end_offset, new_fragment)
                    )
        
        # Strategy 2: String -> int (less common, skip for safety)
        # We'll let manual fixes handle these cases
    
    return replacements


def apply_argument_type_not_assignable_fix(
    path: Path, diagnostics: list["Diagnostic"]
) -> bool:
    """
    Fix argument_type_not_assignable errors by converting int to String for ID-related arguments.
    
    This fixer is conservative and only fixes cases where:
    1. The error is in a test file
    2. The types are ID-related (int/String)
    3. The context suggests it's an ID-related parameter
    4. Uses offset-based replacement for precision
    """
    if not _should_fix(path):
        return False

    original = path.read_text(encoding="utf-8")
    replacements = _collect_replacements(original, diagnostics)
    
    if not replacements:
        return False

    # Apply replacements from end to start to avoid shifting offsets
    new_content = original
    for repl in sorted(replacements, key=lambda r: r.start, reverse=True):
        new_content = new_content[: repl.start] + repl.text + new_content[repl.end :]

    path.write_text(new_content, encoding="utf-8")
    return True
