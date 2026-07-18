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

Applied versions are `0001_telemetry` and `0002_ledger`. Up runs in that order; down reverses the order.

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

## Task ledger

Use `db/hx-task.sh <db-path> <subcommand>`. `create` requires an idempotency key, WORKPLAN task id, branch, and quoted completion criteria. `requeue` uses a 15-minute timeout unless the caller supplies another non-negative minute value.

### `hx_tasks`

| Column | Type | Meaning |
|---|---|---|
| `task_id` | TEXT PRIMARY KEY | Generated stable task identifier. |
| `idempotency_key` | TEXT UNIQUE NOT NULL | Caller key that prevents duplicate task creation. |
| `state` | TEXT NOT NULL | `queued`, `claimed`, `running`, `done`, `failed`, or `blocked`. |
| `owner` | TEXT | Worker that claimed the task; cleared on a successful requeue. |
| `workplan_ref` | TEXT NOT NULL | WORKPLAN task id such as `P1-F1-T4`. |
| `branch` | TEXT NOT NULL | Feature branch assigned to the task. |
| `done_criteria` | TEXT NOT NULL | Completion criteria carried by the assignment. |
| `attempts` | INTEGER NOT NULL | Number of timeout requeues attempted. |
| `max_attempts` | INTEGER NOT NULL | Highest attempts value that may return to `queued`; defaults to 2. |
| `claimed_at` | TEXT | Most recent claim time; cleared on a successful requeue. |
| `updated_at` | TEXT NOT NULL | Last state or progress time used for timeout checks. |
| `detail` | TEXT | Latest progress, result, error, or timeout detail. |

`hx_tasks_state_transition` allows only `queued → claimed → running → done|failed|blocked`. A timed `claimed` or `running` task returns to `queued` with `attempts + 1`; when the new value exceeds `max_attempts`, it moves to fixed `failed`. All other state updates abort.

`hx_tasks_state_updated_idx` indexes `(state, updated_at)` for list and timeout scans. The unique constraint on `idempotency_key` and primary key on `task_id` create their own indexes.

### `hx_task_messages`

| Column | Type | Meaning |
|---|---|---|
| `id` | INTEGER PRIMARY KEY | Message row id. |
| `task_id` | TEXT NOT NULL, FK | Owning `hx_tasks` row; cascades on task deletion. |
| `ts` | TEXT NOT NULL | Message time. |
| `kind` | TEXT NOT NULL | One of the eight SPEC 5.3 task/control message kinds. |
| `payload` | TEXT NOT NULL | Assignment, owner, progress, result, error, or control detail. |

Allowed kinds are `task.assign`, `task.claim`, `task.progress`, `task.result`, `task.error`, `ctrl.pause`, `ctrl.resume`, and `ctrl.kill`. `hx_task_messages_task_ts_idx` indexes `(task_id, ts)` for ordered task history.

## Full-text indexes

### `hx_prompts_fts`

FTS5 external-content index over `hx_prompts.content`, keyed by `hx_prompts.id`. The `hx_prompts_fts_ai`, `hx_prompts_fts_ad`, and `hx_prompts_fts_au` triggers synchronize inserts, deletes, and updates.

### `hx_skill_runs_fts`

FTS5 external-content index over `hx_skill_runs.skill_name` and `hx_skill_runs.outcome`, keyed by `hx_skill_runs.id`. The `hx_skill_runs_fts_ai`, `hx_skill_runs_fts_ad`, and `hx_skill_runs_fts_au` triggers synchronize inserts, deletes, and updates.

Primary keys provide the only B-tree indexes in migration 0001. Migration 0002 adds only the two task-ledger indexes described above. Additional indexes require workload evidence from P1-F1-T5.
