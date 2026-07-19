# Task a017: SPEC v1.1 — 三軸統合と監査所見の根本修正

- task_id: a017
- repo: /Users/mryfmo/Workspace/herness-self-improvement
- issued: 2026-07-19
- orchestrator: claude-fable5high-herness
- worker: codex-gpt56solhigh-herness
- max_turns: 5
- 前提: a016 受入済み。全変更は PR 経由。外部 Web 取得禁止(GitHub 操作許可)。
- 入力: docs/specs/SPEC…v1.0.md(改訂元)、.orchestration/reports/a014-report.md、.orchestration/acceptance/a014-acceptance.md(統合所見)、ADR-0007/0008、discipline-v1.0.md

## Objective(1 PR)

1. `docs/specs/SPEC-HARNESS-SELF-IMPROVEMENT-v1.1.md` を新規作成(v1.0 の全構造を保持した改訂版。frontmatter 付与)。
2. v1.0 の Status に「Superseded by SPEC-HARNESS-SELF-IMPROVEMENT-v1.1.md」1 行のみ追記(WORKPLAN v1.0 の前例と同形式。他は不変)。
3. `ci/docs-frontmatter-exempt.txt` から v1.1 は対象外のまま(新文書は frontmatter あり)。v1.0 は免除継続。

## v1.1 改訂内容(番号は監査所見 ID)

**保持原則**: v1.0 の FR-01〜13 / NFR-01〜08 の番号と趣旨を保持(削除・改番禁止)。修正は本文注記・追記・新番号追加で行う。

1. **Status/前提**: 版 v1.1、改訂根拠(三軸統合 = mryfmo 指示 2026-07-19、監査所見 24 件)。関連文書に discipline-v1.0.md と docs/decisions/README.md を追加。ADR 参照はすべて新番号(旧呼称併記)へ(A014-12)。
2. **Assumptions**:
   - A-4 改訂(A014-02): サーバー側保護が使えない環境(GitHub Free private で 403 実証済み)では、代償統制(コミット済み pre-push hook + PR/CI 運用 + hash-freeze 可視化)で暫定充足。恒久形態は決裁 D1(Pro 化/public 化/受容)待ちであることを明記。
   - A-5 改訂(A014-11): AIDD 3 部品は再利用不能と実証済み。独立最小再実装(docs/reference/evidence-and-gates.md)を正とする。
   - A-7: WORKPLAN v1.1 Decision Log の確定値(GitHub private mryfmo/herness-self-improvement、mryfmo 単独全ロール)を反映。
3. **FR 修正・追加**:
   - FR-03(A014-13): 「一括再生成による更新を CI が拒否」を「diff 比率閾値(既定 40%、L3 所有設定)超の一括更新は自動マージ不可・mryfmo 承認へ格上げ(ADR-0003)」に統一。
   - FR-14 新設(ADR-0007): 最適化・昇格・削除のすべての自動決定は、接地指標(実行された eval/テスト、人間のマージ/却下/訂正、実データ件数)を最低 1 つ入力に含むこと。派生指標(集計統計、LLM 評価)単独の決定は禁止。全駆動指標は対抗指標とペアで定義。
   - FR-15 新設(ADR-0008): 再帰階層 L0〜L3 を強制。L2(改善機構自体)の変更はメタ指標駆動 + mryfmo 承認 + カナリア(次周期悪化で自動ロールバック提案)+ 1 ループ 1 変更/周期。L3 は人間専有。自動提案による自己制約(上限・閾値・承認要件)の緩和禁止。
   - FR-16 新設(ADR-0007 原則 6): 月次監査は循環検査(各最適化決定の接地依拠の検証、派生単独決定の違反報告)を含むこと。
4. **NFR 修正**:
   - NFR-01(A014-10/01): 対象を L3 全域(ゲート・CI 定義・Hooks 設定・kill switch・ADR 群・凍結マニフェスト・階層定義・L3 所有設定ファイル)に拡大。「人間承認」= mryfmo。**建設期例外**: F9 受入前は mryfmo のセッションレベル指示(自律完遂指示 2026-07-18)に基づき orchestrator の敵対的検証 + マージを暫定承認とし、F9-T7 運用移行で mryfmo の PR 単位承認に切替える(決裁 D2 として承認待ちを明記)。
   - NFR-02(A3): worker 隔離の実体 = ワークツリー限定書込み + 許可リストネットワーク + 起動ラッパー検証。OS レベル隔離の実体は F4-T4 実装時に確定(Open 事項として明記)。
5. **5.2 データフロー(A4)**: 体験ログの記録範囲 = orchestrator セッション(Hooks 経由)+ worker 実行(F2-T4 起動ラッパー経由)の双方と明記。
6. **5.3 連携プロトコル(A014-16/19)**: AGMSG-TASK / AGMSG-RESULT / AGMSG-ACCEPTANCE / AGMSG-PING / AGMSG-PONG(v1 契約)をオーケストレーション層の正とし、v1.0 のメッセージ種別との対応写像表(task.assign→AGMSG-TASK + 台帳 create、task.result→AGMSG-RESULT、承認 →ACCEPTANCE + done/failed 遷移、ctrl.\*→ 維持)を追加。hx_tasks 台帳との接続は F2-T4 ラッパーの責務と明記。「直接 push 禁止」の定義 = main への push 禁止。feature branch push + PR は worker の正規経路。
7. **6.2 F-ROUTE(A014-07)**: SkillCoach 型ルーブリック(LLM 評価 = 派生指標)は、接地指標とペアの場合に限り F-OPT の入力にできる(FR-14 参照)と修正。
8. **6.5 F-GOV**: (7) 監査に循環検査(FR-16)を追加。hash-freeze の性格を「変更の強制可視化 + 人間承認が権限の実体」(a016 の訂正と整合)と記載。
9. **8 章 ADR 一覧**: ADR-0001〜0008(旧呼称 H001〜H006 併記、0007/0008 は 2026-07-19 Accepted)へ更新し、docs/decisions/README.md への参照にする。

## 検証(validation に記録)

```sh
# FR/NFR 番号保持: v1.0 の FR-01..13 / NFR-01..08 が v1.1 に全存在、追加は FR-14..16 のみ
grep -o 'FR-[0-9]*' の diff 比較
python3 ci/check-docs.py
python3 ci/hash-freeze.py verify
v1.0 の diff が Superseded 1 行のみであることを git diff で実証
gh pr checks <PR番号>
```

## Allowed files

`docs/specs/SPEC-HARNESS-SELF-IMPROVEMENT-v1.1.md`(新規)、`docs/specs/SPEC-HARNESS-SELF-IMPROVEMENT-v1.0.md`(1 行のみ)、`ci/docs-frontmatter-exempt.txt`(必要時)、PR ブランチ操作、`.orchestration/` の a017 5 artifact。

## Forbidden actions

- v1.0 本文変更(1 行追記以外)、WORKPLAN/REPORT/ADR/規律文書の変更、外部 Web 取得、保護/フック変更、依存追加、force-push、main 直接 push

## Done signal

`AGMSG-RESULT v1 task_id=a017 status=ready_for_review report=.orchestration/reports/a017-report.md validation=.orchestration/validation/a017-validation.md sandbox=.orchestration/sandboxes/a017-sandbox.md learning=.orchestration/learning/a017-learning.md autoskill=.orchestration/autoskill/runs/a017-autoskill.md`
