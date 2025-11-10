"""Fix return_of_invalid_type_from_closure errors by updating Map/Set key types from int to String."""

from __future__ import annotations

import re
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:  # pragma: no cover
    from ..issues import Diagnostic  # pylint: disable=cyclic-import

# Pattern to match Map<int, ...> or Map<int?, ...>
MAP_INT_PATTERN = re.compile(r"Map<\s*int\??\s*,")

# Pattern to match Set<int> or Set<int?>
SET_INT_PATTERN = re.compile(r"Set<\s*int\??\s*>")

# Pattern to match Map<int, Set<int>> or similar nested structures
NESTED_MAP_SET_PATTERN = re.compile(r"Map<\s*int\??\s*,\s*Set<\s*int\??\s*>>")


def _should_fix(path: Path) -> bool:
    """Check if file should be fixed (only test files)."""
    try:
        rel = path.relative_to(Path.cwd())
    except ValueError:
        return False
    parts = rel.parts
    return parts and parts[0] in {"test", "integration_test"}


def apply_return_of_invalid_type_from_closure_fix(
    path: Path, diagnostics: list["Diagnostic"]
) -> bool:
    """
    Fix return_of_invalid_type_from_closure errors by updating Map/Set key types.
    
    This fixer handles cases where closures return Map<int, ...> or Set<int>
    but the expected return type is Map<String, ...> or Set<String>.
    """
    if not _should_fix(path):
        return False

    original = path.read_text(encoding="utf-8")
    lines = original.splitlines()
    changed = False

    # Process each diagnostic
    for diag in diagnostics:
        if diag.code != "return_of_invalid_type_from_closure":
            continue

        line_idx = diag.line - 1
        if line_idx < 0 or line_idx >= len(lines):
            continue

        line = lines[line_idx]
        message = diag.message

        # Extract the returned type from the error message
        # Message format: "The returned type 'Map<int, int>' isn't returnable from a 'Future<Map<String, int>>' function..."
        returned_type_match = re.search(r"returned type '([^']+)'", message)
        if not returned_type_match:
            continue

        returned_type = returned_type_match.group(1)

        # Check if this is a Map or Set with int keys/elements
        # Look for patterns like: Map<int, ...>, Map<int?, ...>, Set<int>, Set<int?>
        if "Set<" in returned_type and "int" in returned_type and "Map<" not in returned_type:
            # Handle Set<int> -> Set<String>
            new_type = returned_type
            # Replace Set<int> with Set<String>
            new_type = re.sub(r"Set<\s*int\??\s*>", "Set<String>", new_type)
            
            if new_type != returned_type:
                new_line = line
                
                # Step 1: Replace type annotations
                # Replace Set<int> with Set<String> (explicit type)
                new_line = re.sub(r"Set<\s*int\??\s*>", "Set<String>", new_line)
                # Replace <int> with <String> (inferred type annotation like <int>{})
                new_line = re.sub(r"<\s*int\??\s*>", "<String>", new_line)
                
                # Step 2: Fix Set literal elements (convert int elements to String)
                # Pattern: {1, 2, 3} -> {'1', '2', '3'}
                # Only fix if we have a type annotation that suggests String elements
                if "<String>" in new_line or "Set<String>" in new_line:
                    # Pattern to match Set literal elements: {int, or , int, or , int}
                    set_element_pattern = re.compile(r"([{,]\s*)(\d+)(\s*[,}])")
                    new_line = set_element_pattern.sub(
                        lambda m: m.group(1) + f"'{m.group(2)}'" + m.group(3),
                        new_line
                    )
                
                if new_line != line:
                    lines[line_idx] = new_line
                    changed = True
                    continue
        
        if "Map<" in returned_type and "int" in returned_type:
            # Replace Map<int, ...> with Map<String, ...>
            # Handle nested structures like Map<int, Set<int>>
            new_type = returned_type
            # Replace Map<int, with Map<String,
            new_type = re.sub(r"Map<\s*int\??\s*,", "Map<String,", new_type)
            # Replace Set<int> with Set<String>
            new_type = re.sub(r"Set<\s*int\??\s*>", "Set<String>", new_type)
            
            # Find the actual return statement in the line
            # The line might contain: <int, int>{...} or Map<int, int>{...}
            # We need to replace the type annotation in the code AND fix Map literal keys
            if new_type != returned_type:
                new_line = line
                
                # Step 1: Replace type annotations
                # Replace Map<int, with Map<String,
                new_line = re.sub(r"Map<\s*int\??\s*,", "Map<String,", new_line)
                # Replace <int, with <String, (for type annotations like <int, int>)
                new_line = re.sub(r"<\s*int\??\s*,", "<String,", new_line)
                # Replace Set<int> with Set<String>
                new_line = re.sub(r"Set<\s*int\??\s*>", "Set<String>", new_line)
                
                # Step 2: Fix Map literal keys (convert int keys to String)
                # Pattern to match Map literal keys: {int_key: or , int_key:
                # Only fix if we have a type annotation that suggests String keys
                if "<String," in new_line or "Map<String," in new_line:
                    map_key_pattern = re.compile(r"([{,]\s*)(\d+)(\s*:)")
                    new_line = map_key_pattern.sub(
                        lambda m: m.group(1) + f"'{m.group(2)}'" + m.group(3),
                        new_line
                    )
                
                if new_line != line:
                    lines[line_idx] = new_line
                    changed = True
                    continue

    if changed:
        path.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")
        return True

    return False
