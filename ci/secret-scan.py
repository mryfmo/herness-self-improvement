#!/usr/bin/env python3
"""Detect known secret formats without printing matched secret values."""

from __future__ import annotations

from pathlib import Path
import re
import sys


ROOT = Path.cwd()
ALLOWLIST = ROOT / "ci" / "secret-allowlist.txt"
RULES = [
    ("github_token", re.compile(r"gh[pousr]_[A-Za-z0-9]{20,}")),
    ("anthropic_key", re.compile(r"sk-ant-[A-Za-z0-9_-]{20,}")),
    ("aws_access_key", re.compile(r"AKIA[0-9A-Z]{16}")),
    ("bearer_token", re.compile(r"\bBearer\s+[A-Za-z0-9._-]{20,}", re.IGNORECASE)),
    (
        "key_value_secret",
        re.compile(
            r"""(?:api[_-]?key|token|client[_-]?secret|password)["']?\s*[:=]\s*["']?[A-Za-z0-9._~-]{16,}""",
            re.IGNORECASE,
        ),
    ),
    ("jwt", re.compile(r"\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+")),
    ("private_key_header", re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----")),
]


def allowlist() -> set[str]:
    return {
        line.strip()
        for line in ALLOWLIST.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    }


def text_files():
    for path in ROOT.rglob("*"):
        if not path.is_file() or path.is_symlink() or ".git" in path.parts:
            continue
        data = path.read_bytes()
        if b"\0" in data[:8192]:
            continue
        try:
            yield path, data.decode("utf-8")
        except UnicodeDecodeError:
            continue


def main() -> None:
    if len(sys.argv) != 1:
        raise SystemExit("usage: ci/secret-scan.py")
    allowed = allowlist()
    findings: set[tuple[str, int, str]] = set()
    for path, text in text_files():
        relative = path.relative_to(ROOT).as_posix()
        for name, rule in RULES:
            for match in rule.finditer(text):
                if match.group(0) in allowed:
                    continue
                line = text.count("\n", 0, match.start()) + 1
                findings.add((relative, line, name))
    for path, line, name in sorted(findings):
        print(f"{path}:{line}: secret pattern {name}", file=sys.stderr)
    if findings:
        raise SystemExit(1)
    print("secret scan clean")


if __name__ == "__main__":
    main()
