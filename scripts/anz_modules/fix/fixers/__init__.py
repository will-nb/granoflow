"""Collection of fixer helpers for `scripts/anz_modules/fix/issues.py`."""

from __future__ import annotations

from typing import TYPE_CHECKING, Callable, Dict, List, Set

if TYPE_CHECKING:  # pragma: no cover - only for type checkers
    from pathlib import Path
    from ..issues import Diagnostic  # pylint: disable=cyclic-import

FixerResult = bool
FixerFunc = Callable[["Path", List["Diagnostic"]], FixerResult]
BulkFixerFunc = Callable[[Dict["Path", List["Diagnostic"]]], Set["Path"]]

__all__ = [
    "FixerFunc",
    "FixerResult",
    "BulkFixerFunc",
]
