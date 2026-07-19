# Task a002: P1-F1-T0 リポジトリブートストラップ

- task_id: a002
- repo: /Users/mryfmo/Workspace/herness-self-improvement
- issued: 2026-07-18
- orchestrator: claude-fable5high-herness
- worker: codex-gpt56solhigh-herness
- max_turns: 5
- 根拠: WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.1.md の P1-F1-T0(Decision Log #2/#5 決裁済み)

## Objective

本ディレクトリをハーネスリポジトリとして本体化する。完了条件は v1.1 P1-F1-T0 のとおり:
「初回 PR がフロー経由でマージされ、以後全変更が PR 駆動になる」。

## 手順(この順で)

1. `.gitignore` を作成: `.codex/`、`.claude/settings.local.json`、`/tmp` 系生成物。`.orchestration/` と `.agents/` は**コミット対象**(プロセス証跡)。
2. `git init`(ブランチ名 main)→ 全対象ファイルを初回コミット。コミットメッセージは Conventional Commits(`chore: bootstrap harness repository (P1-F1-T0)`)+ トレーラー `Agent: worker`。
3. `gh repo create mryfmo/herness-self-improvement --private --source . --push`。
4. 最小 CI を追加: `.github/workflows/ci.yml`(ジョブ名 `ci`。当面はリンク存在検査 — 移設後 4 文書が `docs/` 配下に存在することを確認する程度の高速チェックで可)。main へ push(保護設定前なので直接 push 可)。
5. main 保護を設定(`gh api` 使用): PR 必須、required status check `ci`、force-push/削除禁止。**required approving reviews は 0**(単独運用のため。人間レビューの代替はオーケストレーター敵対的検証である旨を README または docs に 1 行記録)。
6. ブランチ `f1-t0/docs-move` を作成し、4 文書を移設:
   - WORKPLAN v1.0 / v1.1 → `docs/plans/`
   - SPEC → `docs/specs/`
   - REPORT → `docs/reference/`
   - ADR 束 → `docs/decisions/`(分割は F1-T8 で実施、ここでは移設のみ)
7. 4 文書内の相互参照(ファイル名記述)を新パスに更新。`.orchestration/tasks/` 内の既存タスクファイルは変更しない。
8. PR 作成(本文末尾に指定フッター、`Agent: worker` トレーラー)→ CI green を確認 → `gh pr merge --squash` でマージ → ローカル main を更新。
9. 保護の実効性を実証: main への直接 push を試行し、**拒否されること**を確認(出力を validation に記録)。

## Allowed files

リポジトリ全域の新規作成・移設・git 操作を許可。ただし以下は変更禁止:

- `.orchestration/tasks/`(orchestrator 管理)
- `.orchestration/acceptance/`(orchestrator 管理)
- 4 文書の**内容**(相互参照パスの更新を除き、本文を変更しない)

## Forbidden actions

- force-push、履歴改変、リポジトリ削除・公開化(public 化)
- GitHub 上の mryfmo/herness-self-improvement 以外のリポジトリへの操作
- 依存パッケージの追加
- 4 文書の本文変更(パス参照更新以外)

## Validation(出力を validation ファイルに記録)

```sh
git log --oneline
gh repo view mryfmo/herness-self-improvement --json visibility,defaultBranchRef
gh api repos/mryfmo/herness-self-improvement/branches/main/protection | jq '{required_status_checks:.required_status_checks.contexts, reviews:.required_pull_request_reviews.required_approving_review_count, force:.allow_force_pushes.enabled}'
# 直接 push 拒否の実証(拒否されるのが期待値)
git push origin HEAD:main 2>&1 | tail -5   # docs-move マージ後、ダミー変更で試行
ls docs/plans docs/specs docs/reference docs/decisions
grep -rn 'HARNESS-SELF-IMPROVEMENT-v1' docs/ --include='*.md' -l
```

## Expected artifacts

- report: `.orchestration/reports/a002-report.md`(実施手順・PR URL・判断点)
- validation: `.orchestration/validation/a002-validation.md`
- sandbox: `.orchestration/sandboxes/a002-sandbox.md`(network=GitHub のみ使用の記録)
- learning: `.orchestration/learning/a002-learning.md`
- autoskill: `.orchestration/autoskill/runs/a002-autoskill.md`

## Done signal

`AGMSG-RESULT v1 task_id=a002 status=ready_for_review report=... validation=... sandbox=... learning=... autoskill=...`
ブロック時(gh 権限不足等)は status=blocked + report に詳細。

---

## 補遺 r1(orchestrator、2026-07-18): ブランチ保護不可への対応

GitHub Free の private リポジトリでは branch protection / rulesets が利用不可(403 実証済み)。
プラン変更・public 化はユーザー決裁事項のため、本タスクは以下の**修正手順**で完遂する:

- 手順 5(サーバー側保護)は**スキップ**。代わりに代償統制を実装:
  1. `githooks/pre-push` を作成: push 先 ref が `refs/heads/main` の場合、環境変数 `ALLOW_MAIN_PUSH=1` がない限り exit 1 でブロック(メッセージで PR フローへ誘導)。
  2. `git config core.hooksPath githooks` を設定し、README にセットアップ手順として 1 行記載。
  3. `docs/reference/branch-protection.md` を新規作成: 403 の事実、代償統制の内容、サーバー側保護へ移行する際の gh api 手順(validation に記録済みの PUT コマンド)を記載。「サーバー側保護の有効化はユーザー決裁(Pro 化 or public 化)待ち」と明記。
- 手順 6〜8(docs 移設ブランチ → PR → CI green → squash merge)は予定どおり実施。githooks/README/branch-protection.md も同 PR に含めてよい。
- 手順 9(直接 push 拒否の実証)は**ローカル hook で実証**: `ALLOW_MAIN_PUSH` なしの `git push origin HEAD:main` が hook で拒否されることを記録。マージ後の main 更新 push は `ALLOW_MAIN_PUSH=1` で行う(PR マージ自体は GitHub 側で完結するため通常不要)。
- 完了条件の読み替え: 「以後全変更が PR 駆動になる」= PR フロー + ローカル pre-push ガード + CI。サーバー側強制は決裁後に F1-T9 までに再評価。
