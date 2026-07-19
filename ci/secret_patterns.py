"""Secret patterns shared by repository scanning and telemetry masking."""

from __future__ import annotations

import re


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


def mask_text(text: str) -> tuple[str, bool]:
    """Replace every detected secret with a rule-specific marker."""
    masked = False
    for name, rule in RULES:
        text, replacements = rule.subn(f"[REDACTED:{name}]", text)
        masked = masked or replacements > 0
    return text, masked
