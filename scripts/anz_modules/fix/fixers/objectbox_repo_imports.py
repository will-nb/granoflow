"""Ensure ObjectBox repository files import the new domain models."""

from __future__ import annotations

from pathlib import Path
from typing import Dict, List, Set, TYPE_CHECKING

if TYPE_CHECKING:  # pragma: no cover - type checking only
    from ..issues import Diagnostic  # pylint: disable=cyclic-import


_REPO_IMPORTS: Dict[str, List[str]] = {
    "objectbox_preference_repository.dart": [
        "package:granoflow/data/models/preference.dart",
    ],
    "objectbox_tag_repository.dart": [
        "package:granoflow/data/models/tag.dart",
    ],
    "objectbox_task_template_repository.dart": [
        "package:granoflow/data/models/task_template.dart",
    ],
    "objectbox_task_repository.dart": [
        "package:granoflow/data/models/task.dart",
    ],
    "objectbox_focus_session_repository.dart": [
        "package:granoflow/data/models/focus_session.dart",
    ],
    "objectbox_project_repository.dart": [
        "package:granoflow/data/models/project.dart",
    ],
    "objectbox_milestone_repository.dart": [
        "package:granoflow/data/models/milestone.dart",
    ],
    "objectbox_seed_repository.dart": [
        "package:granoflow/data/models/seed_import_log.dart",
    ],
}


SUPPORTED_CODES = {
    "undefined_class",
    "non_type_as_type_argument",
    "undefined_identifier",
}


def ensure_imports(path: Path, imports: List[str]) -> bool:
    """Insert missing imports near the top of the file."""
    content = path.read_text(encoding="utf-8").splitlines()
    existing: Set[str] = set()
    last_import_idx = -1

    for idx, line in enumerate(content):
        stripped = line.strip()
        if stripped.startswith("import "):
            last_import_idx = idx
            try:
                uri = stripped.split("import", 1)[1].strip()
            except IndexError:
                continue
            if uri.endswith(";"):
                uri = uri[:-1].strip()
            existing.add(uri.strip("'\""))

    missing = [uri for uri in imports if uri not in existing]
    if not missing:
        return False

    insertion_index = last_import_idx + 1 if last_import_idx >= 0 else 0
    for offset, uri in enumerate(missing):
        content.insert(insertion_index + offset, f"import '{uri}';")

    path.write_text("\n".join(content) + ("\n" if content else ""), encoding="utf-8")
    return True


def apply_objectbox_repo_imports(path: Path, diagnostics: List["Diagnostic"]) -> bool:
    """Ensure required model imports exist for ObjectBox repository files."""
    file_name = path.name
    required = _REPO_IMPORTS.get(file_name)
    if not required:
        return False
    return ensure_imports(path, required)
