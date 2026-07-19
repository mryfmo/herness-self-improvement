# Task a019: プロセス証跡(.orchestration)の PR コミット

- task_id: a019
- repo: /Users/mryfmo/Workspace/herness-self-improvement
- issued: 2026-07-19
- orchestrator: claude-fable5high-herness
- worker: codex-gpt56solhigh-herness
- max_turns: 3
- 前提: a018 受入済み、F1-T9 受入記録済み。全変更は PR 経由。外部 Web 取得禁止(GitHub 操作許可)。

## Objective

未コミットの `.orchestration/` 配下(tasks / reports / validation / acceptance / sandboxes / learning / autoskill の a001〜a019 全 artifact + f1-phase-acceptance.md + orchestrator-audit-v2-findings.md)と `.agents/worklog/` の未コミット分を 1 PR でコミット・マージし、プロセス証跡を Git 履歴に固定する。

## 要件

- 内容の書き換え禁止(そのままコミット。ただし commit 前に `python3 ci/secret-scan.py` で秘密混入なしを確認)。
- コミットメッセージ: `chore(orchestration): record process evidence a001-a019`、`Agent: worker` トレーラー。
- PR マージ後、`git status` がクリーン(本タスクの artifact 自身は次回バッチで拾う。それのみ残ることは許容し report に明記)。

## Allowed files

`.orchestration/` 全域、`.agents/worklog/` の追加、PR ブランチ操作。リポジトリの他ファイルは変更禁止。

## Validation

```sh
python3 ci/secret-scan.py
git status --short   # a019 自身の artifact 以外に未追跡なし
gh pr checks <PR番号>
```

## Done signal

`AGMSG-RESULT v1 task_id=a019 status=ready_for_review report=.orchestration/reports/a019-report.md validation=.orchestration/validation/a019-validation.md sandbox=.orchestration/sandboxes/a019-sandbox.md learning=.orchestration/learning/a019-learning.md autoskill=.orchestration/autoskill/runs/a019-autoskill.md`
