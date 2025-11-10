"""Convert ID-related type annotations from int to String in tests."""

from __future__ import annotations

import re
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:  # pragma: no cover
    from ..issues import Diagnostic  # pylint: disable=cyclic-import


CONTAINER_PATTERNS = [
    re.compile(r"Map<\s*int\??\s*,"),
    re.compile(r"Map<\s*int\??\s*>"),
    re.compile(r"Set<\s*int\??\s*>"),
    re.compile(r"Iterable<\s*int\??\s*>"),
    re.compile(r"Future<\s*Map<\s*int"),
    re.compile(r"MapEntry<\s*int\??\s*,"),
]

ID_PARAM_PATTERN = re.compile(r"\b(required\s+)?int(\?)?\s+([A-Za-z_]\w*)")
TYPED_LIST_PATTERN = re.compile(r"List<\s*int\??\s*>")
MAP_LITERAL_PATTERN = re.compile(r"<\s*int\??\s*,\s*([A-Za-z_][\w<>?]*)>")
ID_ASSIGN_LITERAL_PATTERN = re.compile(r"\bid\s*:\s*(\d+)")
ID_ASSIGN_INCREMENT_PATTERN = re.compile(r"\bid\s*:\s*(_nextId\+\+)")
ACCESSOR_INT_KEY_PATTERN = re.compile(r"\[(\s*_nextId\s*\+\+\s*)\]")

ENTITY_TYPE_HINTS = (
    "Task",
    "Project",
    "Milestone",
    "FocusSession",
    "TaskTemplate",
    "Tag",
    "Preference",
    "Seed",
    "Log",
    "Update",
    "TreeNode",
)


def _replace_container_types(text: str) -> str:
    replacements = {
        "Map< int?,": "Map<String,",
        "Map<int?,": "Map<String,",
        "Map<int,": "Map<String,",
        "Map< int? >": "Map<String>",
        "Map<int?>": "Map<String>",
        "Map<int>": "Map<String>",
        "Set<int?>": "Set<String>",
        "Set<int>": "Set<String>",
        "Iterable<int?>": "Iterable<String>",
        "Iterable<int>": "Iterable<String>",
        "MapEntry<int?,": "MapEntry<String,",
        "MapEntry<int,": "MapEntry<String,",
    }
    for pattern in CONTAINER_PATTERNS:
        text = pattern.sub(lambda match: match.group(0).replace("int", "String"), text)
    for old, new in replacements.items():
        text = text.replace(old, new)
    # handle simple generic replacements
    text = TYPED_LIST_PATTERN.sub("List<String>", text)
    return text


def _replace_id_params(text: str) -> str:
    def repl(match: re.Match[str]) -> str:
        required = match.group(1) or ""
        nullable = match.group(2) or ""
        name = match.group(3)
        if "id" not in name.lower():
            return match.group(0)
        suffix = "?" if nullable else ""
        prefix = f"{required}" if required else ""
        if prefix:
            return f"{prefix}String{suffix} {name}"
        return f"String{suffix} {name}"

    return ID_PARAM_PATTERN.sub(repl, text)


def _should_convert_entity(type_name: str) -> bool:
    return any(hint in type_name for hint in ENTITY_TYPE_HINTS)


def _replace_map_literals(text: str) -> str:
    def repl(match: re.Match[str]) -> str:
        target = match.group(1)
        if not _should_convert_entity(target):
            return match.group(0)
        return match.group(0).replace("int", "String", 1)

    return MAP_LITERAL_PATTERN.sub(repl, text)


def _replace_id_assignments(text: str) -> str:
    text = ID_ASSIGN_LITERAL_PATTERN.sub(lambda m: f"id: '{m.group(1)}'", text)
    text = ID_ASSIGN_INCREMENT_PATTERN.sub(lambda m: f"id: ({m.group(1)}).toString()", text)
    text = ACCESSOR_INT_KEY_PATTERN.sub(lambda m: f"[({m.group(1)}).toString()]", text)
    return text


def apply_id_type_annotations(path: Path, diagnostics: list["Diagnostic"]) -> bool:
    original = path.read_text(encoding="utf-8")
    updated = original
    updated = _replace_container_types(updated)
    updated = _replace_id_params(updated)
    updated = _replace_map_literals(updated)
    updated = _replace_id_assignments(updated)
    if updated == original:
        return False
    path.write_text(updated, encoding="utf-8")
    return True
