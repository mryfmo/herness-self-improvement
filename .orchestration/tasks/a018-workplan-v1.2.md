# Task a018: WORKPLAN v1.2 — タスク契約の三軸整合と現状反映

- task_id: a018
- repo: /Users/mryfmo/Workspace/herness-self-improvement
- issued: 2026-07-19
- orchestrator: claude-fable5high-herness
- worker: codex-gpt56solhigh-herness
- max_turns: 5
- 前提: a017 受入済み(SPEC v1.1 が存在)。全変更は PR 経由。外部 Web 取得禁止(GitHub 操作許可)。
- 入力: WORKPLAN v1.1(改訂元)、SPEC v1.1、ADR-0007/0008、.orchestration/reports/a014-report.md、acceptance 群(a002〜a017)

## Objective(1 PR)

1. `docs/plans/WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.2.md` 新規作成(frontmatter 付き。v1.1 の全タスク ID・構成保持、以下の改訂)。
2. v1.1 の Status に「Superseded by WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.2.md」1 行のみ追記。
3. 前提文書参照を SPEC v1.1 / discipline / ADR 索引へ更新。

## v1.2 改訂内容(所見 ID 併記)

**保持原則**: v1.1 の全タスク ID(P1-F1-T0〜P1-F9-T7)を欠落・改番なしで保持。修正はタスク本文への要件追記と新節追加で行う。

1. **Status / Current State(A014-18)**: 状態を「F1 実施済み(T0〜T8 完了、T9 受入待ち)・改訂フェーズ完了」に更新。Current State を実状(リポジトリ稼働、PR #1〜#14+、hx スキーマ/台帳/負荷試験/evidence/gates/docs CI 稼働、ADR-0001〜0008 登録)へ書き換え。完了タスクの証跡表(タスク ID → PR 番号 → acceptance ファイル)を新設。
2. **Decision Log 追記**: 2026-07-19 の決裁(三軸統合指示 → ADR-0007/0008 Accepted、規律文書)を追加。
3. **改訂フェーズ実績の編入(A014-18/G6)**: 「追加実績(v1.1 計画外)」節を新設し a011(genealogy)〜a017(SPEC v1.1)を記録。
4. **F2-T4 拡張(A014-16)**: 起動ラッパーの要件に「AGMSG-TASK/RESULT/ACCEPTANCE ⇔ hx_tasks 台帳のアダプタ実装(SPEC v1.1 5.3 の写像表準拠)。以後の授受は台帳を唯一経路とする」を追加。
5. **F2-T5 拡張(A014-05)**: metrics.md の完了条件に「全指標をペア構造(駆動指標 + 対抗指標)で定義。各指標に接地/派生の分類、owner(mryfmo)、改訂周期を付与(FR-14)」を追加。
6. **L2 カナリア契約(A014-06)**: F3-T6・F4-T9・F6-T2 に共通要件を追記 —「プロンプト/スコア規則等 L2 の改訂は、メタ指標実測値を PR 本文に記載し、mryfmo 承認、カナリア(次周期メタ指標悪化で F6-T5 の機構によるロールバック提案)、1 ループ 1 変更/周期に従う(FR-15)」。
7. **F6-T8 修正(A014-10)**: 閾値設定ファイルは L3 所有とし、「設定変更 PR が人間専有(自動提案不可)であることの検証」を検証項目に追加。
8. **F8-T2 拡張(A014-10)**: 保護対象パスを SPEC v1.1 NFR-01 の L3 全域(ADR 群・凍結マニフェスト・階層定義・kill switch・L3 設定)に揃える。
9. **F8-T7 拡張(A014-08)**: 月次レポート要件に循環検査(FR-16: 各最適化決定の接地依拠検証、派生単独決定の違反報告)を追加。
10. **調停経路(A014-09)**: F3/F6/F7 の該当タスク(F3-T4、F6-T4、F7-T4/T5)に「ループ間衝突は conflict record を残し、orchestrator 調停提案 → mryfmo 決裁で解決(当事者ループ内で解決しない)」を追記。
11. **F9-T3 拡張(A014-15)**: 完了条件に「ci/docs-frontmatter-exempt.txt を空にする(legacy 文書への frontmatter 付与完了)」を追加。
12. **F9-T7 拡張(A014-01/D2)**: 運用移行の作業に「承認モードの切替: 建設期例外(orchestrator 検証 + マージ)を終了し、mryfmo の PR 単位承認へ移行」を追加。
13. **決裁事項表の更新**: 決裁済みに 2026-07-19 分(三軸/ADR-0007-0008)を追加。残存に D1(サーバー側保護: Pro 化/public 化/受容)、D2(建設期承認例外の追認と F9 切替)、D3(DB 同居の最終承認 — 実測済み・同居推奨・暫定採用中)を明記。#4 は D3 へ統合(A014-14)。telemetry-schema.md の deployment 記述更新は F2-T1 実装時に併せる旨を注記。

## 検証(validation に記録)

```sh
# タスク ID 完全性: v1.1 と v1.2 の P1-F\d+-T\d+ 集合が一致(追加・削除なし)
python3 ci/check-docs.py
python3 ci/hash-freeze.py verify
v1.1 の diff が Superseded 1 行のみであることを git diff で実証
gh pr checks <PR番号>
```

## Allowed files

`docs/plans/WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.2.md`(新規)、`docs/plans/WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.1.md`(1 行のみ)、`ci/docs-frontmatter-exempt.txt`(必要時)、PR ブランチ操作、`.orchestration/` の a018 5 artifact。

## Forbidden actions

- v1.1 本文変更(1 行以外)、SPEC/REPORT/ADR/規律文書の変更、外部 Web 取得、保護/フック変更、依存追加、force-push、main 直接 push

## Done signal

`AGMSG-RESULT v1 task_id=a018 status=ready_for_review report=.orchestration/reports/a018-report.md validation=.orchestration/validation/a018-validation.md sandbox=.orchestration/sandboxes/a018-sandbox.md learning=.orchestration/learning/a018-learning.md autoskill=.orchestration/autoskill/runs/a018-autoskill.md`
