# Task a009: P1-F1-T7 Wiki 骨格と frontmatter 規約・検査 CI

- task_id: a009
- repo: /Users/mryfmo/Workspace/herness-self-improvement
- issued: 2026-07-19
- orchestrator: claude-fable5high-herness
- worker: codex-gpt56solhigh-herness
- max_turns: 4
- 根拠: WORKPLAN v1.1 P1-F1-T7(F-WIKI)
- 前提: a008 受入済み。全変更は PR 経由。依存追加禁止(python3 stdlib / POSIX sh)。

## Objective

docs/ の frontmatter 規約(owner / last-verified / freshness 必須)とテンプレート、相互リンク検査・frontmatter 検査の CI を実装し PR でマージする。

## 作成物

1. `docs/reference/wiki-conventions.md`(frontmatter 付き): 規約 — 全 docs/\*_/_.md は YAML frontmatter に `owner`(文字列)、`last-verified`(YYYY-MM-DD)、`freshness`(例 30d/90d/180d)必須。ディレクトリ責務(decisions/plans/specs/reference/lessons)。テンプレート(コピー用スニペット)。
2. `ci/check-docs.py`(python3 stdlib):
   - frontmatter 検査: 必須 3 フィールドの存在と形式(日付形式、freshness の `\d+d`)。
   - リンク検査: docs/\*_/_.md と README.md 内の相対 Markdown リンク・相対パス参照がリポジトリ内に解決すること(http(s) は対象外)。
   - 例外リスト `ci/docs-frontmatter-exempt.txt`: 移設済み 4 文書(WORKPLAN v1.0/v1.1、SPEC、REPORT、ADR 束)は本文変更禁止のため frontmatter を免除。ファイル冒頭コメントに「文書改訂時に frontmatter 付与し本リストから除去」と注記。リンク検査は 4 文書にも適用。
3. `ci/test_check_docs.py`: 一時ディレクトリで (a) 正常ケース pass、(b) frontmatter 欠落 fail、(c) 各フィールド形式不正 fail、(d) リンク切れ fail、(e) 免除リスト適用、の 5 観点。
4. `.github/workflows/ci.yml` に check-docs 実行を追加(既存チェック維持)。
5. 既存 docs/reference/\*.md(branch-protection / telemetry-schema / sqlite-load-test / evidence-and-gates)が新検査に通ること(frontmatter 不足があれば **これらは 4 文書ではないので** 追補してよい)。

## Fail 実証

CI 上での fail 実証として、リンク切れ + frontmatter 欠落を含むコミットを一時ブランチに push し、push CI が fail する Actions run URL を validation に記録(PR は作らない)。実証後ブランチ削除。

## Allowed files

`docs/reference/wiki-conventions.md`、既存 docs/reference/\*.md の frontmatter 追補、`ci/`(新規 2 + ci.yml ステップ追加 + 凍結マニフェスト更新)、PR ブランチ操作、`.orchestration/` の a009 5 artifact。

## Forbidden actions

- 4 文書の変更(免除リスト方式を使う)、保護/フック変更、依存追加、force-push、main 直接 push、実運用 agmsg DB

## Validation

```sh
python3 ci/test_check_docs.py
python3 ci/check-docs.py            # 現行リポジトリで pass
# fail 実証 run URL(push CI failure)を記録
gh pr checks <PR番号>
```

## Expected artifacts

- report / validation / sandbox / learning / autoskill: `.orchestration/{reports,validation,sandboxes,learning,autoskill/runs}/a009-*.md`

## Done signal

`AGMSG-RESULT v1 task_id=a009 status=ready_for_review report=... validation=... sandbox=... learning=... autoskill=...`
