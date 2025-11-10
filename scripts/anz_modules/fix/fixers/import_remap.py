"""Fixer for remapping stale import URIs introduced during major refactors."""

from __future__ import annotations

import re
from pathlib import Path
from typing import Dict, List, Optional, Tuple, TYPE_CHECKING

if TYPE_CHECKING:  # pragma: no cover - type checking only
    from ..issues import Diagnostic  # pylint: disable=cyclic-import


IMPORT_RE = re.compile(r"^\s*import\s+['\"](?P<uri>[^'\"]+)['\"];\s*$")

# Hard-coded remap table derived from ObjectBox migration blueprint.
DIRECT_MAPPING: Dict[str, str] = {
    # Isar -> ObjectBox entity mappings
    "package:granoflow/data/isar/focus_session_entity.dart": "package:granoflow/data/objectbox/focus_session_entity.dart",
    "package:granoflow/data/isar/milestone_entity.dart": "package:granoflow/data/objectbox/milestone_entity.dart",
    "package:granoflow/data/isar/project_entity.dart": "package:granoflow/data/objectbox/project_entity.dart",
    "package:granoflow/data/isar/preference_entity.dart": "package:granoflow/data/objectbox/preference_entity.dart",
    "package:granoflow/data/isar/seed_import_log_entity.dart": "package:granoflow/data/objectbox/seed_import_log_entity.dart",
    "package:granoflow/data/isar/tag_entity.dart": "package:granoflow/data/objectbox/tag_entity.dart",
    "package:granoflow/data/isar/task_entity.dart": "package:granoflow/data/objectbox/task_entity.dart",
    "package:granoflow/data/isar/task_template_entity.dart": "package:granoflow/data/objectbox/task_template_entity.dart",
    # Relative path Isar -> ObjectBox
    "data/isar/focus_session_entity.dart": "package:granoflow/data/objectbox/focus_session_entity.dart",
}

# Imports that should be removed (no longer needed)
REMOVE_IMPORTS: set[str] = {
    "package:isar/isar.dart",
    "package:isar_flutter_libs/isar_flutter_libs.dart",
}

RELATIVE_MAPPING: Dict[str, str] = {
    "../models/preference.dart": "package:granoflow/data/models/preference.dart",
    "../models/tag.dart": "package:granoflow/data/models/tag.dart",
    "../models/task_template.dart": "package:granoflow/data/models/task_template.dart",
    "../models/task.dart": "package:granoflow/data/models/task.dart",
    "../models/focus_session.dart": "package:granoflow/data/models/focus_session.dart",
    "../models/project.dart": "package:granoflow/data/models/project.dart",
    "../models/milestone.dart": "package:granoflow/data/models/milestone.dart",
    "../models/seed_import_log.dart": "package:granoflow/data/models/seed_import_log.dart",
    "../../config/app_constants.dart": "package:granoflow/core/config/app_constants.dart",
}

PREFIX_MAPPING: List[Tuple[str, str]] = [
    ("package:granoflow/data/isar/", "package:granoflow/data/objectbox/"),
    ("../../isar/", "../../objectbox/"),
]


def resolve_replacement(uri: str) -> Optional[str]:
    """Return remapped URI if available."""
    if uri in DIRECT_MAPPING:
        return DIRECT_MAPPING[uri]
    if uri in RELATIVE_MAPPING:
        return RELATIVE_MAPPING[uri]
    for prefix, target in PREFIX_MAPPING:
        if uri.startswith(prefix):
            return uri.replace(prefix, target, 1)
    return None


def apply_import_remap(path: Path, diagnostics: List["Diagnostic"]) -> bool:
    """Remap outdated imports to their ObjectBox equivalents or remove obsolete imports."""
    lines = path.read_text(encoding="utf-8").splitlines()
    changed = False

    for diag in diagnostics:
        idx = diag.line - 1
        if not 0 <= idx < len(lines):
            continue
        match = IMPORT_RE.match(lines[idx])
        if not match:
            continue
        current_uri = match.group("uri")
        
        # Check if this import should be removed
        if current_uri in REMOVE_IMPORTS:
            print(f"[anz:fix] Removing obsolete import {current_uri} in {path}")
            lines[idx] = ""
            changed = True
            continue
        
        # Try to remap
        replacement = resolve_replacement(current_uri)
        if not replacement:
            continue
        if replacement == current_uri:
            continue
        print(f"[anz:fix] Remapping import {current_uri} -> {replacement} in {path}")
        lines[idx] = lines[idx].replace(current_uri, replacement)
        changed = True

    if changed:
        path.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")
    return changed


SUPPORTED_CODES = {
    "uri_does_not_exist",
}
