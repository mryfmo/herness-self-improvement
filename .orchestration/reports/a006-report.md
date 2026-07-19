# a006 P1-F1-T4 Task Ledger Report

## Status

ready_for_review

## Result

- Pull request: https://github.com/mryfmo/herness-self-improvement/pull/5
- Squash merge: `603d784440bbf6d60874d2d352fe0a1e12476e66`
- Branch: `f1-t4/task-ledger`（merge 後に削除）

## Implementation choice

SQLite の CHECK、UNIQUE、foreign key、単一 state-transition trigger を状態機械の信頼境界にした。CLI は POSIX shell と sqlite3 だけで入力検証、SQL quote、`BEGIN IMMEDIATE`、条件付き更新、message 追記を行う。追加 dependency や汎用 migration framework は作っていない。

CLI contract は `create <idempotency-key> <workplan-ref> <branch> <done-criteria> [max-attempts]`、`claim <task-id> <owner>`、`start <task-id>`、`progress|done|fail|block <task-id> <payload>`、`requeue <task-id> [timeout-minutes]`、`show <task-id>`、`list` とした。

## Completed procedure

1. 先行 test を作り、`db/hx-task.sh` 不在で失敗することを確認した。
2. migration 0002 に `hx_tasks`、`hx_task_messages`、2 indexes、状態遷移 trigger を追加した。
3. migration runner を0001→0002の up、0002→0001の downへ最小拡張し、既存 status contract を維持した。
4. create は unique idempotency key の conflict 時に既存 task_id を返し、task/messageを重複作成しないよう実装した。
5. queued→claimed→running→done|failed|blocked と、claimed/running timeout requeue を transaction で実装した。
6. requeue は attempts を増加し、新値が max_attempts 以下なら queued、超えたら fixed failed にする。
7. system temporary database test で全正常パス、不正遷移、冪等性、SQL quote、requeue 上限、必須値、up/down、文書 parity を検証した。
8. schema reference と CI step を更新し、`57dc56d feat(db): add task ledger state machine`（`Agent: worker`）を PR #5 で squash mergeした。

## Judgment

P1-F1-T4 と SPEC 5.3 の状態機械、冪等 create、必須作業指示、15分既定 timeout、attempts 上限を依存なしで満たした。実運用 agmsg DB、禁止された4文書、protection/hooks、dependencies、他 repository は変更していない。
