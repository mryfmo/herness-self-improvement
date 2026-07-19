#!/usr/bin/env python3
"""Check docs frontmatter and repository-relative Markdown links."""

from datetime import date
from pathlib import Path
import re
import sys
from urllib.parse import unquote, urlsplit


INLINE_LINK = re.compile(r"!?\[[^\]]*\]\(([^)\n]+)\)")
REFERENCE_LINK = re.compile(r"^\s*\[[^\]]+\]:\s*(<[^>]+>|\S+)", re.MULTILINE)
FIELD = re.compile(r"^([A-Za-z][A-Za-z0-9_-]*):\s*(.*?)\s*$")
FRESHNESS = re.compile(r"\d+d")
REQUIRED = ("owner", "last-verified", "freshness")


def documents(root: Path) -> list[Path]:
    return sorted(path for path in (root / "docs").rglob("*.md") if path.is_file())


def exemptions(root: Path) -> set[str]:
    path = root / "ci" / "docs-frontmatter-exempt.txt"
    return {
        line.strip()
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    }


def scalar(value: str) -> str:
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    return value


def frontmatter_errors(root: Path, path: Path) -> list[str]:
    relative = path.relative_to(root).as_posix()
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0].strip() != "---":
        return [f"{relative}: frontmatter is required"]
    try:
        end = next(index for index, line in enumerate(lines[1:], 1) if line.strip() == "---")
    except StopIteration:
        return [f"{relative}: frontmatter closing delimiter is required"]

    values: dict[str, str] = {}
    duplicates: set[str] = set()
    for line in lines[1:end]:
        match = FIELD.match(line)
        if not match:
            continue
        key, value = match.groups()
        if key in values:
            duplicates.add(key)
        values[key] = scalar(value.strip())

    errors = [f"{relative}: duplicate frontmatter field {key}" for key in sorted(duplicates)]
    for key in REQUIRED:
        if key not in values:
            errors.append(f"{relative}: missing frontmatter field {key}")

    owner = values.get("owner", "")
    if "owner" in values and (
        not owner
        or owner.lower() in {"null", "~", "true", "false"}
        or owner[:1] in "[{|>"
        or re.fullmatch(r"[+-]?(?:\d+(?:\.\d*)?|\.\d+)", owner)
    ):
        errors.append(f"{relative}: owner must be a non-empty string")

    verified = values.get("last-verified")
    if verified is not None:
        try:
            valid_date = date.fromisoformat(verified).isoformat() == verified
        except ValueError:
            valid_date = False
        if not valid_date:
            errors.append(f"{relative}: last-verified must be YYYY-MM-DD")

    freshness = values.get("freshness")
    if freshness is not None and not FRESHNESS.fullmatch(freshness):
        errors.append(f"{relative}: freshness must match \\d+d")
    return errors


def link_target(raw: str) -> str:
    raw = raw.strip()
    if raw.startswith("<"):
        closing = raw.find(">")
        return raw[1:closing] if closing >= 0 else raw
    return raw.split(maxsplit=1)[0] if raw else ""


def link_errors(root: Path, source: Path) -> list[str]:
    relative = source.relative_to(root).as_posix()
    text = source.read_text(encoding="utf-8")
    targets = [*INLINE_LINK.findall(text), *REFERENCE_LINK.findall(text)]
    errors = []
    for raw in targets:
        target = link_target(raw)
        parsed = urlsplit(target)
        if not target or target.startswith("#") or parsed.scheme or parsed.netloc or parsed.path.startswith("/"):
            continue
        path_text = unquote(parsed.path)
        if not path_text:
            continue
        resolved = (source.parent / path_text).resolve()
        try:
            resolved.relative_to(root)
        except ValueError:
            errors.append(f"{relative}: link target escapes repository: {target}")
            continue
        if not resolved.exists():
            errors.append(f"{relative}: link target does not exist: {target}")
    return errors


def check(root: Path) -> list[str]:
    root = root.resolve()
    docs = documents(root)
    exempt = exemptions(root)
    errors = []
    for path in docs:
        if path.relative_to(root).as_posix() not in exempt:
            errors.extend(frontmatter_errors(root, path))
    for path in [root / "README.md", *docs]:
        if path.is_file():
            errors.extend(link_errors(root, path))
    return sorted(errors)


def main() -> None:
    if len(sys.argv) != 1:
        raise SystemExit("usage: ci/check-docs.py")
    errors = check(Path.cwd())
    if errors:
        print(*errors, sep="\n", file=sys.stderr)
        raise SystemExit(1)
    print(f"docs check passed ({len(documents(Path.cwd()))} documents)")


if __name__ == "__main__":
    main()
