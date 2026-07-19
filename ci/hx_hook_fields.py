#!/usr/bin/env python3
"""Parse one Claude hook event and emit hex-safe telemetry fields."""

from __future__ import annotations

import json
import sys

from secret_patterns import mask_text


def string(data: dict[str, object], key: str, *, required: bool = False) -> str:
    value = data.get(key, "")
    if not isinstance(value, str) or (required and not value):
        raise ValueError(key)
    return value


def main() -> None:
    if len(sys.argv) != 2 or sys.argv[1] not in {"session-start", "prompt-submit"}:
        raise SystemExit("usage: ci/hx_hook_fields.py session-start|prompt-submit")
    try:
        data = json.load(sys.stdin)
        if not isinstance(data, dict):
            raise ValueError("event")
        session_id = string(data, "session_id", required=True)
        project = string(data, "cwd")
        content, masked = (
            mask_text(string(data, "prompt"))
            if sys.argv[1] == "prompt-submit"
            else ("", False)
        )
    except (json.JSONDecodeError, ValueError):
        raise SystemExit("invalid hook input") from None

    fields = (session_id, project, content)
    print("|".join([*(value.encode().hex() for value in fields), str(int(masked))]))


if __name__ == "__main__":
    main()
