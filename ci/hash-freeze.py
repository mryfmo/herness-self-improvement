#!/usr/bin/env python3
"""Freeze or verify SHA-256 hashes for configured repository paths."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import sys


ROOT = Path.cwd()
CONFIG = ROOT / "ci" / "frozen-paths.txt"
MANIFEST = ROOT / "ci" / "frozen-manifest.json"


def configured_paths() -> list[Path]:
    entries = []
    for line in CONFIG.read_text(encoding="utf-8").splitlines():
        value = line.strip()
        if not value or value.startswith("#"):
            continue
        path = Path(value)
        if path.is_absolute() or ".." in path.parts:
            raise ValueError(f"frozen path must be repository-relative: {value}")
        entries.append(ROOT / path)
    return entries


def frozen_files() -> list[Path]:
    files: set[Path] = set()
    for entry in configured_paths():
        if not entry.exists():
            raise FileNotFoundError(f"frozen path does not exist: {entry.relative_to(ROOT)}")
        candidates = [entry] if entry.is_file() else entry.rglob("*")
        for path in candidates:
            if path == MANIFEST or "__pycache__" in path.parts or path.suffix == ".pyc":
                continue
            if path.is_symlink():
                raise ValueError(f"symlink is not allowed in frozen paths: {path.relative_to(ROOT)}")
            if path.is_file():
                files.add(path)
    return sorted(files)


def snapshot() -> dict[str, str]:
    return {
        path.relative_to(ROOT).as_posix(): hashlib.sha256(path.read_bytes()).hexdigest()
        for path in frozen_files()
    }


def freeze() -> None:
    files = snapshot()
    payload = {"algorithm": "sha256", "files": files}
    MANIFEST.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"froze {len(files)} files")


def verify() -> None:
    payload = json.loads(MANIFEST.read_text(encoding="utf-8"))
    if payload.get("algorithm") != "sha256" or not isinstance(payload.get("files"), dict):
        raise ValueError("invalid frozen manifest")
    expected = payload["files"]
    actual = snapshot()
    changed = sorted(path for path in set(expected) | set(actual) if expected.get(path) != actual.get(path))
    if changed:
        for path in changed:
            print(f"frozen mismatch: {path}", file=sys.stderr)
        raise SystemExit(1)
    print(f"verified {len(actual)} frozen files")


def main() -> None:
    if len(sys.argv) != 2 or sys.argv[1] not in {"freeze", "verify"}:
        raise SystemExit("usage: ci/hash-freeze.py freeze|verify")
    freeze() if sys.argv[1] == "freeze" else verify()


if __name__ == "__main__":
    main()
