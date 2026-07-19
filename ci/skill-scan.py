#!/usr/bin/env python3
"""Validate skill metadata and flag unsafe bundled content."""

from __future__ import annotations

import argparse
from datetime import date
from ipaddress import ip_address
from pathlib import Path
import re
import sys
from urllib.parse import urlsplit

from secret_patterns import RULES, mask_text


REQUIRED_TOP_LEVEL = ("name", "description")
REQUIRED_METADATA = (
    "scope",
    "owner",
    "last-verified",
    "freshness",
    "provenance",
)
FIELD = re.compile(r"^([A-Za-z][A-Za-z0-9_-]*):\s*(.*?)\s*$")
NAME = re.compile(r"[a-z0-9]+(?:-[a-z0-9]+)*")
FRESHNESS = re.compile(r"[1-9][0-9]*d")
PROVENANCE = re.compile(
    r"repo=[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+;\s*"
    r"license=[A-Za-z0-9][A-Za-z0-9.+-]*"
)
DYNAMIC_CONTEXT = re.compile(r"!\s*`[^`\n]+`")
URL = re.compile(r"https?://[^\s'\"<>]+")
DOMAIN = re.compile(
    r"(?<![A-Za-z0-9_.-])(?:[A-Za-z0-9-]+\.)+[A-Za-z]{2,}(?![A-Za-z0-9_.-])"
)
IP_CANDIDATE = re.compile(r"(?<![A-Za-z0-9_])[A-Za-z0-9_.:@\[\]-]+")
YAML_NUMBER = re.compile(
    r"[-+]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:e[-+]?[0-9]+)?",
    re.IGNORECASE,
)


def display(path: Path) -> str:
    try:
        return path.resolve().relative_to(Path.cwd().resolve()).as_posix()
    except ValueError:
        return path.as_posix()


def scalar(value: str) -> str:
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    yaml_keywords = {
        "~", "null", "Null", "NULL",
        "true", "True", "TRUE",
        "false", "False", "FALSE",
    }
    if (
        value in yaml_keywords
        or YAML_NUMBER.fullmatch(value)
    ):
        return ""
    return value


def strip_plain_comment(value: str) -> str:
    if value.startswith("#"):
        return ""
    if value[:1] in "\"'":
        return value
    return re.split(r"\s+#", value, maxsplit=1)[0].rstrip()


def unsupported_scalar(value: str) -> bool:
    if not value:
        return False
    starts_quote = value[:1] in "\"'"
    ends_quote = value[-1:] in "\"'"
    return (
        value.startswith(("[", "{", "*", "&", "!"))
        or starts_quote != ends_quote
        or (starts_quote and value[:1] != value[-1:])
    )


def block_scalar(lines: list[str], start: int, end: int, marker: str) -> str:
    content = []
    for line in lines[start + 1 : end]:
        if line and not line[:1].isspace():
            break
        if line.strip():
            content.append(line.strip())
    return ("\n" if marker.startswith("|") else " ").join(content)


def frontmatter(path: Path, text: str) -> tuple[list[str], str]:
    lines = text.splitlines()
    if not lines or lines[0] != "---":
        return [f"{display(path)}: frontmatter is required"], text
    try:
        end = next(i for i, line in enumerate(lines[1:], 1) if line == "---")
    except StopIteration:
        return [f"{display(path)}: frontmatter closing delimiter is required"], ""

    values: dict[str, str] = {}
    metadata: dict[str, str] = {}
    duplicates = set()
    section = None
    errors = []
    for index, line in enumerate(lines[1:end], 1):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line.startswith("  ") and not line.startswith("    ") and section == "metadata":
            match = FIELD.fullmatch(line[2:])
            if not match:
                errors.append(f"{display(path)}: invalid metadata line")
                continue
            key, value = match.groups()
            if key in metadata:
                duplicates.add(f"metadata.{key}")
            raw = strip_plain_comment(value.strip())
            if unsupported_scalar(raw):
                errors.append(f"{display(path)}: unsupported YAML scalar")
                continue
            metadata[key] = scalar(raw)
            continue
        if line[:1].isspace():
            continue
        match = FIELD.fullmatch(line)
        if not match:
            errors.append(f"{display(path)}: invalid frontmatter line")
            continue
        key, value = match.groups()
        if key in values:
            duplicates.add(key)
        raw = strip_plain_comment(value.strip())
        if unsupported_scalar(raw):
            errors.append(f"{display(path)}: unsupported YAML scalar")
            values[key] = ""
        else:
            values[key] = (
                block_scalar(lines, index, end, raw)
                if raw[:1] in {"|", ">"} and raw[1:] in {"", "+", "-"}
                else scalar(raw)
            )
        section = key if not value else None

    errors.extend(
        f"{display(path)}: duplicate frontmatter field {key}"
        for key in sorted(duplicates)
    )
    for key in REQUIRED_TOP_LEVEL:
        if not values.get(key):
            errors.append(f"{display(path)}: missing frontmatter field {key}")
    if "metadata" not in values:
        errors.append(f"{display(path)}: missing frontmatter field metadata")
    for key in REQUIRED_METADATA:
        if not metadata.get(key):
            errors.append(f"{display(path)}: missing frontmatter field metadata.{key}")

    name = values.get("name")
    if name and (len(name) > 64 or not NAME.fullmatch(name)):
        errors.append(
            f"{display(path)}: name must be at most 64 lowercase letters, digits, or hyphens"
        )
    description = values.get("description")
    if description and len(description) > 1024:
        errors.append(f"{display(path)}: description must be at most 1024 characters")
    if description and ("<" in description or ">" in description):
        errors.append(f"{display(path)}: description cannot contain angle brackets")
    if metadata.get("scope") not in {None, "", "personal", "project", "org"}:
        errors.append(f"{display(path)}: scope must be personal, project, or org")

    verified = metadata.get("last-verified")
    if verified:
        try:
            valid_date = date.fromisoformat(verified).isoformat() == verified
        except ValueError:
            valid_date = False
        if not valid_date:
            errors.append(f"{display(path)}: last-verified must be YYYY-MM-DD")

    freshness = metadata.get("freshness")
    if freshness and not FRESHNESS.fullmatch(freshness):
        errors.append(f"{display(path)}: freshness must match [1-9][0-9]*d")

    provenance = metadata.get("provenance")
    if provenance and provenance != "self" and not PROVENANCE.fullmatch(provenance):
        errors.append(
            f"{display(path)}: provenance must be self or "
            "repo=owner/repo; license=SPDX"
        )
    return errors, "\n".join(lines[end + 1 :])


def text_file(path: Path) -> str | None:
    data = path.read_bytes()
    if b"\0" in data[:8192]:
        return None
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError:
        return None


def bundled_files(skill: Path) -> tuple[list[Path], list[str]]:
    scripts = skill.parent / "scripts"
    if scripts.is_symlink():
        return [], [f"{display(scripts)}: symlink is not allowed"]
    if not scripts.exists():
        return [], []
    files = []
    errors = []
    for path in scripts.rglob("*"):
        if path.is_symlink():
            errors.append(f"{display(path)}: symlink is not allowed")
        elif path.is_file():
            files.append(path)
    return sorted(files), errors


def secret_errors(path: Path, text: str) -> list[str]:
    errors = []
    for name, rule in RULES:
        for match in rule.finditer(text):
            line = text.count("\n", 0, match.start()) + 1
            errors.append(f"{display(path)}:{line}: secret pattern {name}")
    return errors


def destinations(path: Path, text: str) -> set[tuple[str, str]]:
    text, _ = mask_text(text)
    found = {(display(path), match.group(0)) for match in DOMAIN.finditer(text)}
    for match in URL.finditer(text):
        host = urlsplit(match.group(0).rstrip(".,;:)")).hostname
        if host:
            found.add((display(path), host))
    for match in IP_CANDIDATE.finditer(text):
        candidate = match.group(0).rsplit("@", 1)[-1]
        if candidate.startswith("[") and "]" in candidate:
            candidate = candidate[1:candidate.index("]")]
        elif "." in candidate and candidate.count(":") == 1:
            host, port = candidate.rsplit(":", 1)
            candidate = host if port.isdigit() else candidate
        try:
            address = ip_address(candidate)
        except ValueError:
            continue
        found.add((display(path), str(address)))
    return found


def discover(inputs: list[Path]) -> tuple[list[Path], list[str]]:
    skills = set()
    errors = []
    for path in inputs:
        if not path.exists():
            errors.append(f"{display(path)}: path does not exist")
        elif path.is_symlink():
            errors.append(f"{display(path)}: symlink is not allowed")
        elif path.is_file():
            if path.name == "SKILL.md":
                skills.add(path)
            else:
                errors.append(f"{display(path)}: expected SKILL.md or a directory")
        else:
            for candidate in path.rglob("*"):
                if candidate.is_symlink():
                    errors.append(f"{display(candidate)}: symlink is not allowed")
                elif candidate.name == "SKILL.md" and candidate.is_file():
                    skills.add(candidate)
    return sorted(skills), errors


def scan(inputs: list[Path]) -> tuple[int, list[str], list[str]]:
    skills, errors = discover(inputs)
    network = set()
    for skill in skills:
        text = text_file(skill)
        if text is None:
            errors.append(f"{display(skill)}: SKILL.md must be UTF-8 text")
            continue
        metadata_errors, body = frontmatter(skill, text)
        errors.extend(metadata_errors)
        if DYNAMIC_CONTEXT.search(body):
            errors.append(f"{display(skill)}: dynamic context execution is forbidden")
        errors.extend(secret_errors(skill, text))

        scripts, script_errors = bundled_files(skill)
        errors.extend(script_errors)
        for script in scripts:
            script_text = text_file(script)
            if script_text is None:
                errors.append(f"{display(script)}: bundled file must be UTF-8 text")
                continue
            errors.extend(secret_errors(script, script_text))
            network.update(destinations(script, script_text))

    warnings = [
        f"{path}: unknown-network {destination}"
        for path, destination in sorted(network)
    ]
    return len(skills), sorted(set(errors)), warnings


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Validate SKILL.md files and inspect bundled scripts."
    )
    parser.add_argument(
        "paths",
        nargs="*",
        type=Path,
        default=[Path(".claude/skills")],
        help="SKILL.md file or directory to scan (default: .claude/skills)",
    )
    args = parser.parse_args()

    count, errors, warnings = scan(args.paths)
    print(*warnings, sep="\n")
    if errors:
        print(*errors, sep="\n", file=sys.stderr)
        raise SystemExit(1)
    print(f"skill scan passed: scanned {count} skill(s); unknown-network={len(warnings)}")


if __name__ == "__main__":
    main()
