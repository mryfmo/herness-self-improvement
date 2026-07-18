#!/usr/bin/env python3

import hashlib
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MARKERS = {
    "<!-- COMMON -->": "common",
    "<!-- CLAUDE -->": "claude",
    "<!-- AGENTS -->": "agents",
}
TARGETS = {
    "CLAUDE.md": ("Claude Code Rules", "claude"),
    "AGENTS.md": ("Agent Rules", "agents"),
}


def parse_sections(source):
    sections = {name: [] for name in MARKERS.values()}
    current = None
    seen = set()

    for line in source.splitlines():
        if line in MARKERS:
            current = MARKERS[line]
            if current in seen:
                raise ValueError(f"duplicate marker: {line}")
            seen.add(current)
        elif current is None:
            if line.strip():
                raise ValueError("content before first marker")
        else:
            sections[current].append(line)

    if seen != set(sections):
        raise ValueError("rules.src.md requires COMMON, CLAUDE, and AGENTS markers")
    return {name: "\n".join(lines).strip() for name, lines in sections.items()}


def render(source, target):
    title, target_section = TARGETS[target]
    sections = parse_sections(source)
    digest = hashlib.sha256(source.encode()).hexdigest()
    return (
        "<!-- GENERATED FILE — edit rules.src.md -->\n"
        f"<!-- source-sha256: {digest} -->\n\n"
        f"# {title}\n\n"
        f"{sections['common']}\n\n"
        f"{sections[target_section]}\n"
    )


def generate(root=ROOT):
    source = (root / "rules.src.md").read_bytes().decode("utf-8")
    paths = []
    for target in TARGETS:
        path = root / target
        path.write_text(render(source, target), encoding="utf-8")
        paths.append(path)
    return paths


def warn_long_files(paths, limit=120, output=sys.stdout):
    for path in paths:
        lines = len(path.read_text(encoding="utf-8").splitlines())
        if lines > limit:
            print(
                f"::warning file={path.name}::{path.name} has {lines} lines; limit is {limit}",
                file=output,
            )


if __name__ == "__main__":
    warn_long_files(generate())
