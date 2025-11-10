"""Fix undefined_named_parameter errors by renaming parameters to match new API."""

from __future__ import annotations

import re
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:  # pragma: no cover
    from ..issues import Diagnostic  # pylint: disable=cyclic-import

# Parameter name mappings: old_name -> new_name
PARAM_NAME_MAPPINGS = {
    "taskId": "id",
    "isarId": "id",
    "projectId": "id",
    "milestoneId": "id",
    "sessionId": "id",
    "parentTaskId": "parentId",
    "transferToTaskId": "transferToTaskId",  # Keep as is for now
}

# Pattern to match named parameters in function calls
NAMED_PARAM_PATTERN = re.compile(
    r"\b(" + "|".join(re.escape(k) + r"\s*:" for k in PARAM_NAME_MAPPINGS.keys()) + r")"
)


def _should_fix(path: Path) -> bool:
    """Check if file should be fixed (all files)."""
    return True


def apply_undefined_named_parameter_fix(
    path: Path, diagnostics: list["Diagnostic"]
) -> bool:
    """
    Fix undefined_named_parameter errors by renaming parameters.
    
    This fixer handles cases where parameter names have changed:
    - taskId -> id
    - isarId -> id
    - projectId -> id
    - milestoneId -> id
    - sessionId -> id
    - parentTaskId -> parentId
    """
    if not _should_fix(path):
        return False

    original = path.read_text(encoding="utf-8")
    lines = original.splitlines()
    changed = False

    # Process each diagnostic
    for diag in diagnostics:
        if diag.code != "undefined_named_parameter":
            continue

        line_idx = diag.line - 1
        if line_idx < 0 or line_idx >= len(lines):
            continue

        line = lines[line_idx]
        message = diag.message

        # Extract the parameter name from the error message
        # Message format: "The named parameter 'taskId' isn't defined..."
        param_match = re.search(r"named parameter '(\w+)'", message)
        if not param_match:
            continue

        old_param_name = param_match.group(1)
        new_param_name = PARAM_NAME_MAPPINGS.get(old_param_name)

        if not new_param_name:
            # Unknown parameter name, skip
            continue

        # Check if the new parameter name already exists in the same line or nearby lines
        # If it does, we should remove the old parameter instead of renaming
        context_lines = []
        for i in range(max(0, line_idx - 2), min(len(lines), line_idx + 3)):
            context_lines.append(lines[i])
        context = "\n".join(context_lines)
        
        # Check if new_param_name already exists in context
        new_param_pattern = re.compile(
            r"\b" + re.escape(new_param_name) + r"\s*:",
            re.IGNORECASE,
        )
        
        if new_param_pattern.search(context):
            # New parameter already exists, remove the old one
            # Match patterns like: taskId: value, taskId:value, taskId : value
            # Also handle trailing comma
            pattern = re.compile(
                r",\s*" + re.escape(old_param_name) + r"\s*:\s*[^,)]+",
                re.IGNORECASE,
            )
            new_line = pattern.sub("", line)
            
            # Also handle if it's the first parameter
            pattern2 = re.compile(
                r"\b" + re.escape(old_param_name) + r"\s*:\s*[^,)]+\s*,",
                re.IGNORECASE,
            )
            new_line = pattern2.sub("", new_line)
        else:
            # Replace the parameter name
            pattern = re.compile(
                r"\b" + re.escape(old_param_name) + r"\s*:",
                re.IGNORECASE,
            )
            new_line = pattern.sub(f"{new_param_name}:", line)

        if new_line != line:
            lines[line_idx] = new_line
            changed = True

    if changed:
        path.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")
        return True

    return False
