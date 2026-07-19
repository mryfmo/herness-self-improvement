# Task a016: 監査所見の実装修正(A014-17 / A014-04 / A014-03 文書部分)

- task_id: a016
- repo: /Users/mryfmo/Workspace/herness-self-improvement
- issued: 2026-07-19
- orchestrator: claude-fable5high-herness
- worker: codex-gpt56solhigh-herness
- max_turns: 3
- 前提: a015 受入済み。全変更は PR 経由。外部 Web 取得禁止(GitHub 操作許可)。
- 根拠: a014 監査所見(.orchestration/reports/a014-report.md — 本タスクでは読取り可)

## Objective(1 PR)

1. **A014-17(バグ修正)**: `db/migrate.sh status` を全マイグレーション(0001, 0002、今後の追加分も自動対応)の適用状態表示に拡張。未適用が 1 本でもあれば非ゼロ終了。`ci/test_migrations.sh` / `ci/test_task_ledger.sh` の期待値を更新し、「0002 のみ欠落」ケースの検出を新規テストとして追加(worker の再現手順: scratch DB で 0002 entry/table 除去 → status が欠落を報告し非ゼロであること)。
2. **A014-04(凍結対象拡大)**: `ci/frozen-paths.txt` に `docs/decisions/` と `docs/specs/discipline-v1.0.md` を追加し、マニフェストを更新。ADR 群と規律定義が L3 凍結対象になる。
3. **A014-03(表現訂正)**: `docs/reference/evidence-and-gates.md` の hash-freeze 説明を「変更権限の機械的強制」から「**変更の強制可視化**(凍結対象の変更はマニフェスト更新を伴う明示的 diff としてレビューに必ず現れる)+ 人間承認(NFR-01)が権限の実体。トラストルートを checkout 外(サーバー側保護 or 署名)へ移す件はユーザー決裁 D1 待ち」へ訂正。ADR-0006/0008 本文は変更しない(a017 で SPEC 側から整合)。

## Allowed files

`db/migrate.sh`、`ci/test_migrations.sh`、`ci/test_task_ledger.sh`、`ci/frozen-paths.txt`、`ci/frozen-manifest.json`、`docs/reference/evidence-and-gates.md`、`.github/workflows/ci.yml`(必要時)、PR ブランチ操作、`.orchestration/` の a016 5 artifact。

## Forbidden actions

- 4 文書・ADR 群・規律文書の変更、外部 Web 取得、保護/フック変更、依存追加、force-push、main 直接 push、実運用 agmsg DB

## Validation

```sh
ci/test_migrations.sh && ci/test_task_ledger.sh
# A014-17 再現ケース: 0002 欠落 DB で migrate.sh status が欠落報告 + 非ゼロ
python3 ci/hash-freeze.py verify   # docs/decisions/ を含む新マニフェストで
python3 ci/check-docs.py
gh pr checks <PR番号>
```

## Done signal

`AGMSG-RESULT v1 task_id=a016 status=ready_for_review report=.orchestration/reports/a016-report.md validation=.orchestration/validation/a016-validation.md sandbox=.orchestration/sandboxes/a016-sandbox.md learning=.orchestration/learning/a016-learning.md autoskill=.orchestration/autoskill/runs/a016-autoskill.md`
