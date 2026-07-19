---
owner: mryfmo
last-verified: 2026-07-18
freshness: 90d
---

# Telemetry schema

## Scope

The harness experience layer uses an injected SQLite database path. Every extension object uses the `hx_` namespace. Based on the P1-F1-T5 load test, v1 provisionally shares the live agmsg database under decision D3; final human approval remains pending. Set `HX_DB_PATH` to use another database for tests or a later deployment change.

Run `db/migrate.sh up|down|status <db-path>`. The wrapper enables WAL and a 5,000 ms busy timeout; up/down connections also enable foreign keys. Applications must enable foreign keys on their own SQLite connections.

Timestamps are ISO 8601 text. Boolean fields are integers constrained to `0` or `1`.

## Lifecycle hooks

Project settings register `.claude/hooks/hx-telemetry.sh` for `SessionStart`, `UserPromptSubmit`, `PostToolUse`, `Stop`, and `SubagentStop`. The hook copies its JSON input and starts the SQLite writer in the background, so the calling hook exits without waiting for the insert. Project settings take effect at the next Claude session start; live-session measurement belongs to the P1-F2-T7 dry run.

The default database path comes from the agmsg `agmsg_db_path` storage resolver. `HX_DB_PATH` overrides it. Before applying migrations to the live database, create and hash a SQLite `.backup`.

Prompt content is checked against the same patterns as `ci/secret-scan.py`. Each match is replaced with `[REDACTED:<rule>]`; `hx_prompts.masked` is `1` when at least one replacement occurred.

`PostToolUse` writes the tool name and a normalized `success` or `failure` status to `hx_tool_events`. Duration and exit code are stored when the hook payload provides them. A supplied stderr or error value is masked and limited to 200 characters before storage. `Stop` sets the session status to `completed` and records `ended_at`, inserting a completed session when no start row exists. `SubagentStop` reuses `hx_tool_events` with `tool='subagent'` and `status='success'`; no dedicated subagent table is needed.

When `PostToolUse.tool_name` is exactly `Skill`, the hook also writes `tool_input.skill`, the supplied scope or `unknown`, and the normalized outcome to `hx_skill_runs`. On a later prompt, regular expressions from `.claude/hooks/hx-correction-markers.txt` identify possible corrections. The most recent skill run in the same session is marked `corrected=1` when it falls within 15 minutes; `HX_CORRECTION_WINDOW_MIN` sets another non-negative window.

Correction detection is intentionally a keyword heuristic. It can miss indirect corrections and can flag ordinary uses of a marker. F2-T7 will measure false positives on 30 real samples before the marker list or approach is made more complex.

Insert and input failures do not fail the hook. They append a redacted event line to `~/.agents/hx/telemetry-failures.log`. The next successful insert records `telemetry.failures.recovered` in `hx_audit` with the accumulated failure count, then clears the file.

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
| `scope` | TEXT NOT NULL | Company, project, user, or other supplied scope; `unknown` when unavailable. |
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

## Daily reconciliation

Run `ci/hx-reconcile.sh <db-path> [--date YYYY-MM-DD]` to compare one UTC
day of source rows with its audit snapshot. The date defaults to the current
UTC day. The first run appends `event=telemetry.reconcile` with the counts
below. A later run with different counts appends
`event=telemetry.reconcile.mismatch` and exits nonzero. Repeating the same
mismatch does not append another row.

| Count | Source |
|---|---|
| `session_start` / `stop` | `hx_sessions.started_at` / `ended_at` |
| `prompt_submit` | `hx_prompts.ts` |
| `post_tool_use` / `subagent_stop` | `hx_tool_events.ts`, split by `tool='subagent'` |
| `skill_run` / `correction` | `hx_skill_runs.ts`; corrected runs use the original run date because correction time is not stored |
| `metrics_daily` | `hx_audit` rows with `event=metrics.daily` and `ref=<date>` |
| `failures_recovered` | `hx_audit` rows with `event=telemetry.failures.recovered` |
| `task_rows` / `task_messages` | `hx_tasks.updated_at` / `hx_task_messages.ts` |

GitHub Actions runs `ci/test_reconcile.sh` against synthetic data only. The
live database is local and is not available to a hosted runner. F3-T3 must
schedule the live command in its local nightly job under the kill switch.

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
