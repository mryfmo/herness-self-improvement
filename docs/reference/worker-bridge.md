---
owner: harness-operators
last-verified: 2026-07-19
freshness: 90d
---

# Worker bridge

`bin/hx-agmsg-adapter.sh` makes the task ledger the entry point for AGMSG task
handoffs. `bin/hx-worker.sh` starts one Codex worker with repository-scoped
write access and records its session. Orchestrators must use the adapter for
future task assignment, result, revision, and acceptance messages instead of
calling AGMSG `send.sh` directly.

## Adapter

Set the routing values once, or pass the equivalent `--team`, `--from`, and
`--to` options before the subcommand:

```sh
export HX_AGMSG_TEAM=herness-self-improvement
export HX_AGMSG_FROM=orchestrator-agent
export HX_AGMSG_TO=worker-agent
```

The adapter uses the AGMSG `messages.db` as the default ledger location.
`HX_DB_PATH` selects another migrated database, which is useful for isolated
validation.

Assign a task:

```sh
bin/hx-agmsg-adapter.sh assign a024 P1-F2-T5 \
  a024/example-branch "required checks pass" \
  .orchestration/tasks/a024-example.md
```

The command prints the internal `hx_tasks.task_id`. Assignment first calls
`db/hx-task.sh create` with `a024` as its idempotency key. Only after that
write succeeds does it deliver `AGMSG-TASK` with the existing AGMSG
`send.sh`. Repeating the command reuses the ledger row; AGMSG delivery is
at-least-once so an orchestrator can retry after an uncertain delivery.

Record the worker result, request a revision, accept it, or record a blocking
error:

```sh
bin/hx-agmsg-adapter.sh result a024 ready_for_review \
  report=.orchestration/reports/a024-report.md \
  validation=.orchestration/validation/a024-validation.md
bin/hx-agmsg-adapter.sh accept a024 revise "add the missing assertion"
bin/hx-agmsg-adapter.sh accept a024 accepted "all checks passed"
bin/hx-agmsg-adapter.sh error a024 "operator kill switch active"
```

The public task ID, such as `a024`, is used by adapter commands and AGMSG.
The generated `hx-...` ID is used by the worker launcher's `--task-id`
option.

## Protocol mapping

| Adapter command | Ledger operation | AGMSG message |
| --- | --- | --- |
| `assign` | `create` → `task.assign` | `AGMSG-TASK` |
| `result` | `progress` with review payload | `AGMSG-RESULT` |
| `accept ... accepted` | `done` → `task.result` | `AGMSG-ACCEPTANCE` |
| `accept ... revise` | `progress` with revision payload | `AGMSG-ACCEPTANCE` |
| `error` | `block` → `task.error` | blocked `AGMSG-RESULT` |

This order is fail-closed at assignment: a ledger creation failure cannot
produce a task message. The adapter does not reimplement AGMSG persistence.

## Worker launcher

Inspect checks and the exact planned command without changing the ledger or
starting Codex:

```sh
bin/hx-worker.sh --dry-run /path/to/repository \
  "Check your agmsg inbox and process the assigned task."
```

Launch a ledger-backed worker:

```sh
bin/hx-worker.sh --task-id hx-0123456789abcdef --owner worker-agent \
  /path/to/repository \
  "Check your agmsg inbox and process the assigned task."
```

The launcher refuses repositories without `AGENTS.md`. It invokes Codex with
`--sandbox workspace-write`, `--ask-for-approval on-request`, the repository
as `--cd`, and `exec --ignore-user-config --ephemeral`. Together these flags
limit writable workspace scope to the selected worktree while retaining
approval prompts for actions outside that sandbox.

At launch, the wrapper claims and starts the optional ledger task, then
inserts an `agent_type=codex` row in `hx_sessions`. On process exit it records
`ended_at` and a `completed` or `failed` status. Result and acceptance
transitions remain adapter operations.

## Kill switch

Creating the flag below prevents both dry-run approval and worker launch:

```sh
mkdir -p "$HOME/.agents/hx"
touch "$HOME/.agents/hx/kill-switch"
```

Remove the file only after the operator has decided launches may resume.
The current control is file-based; F8-T3 is reserved for a DB-backed flag.

## Orchestrator procedure

1. Write the task file and call adapter `assign`; retain its printed internal
   ledger ID.
2. Pass that internal ID to `hx-worker.sh --task-id`.
3. On `AGMSG-RESULT`, call adapter `result` with every artifact path.
4. Call adapter `accept ... revise` for another iteration, or
   `accept ... accepted` after review.
5. Call adapter `error` when the task must become blocked.

Direct task handoffs through AGMSG bypass the ledger and are not part of this
workflow.
