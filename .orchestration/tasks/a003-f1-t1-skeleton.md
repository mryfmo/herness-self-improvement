# Task a003: P1-F1-T1 ハーネスリポジトリ骨格作成

- task_id: a003
- repo: /Users/mryfmo/Workspace/herness-self-improvement
- issued: 2026-07-18
- orchestrator: claude-fable5high-herness
- worker: codex-gpt56solhigh-herness
- max_turns: 4
- 根拠: WORKPLAN v1.1 P1-F1-T1 / SPEC 5.1
- 前提: a002(F1-T0)受入済みであること。以後の変更はすべて PR 経由。

## Objective

SPEC 5.1 のコンポーネント構成どおりのディレクトリ骨格と README、保護ブランチ設定手順書を作成し、PR でマージする。

## 作成物

1. ディレクトリ骨格(空ディレクトリは `.gitkeep`、各トップに 1 行 README 可):
   - `docs/decisions/` `docs/plans/` `docs/specs/` `docs/reference/` `docs/lessons/`(a002 で一部存在済み。欠けを補完)
   - `.claude/skills/` `.claude/agents/` `.claude/hooks/` `.claude/commands/`
   - `ci/`
2. `README.md`(リポジトリルート): 本リポジトリの目的(自己改善ハーネス基盤)、4 文書への docs/ リンク、SPEC 5.1 構成図の要約、単独運用と敵対的検証の運用注記。120 行以内。
3. `docs/reference/branch-protection.md`: a002 で適用した保護設定の再現手順(gh api コマンド)と設定値の根拠(Decision Log #2)。
4. CI(`.github/workflows/ci.yml`)を拡張: 骨格存在検査(上記ディレクトリの存在)を追加。既存チェックは維持。

## Allowed files

上記作成物と、そのための PR ブランチ操作。`.orchestration/` は reports/validation/sandboxes/learning/autoskill の a003 ファイルのみ。

## Forbidden actions

- 4 文書(docs/ 配下の WORKPLAN/SPEC/REPORT/ADR)の変更
- 保護設定の変更、force-push、main への直接 push
- 依存パッケージ追加、他リポジトリ操作

## Validation

```sh
tree -a -I '.git' -L 3   # SPEC 5.1 との一致を目視対応表で示す
gh pr checks <PR番号>     # ci green
wc -l README.md           # ≤ 120
```

## Expected artifacts

- report: `.orchestration/reports/a003-report.md`(PR URL、SPEC 5.1 との対応表)
- validation: `.orchestration/validation/a003-validation.md`
- sandbox: `.orchestration/sandboxes/a003-sandbox.md`
- learning: `.orchestration/learning/a003-learning.md`
- autoskill: `.orchestration/autoskill/runs/a003-autoskill.md`

## Done signal

`AGMSG-RESULT v1 task_id=a003 status=ready_for_review report=... validation=... sandbox=... learning=... autoskill=...`
