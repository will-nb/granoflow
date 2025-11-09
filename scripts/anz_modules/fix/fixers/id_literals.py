"""Fixers that rewrite numeric ID literals to strings in tests."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, TYPE_CHECKING

if TYPE_CHECKING:  # pragma: no cover
    from ..issues import Diagnostic  # pylint: disable=cyclic-import


@dataclass(frozen=True)
class Replacement:
    start: int
    end: int
    text: str


def _should_handle(path: Path) -> bool:
    try:
        rel = path.relative_to(Path.cwd())
    except ValueError:
        return False
    parts = rel.parts
    return (
        len(parts) > 0
        and parts[0] in {"test", "integration_test"}
    )


def _collect_replacements(content: str, diagnostics: Iterable["Diagnostic"]) -> List[Replacement]:
    replacements: List[Replacement] = []
    for diag in diagnostics:
        if diag.offset < 0 or diag.end_offset <= diag.offset:
            continue
        fragment = content[diag.offset:diag.end_offset]
        stripped = fragment.strip()
        if not stripped.isdigit():
            continue
        if "'"+stripped+"'" == fragment or '"' + stripped + '"' == fragment:
            continue
        replacements.append(Replacement(diag.offset, diag.end_offset, f"'{stripped}'"))
    return replacements


def apply_id_literal_conversion(path: Path, diagnostics: List["Diagnostic"]) -> bool:
    if not _should_handle(path):
        return False
    original = path.read_text(encoding="utf-8")
    replacements = _collect_replacements(original, diagnostics)
    if not replacements:
        return False

    # Apply replacements from end to start to avoid shifting offsets.
    new_content = original
    for repl in sorted(replacements, key=lambda r: r.start, reverse=True):
        new_content = new_content[:repl.start] + repl.text + new_content[repl.end:]

    path.write_text(new_content, encoding="utf-8")
    return True
