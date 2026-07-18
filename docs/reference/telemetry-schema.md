---
owner: mryfmo
last-verified: 2026-07-18
freshness: 90d
---

# Telemetry schema

## Scope

The harness experience layer uses an injected SQLite database path. Every extension object uses the `hx_` namespace, so the schema can share the agmsg database or use a separate file without code changes. The deployment choice remains open until P1-F1-T5.

Run `db/migrate.sh up|down|status <db-path>`. The wrapper enables WAL and a 5,000 ms busy timeout; up/down connections also enable foreign keys. Applications must enable foreign keys on their own SQLite connections.

Timestamps are ISO 8601 text. Boolean fields are integers constrained to `0` or `1`.

## Migration ledger

### `hx_schema_migrations`

| Column | Type | Meaning |
|---|---|---|
| `version` | TEXT PRIMARY KEY | Applied migration identifier. |
| `applied_at` | TEXT NOT NULL | UTC application timestamp. |

The ledger remains after a down migration so `status` can report `0001_telemetry pending`.

## Experience tables

### `hx_sessions`

| Column | Type | Meaning |
|---|---|---|
| `session_id` | TEXT PRIMARY KEY | Stable session identifier. |
| `agent_type` | TEXT NOT NULL | Agent implementation such as Claude Code or Codex. |
| `project` | TEXT NOT NULL | Project identifier or path label. |
| `started_at` | TEXT NOT NULL | Session start time. |
| `ended_at` | TEXT | Session end time when complete. |
| `status` | TEXT NOT NULL | Current or terminal session status. |

### `hx_prompts`

| Column | Type | Meaning |
|---|---|---|
| `id` | INTEGER PRIMARY KEY | Prompt event row id. |
| `session_id` | TEXT NOT NULL, FK | Owning `hx_sessions` row; cascades on session deletion. |
| `ts` | TEXT NOT NULL | Event time. |
| `role` | TEXT NOT NULL | Prompt role. |
| `content` | TEXT NOT NULL | Masked or original prompt text. |
| `masked` | INTEGER NOT NULL | Whether masking was applied. |

### `hx_tool_events`

| Column | Type | Meaning |
|---|---|---|
| `id` | INTEGER PRIMARY KEY | Tool event row id. |
| `session_id` | TEXT NOT NULL, FK | Owning `hx_sessions` row; cascades on session deletion. |
| `ts` | TEXT NOT NULL | Event time. |
| `tool` | TEXT NOT NULL | Tool name. |
| `status` | TEXT NOT NULL | Tool outcome status. |
| `duration_ms` | INTEGER | Elapsed milliseconds. |
| `exit_code` | INTEGER | Process exit code when applicable. |
| `error_summary` | TEXT | Redacted failure summary. |

### `hx_skill_runs`

| Column | Type | Meaning |
|---|---|---|
| `id` | INTEGER PRIMARY KEY | Skill run row id. |
| `session_id` | TEXT NOT NULL, FK | Owning `hx_sessions` row; cascades on session deletion. |
| `ts` | TEXT NOT NULL | Run time. |
| `skill_name` | TEXT NOT NULL | Activated skill name. |
| `scope` | TEXT NOT NULL | Company, project, or personal scope. |
| `outcome` | TEXT NOT NULL | Run outcome. |
| `corrected` | INTEGER NOT NULL | Whether a later user correction was detected. |

### `hx_patterns`

| Column | Type | Meaning |
|---|---|---|
| `id` | INTEGER PRIMARY KEY | Pattern row id. |
| `detected_at` | TEXT NOT NULL | Detection time. |
| `cluster_key` | TEXT NOT NULL | Stable grouping key. |
| `template` | TEXT NOT NULL | Generalized pattern text. |
| `freq` | INTEGER NOT NULL | Observed frequency. |
| `fail_rate` | REAL NOT NULL | Failure ratio. |
| `avg_duration_ms` | REAL NOT NULL | Mean duration in milliseconds. |
| `score` | REAL NOT NULL | Candidate priority score. |
| `artefact_kind` | TEXT | Proposed artefact class. |
| `state` | TEXT NOT NULL | Candidate lifecycle state. |
| `reason` | TEXT | State rationale. |

### `hx_audit`

| Column | Type | Meaning |
|---|---|---|
| `id` | INTEGER PRIMARY KEY | Audit row id. |
| `ts` | TEXT NOT NULL | Event time. |
| `actor` | TEXT NOT NULL | Event actor. |
| `event` | TEXT NOT NULL | Audit event name. |
| `ref` | TEXT | Related object reference. |
| `detail` | TEXT | Redacted event detail. |

`hx_audit_no_update` and `hx_audit_no_delete` abort UPDATE and DELETE, making rows append-only.

## Full-text indexes

### `hx_prompts_fts`

FTS5 external-content index over `hx_prompts.content`, keyed by `hx_prompts.id`. The `hx_prompts_fts_ai`, `hx_prompts_fts_ad`, and `hx_prompts_fts_au` triggers synchronize inserts, deletes, and updates.

### `hx_skill_runs_fts`

FTS5 external-content index over `hx_skill_runs.skill_name` and `hx_skill_runs.outcome`, keyed by `hx_skill_runs.id`. The `hx_skill_runs_fts_ai`, `hx_skill_runs_fts_ad`, and `hx_skill_runs_fts_au` triggers synchronize inserts, deletes, and updates.

Primary keys provide the only B-tree indexes in migration 0001. Additional indexes require workload evidence from P1-F1-T5.
