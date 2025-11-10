"""Fix undefined_getter errors by replacing old property names with new ones."""

from __future__ import annotations

import re
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:  # pragma: no cover
    from ..issues import Diagnostic  # pylint: disable=cyclic-import

# Property name mappings: old_name -> new_name
PROPERTY_MAPPINGS = {
    "milestoneId": "id",
    "projectId": "id",
    "parentTaskId": "parentId",  # Task.parentId exists
    "taskId": "id",  # For Task objects
    "isarId": "id",  # Old Isar ID property
}


def _should_fix(path: Path) -> bool:
    """Check if file should be fixed."""
    try:
        rel = path.relative_to(Path.cwd())
    except ValueError:
        return False
    parts = rel.parts
    # Fix in both lib and test files
    return parts and parts[0] in {"lib", "test", "integration_test"}


def apply_undefined_getter_fix(
    path: Path, diagnostics: list["Diagnostic"]
) -> bool:
    """
    Fix undefined_getter errors by replacing old property names with new ones.
    
    This fixer handles cases where code references properties that have been renamed
    during the Isar to ObjectBox migration (e.g., milestoneId -> id).
    """
    if not _should_fix(path):
        return False

    original = path.read_text(encoding="utf-8")
    lines = original.splitlines()
    changed = False

    # Process each diagnostic
    for diag in diagnostics:
        if diag.code != "undefined_getter":
            continue

        line_idx = diag.line - 1
        if line_idx < 0 or line_idx >= len(lines):
            continue

        line = lines[line_idx]
        message = diag.message

        # Extract the property name from the error message
        # Message format: "The getter 'milestoneId' isn't defined for the type 'Milestone'..."
        property_match = re.search(r"getter '([^']+)'", message)
        if not property_match:
            continue

        old_property = property_match.group(1)
        
        # Check if we have a mapping for this property
        if old_property not in PROPERTY_MAPPINGS:
            continue

        new_property = PROPERTY_MAPPINGS[old_property]

        # Replace the property name in the line
        # Use word boundaries to avoid partial matches
        # Pattern: .oldProperty or .oldProperty. or .oldProperty)
        pattern = re.compile(rf"\.{re.escape(old_property)}\b")
        new_line = pattern.sub(f".{new_property}", line)

        if new_line != line:
            lines[line_idx] = new_line
            changed = True

    if changed:
        path.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")
        return True

    return False
