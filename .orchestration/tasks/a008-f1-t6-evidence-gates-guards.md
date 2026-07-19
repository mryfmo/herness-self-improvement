# Task a008: P1-F1-T6 evidence store / closed gates / data guards 組込み

- task_id: a008
- repo: /Users/mryfmo/Workspace/herness-self-improvement
- issued: 2026-07-19
- orchestrator: claude-fable5high-herness
- worker: codex-gpt56solhigh-herness
- max_turns: 4
- 根拠: WORKPLAN v1.1 P1-F1-T6(FR-12 土台)
- 前提: a007 受入済み。全変更は PR 経由。依存追加禁止。

## 重要な前提修正(orchestrator 調査 2026-07-19)

SPEC Assumption A-5「AIDD の closed gates / data guards / evidence store は型付きコードとして再利用可能」は実態と不一致。ai-ops-platform に該当する再利用可能なパッケージ三点は存在せず、近縁部品は TypeScript の `packages/shared/src/auditLog.ts` と `secretSanitizer.ts` のみ(pnpm/Node 前提で本リポジトリの依存ゼロ方針と不整合)。
よって本タスクは**同等機能の最小再実装**とし、A-5 の修正を成果物内に明記する。ai-ops-platform のコードは**読み取り参照のみ可**(設計・マスキングパターンの参考)。コピーは不可(ライセンス・保守二重化回避)。

## Objective

3 部品を sh/python3 stdlib で最小実装し、CI と将来の Hooks から呼べる形で PR マージする。

1. **evidence store**: 既存 `hx_audit`(append-only、a005)を評価ストアとして正式採用。書込み口 `db/hx-evidence.sh <db-path> record <actor> <event> <ref> <detail-json>` と読出し `list|trace <ref>` を実装。
2. **closed gate(SHA-256 凍結)**: `ci/hash-freeze.py` — 対象パスリスト(設定ファイル `ci/frozen-paths.txt`: 当面 `githooks/ ci/ db/ .github/workflows/`)のマニフェスト `ci/frozen-manifest.json` を生成(`freeze`)/照合(`verify`)。CI に verify を追加し、凍結対象の変更はマニフェスト更新を伴わない限り fail(= 変更が明示的な差分としてレビューに現れる)。
3. **data guard(秘密情報検出)**: `ci/secret-scan.py` — secretSanitizer.ts のパターンを参考に、API キー・トークン・秘密鍵ヘッダ等の正規表現群でリポジトリ走査(binary/`.git` 除外、許容リスト `ci/secret-allowlist.txt`)。CI に追加。検出時 fail。

- テスト: `ci/test_evidence_gates.sh` — (a) evidence record→trace 往復、(b) 凍結対象改変で verify fail → マニフェスト更新で pass、(c) 秘密サンプル(無害なダミー)検出、許容リスト適用。CI 登録。
- 文書: `docs/reference/evidence-and-gates.md`(frontmatter 付き): 3 部品の呼出し口、A-5 前提修正の経緯、AIDD 参照元(パス)を記録。
- learning artifact に「A-5 は再実装で充足、SPEC 改訂時に修正要」を必ず記録(SPEC 本文は変更禁止のまま)。

## Allowed files

`db/hx-evidence.sh`、`ci/`(上記新規 + ci.yml ステップ追加)、`docs/reference/evidence-and-gates.md`、PR ブランチ操作、`.orchestration/` の a008 5 artifact。ai-ops-platform は読み取りのみ。

## Forbidden actions

- ai-ops-platform のコードコピー・変更、実運用 agmsg DB への書込み、docs/ 4 文書変更、保護/フック変更、依存追加、force-push、main 直接 push

## Validation

```sh
ci/test_evidence_gates.sh
ci/hash-freeze.py verify && echo FROZEN-OK
ci/secret-scan.py && echo NO-SECRETS
gh pr checks <PR番号>
```

## Expected artifacts

- report / validation / sandbox / learning / autoskill: `.orchestration/{reports,validation,sandboxes,learning,autoskill/runs}/a008-*.md`

## Done signal

`AGMSG-RESULT v1 task_id=a008 status=ready_for_review report=... validation=... sandbox=... learning=... autoskill=...`
