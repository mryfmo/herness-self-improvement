---
owner: mryfmo
last-verified: 2026-07-19
freshness: 90d
---

# Wiki conventions

## Frontmatter

Every Markdown file below `docs/` starts with YAML frontmatter containing:

- `owner`: non-empty person or team name
- `last-verified`: real calendar date in `YYYY-MM-DD` form
- `freshness`: review interval such as `30d`, `90d`, or `180d`

Copy this template:

```yaml
---
owner: <person-or-team>
last-verified: YYYY-MM-DD
freshness: 90d
---

# Title
```

The protected legacy documents listed in `ci/docs-frontmatter-exempt.txt` are temporarily exempt from frontmatter only. Add frontmatter and remove the exemption when each document is revised.

## Directory responsibilities

- `docs/decisions/`: one durable architecture or governance decision per ADR
- `docs/plans/`: versioned implementation plans and execution sequencing
- `docs/specs/`: requirements, scope, interfaces, and acceptance conditions
- `docs/reference/`: operational facts, procedures, measurements, and conventions
- `docs/lessons/`: validated reusable lessons and their application boundaries

## Links

Use relative Markdown links for repository content. Resolve them from the document containing the link and keep the target in the repository. Fragments are allowed. HTTP and HTTPS links are treated as external.

Run the same checks as CI:

```sh
python3 ci/test_check_docs.py
python3 ci/check-docs.py
```
