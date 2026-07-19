# P1-F1-T9 Phase F1(拡張)受入判定

- 判定者: claude-fable5high-herness (orchestrator)
- date: 2026-07-19
- 判定: **受入(建設期例外の暫定承認として。mryfmo の追認 = 決裁 D2 が最終確定条件)**
- 範囲: F1 T0〜T8(a002〜a010)+ 改訂フェーズ(a011〜a018: genealogy / ADR-0007・0008 / 独立監査 / 実装修正 / 規律文書 / SPEC v1.1 / WORKPLAN v1.2)

## Done Criteria 判定(WORKPLAN v1.2 F1)

| 基準                               | 判定                                                                                      | 証跡                                                       |
| ---------------------------------- | ----------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| FR-01 土台(PR 駆動)                | 条件付き達成 — feature branch + PR + CI + pre-push 代償統制。サーバー側強制は決裁 D1 待ち | PR #1〜#16、a002-acceptance                                |
| FR-13(生成器・手編集検出)          | 達成                                                                                      | PR #3、a004-acceptance(冪等・fail 実証)                    |
| NFR-03(並行負荷)                   | 達成 — 600 秒 × 2 プロファイル、欠損 0・p95 10.9ms                                        | PR #6、a007-acceptance、docs/reference/sqlite-load-test.md |
| NFR-06(≤120 行マップ)              | 達成 — CLAUDE.md/AGENTS.md 各 25〜31 行 + 警告 CI                                         | PR #3/#13                                                  |
| ADR 6 件 Accepted                  | 達成(+0007/0008 も 2026-07-19 Accepted)                                                   | PR #9/#11/#12/#13、転記忠実性 diff                         |
| 決裁反映(リポジトリ・承認者・採番) | 達成                                                                                      | WORKPLAN v1.1/v1.2 Decision Log                            |

## F1 Tests 判定

CI green(main 連続 success)/ スキーマ・台帳・生成器・docs 検査の全テスト self-run PASS / 負荷試験基準達成 / fail ケース実証(手編集検出・docs gate fail run・凍結改竄検知・秘密検出・migrate status 欠落検知)— すべて orchestrator が独立再実行または直接確認。

## 逸脱・特記

1. サーバー側ブランチ保護は GitHub Free 制約で未適用(代償統制で暫定充足)。恒久形態 = 決裁 D1。
2. SPEC A-5 は不成立と実証され、v1.1 で訂正済み(独立最小実装)。
3. 監査(orchestrator 20 件 + worker 独立 19 件 → 統合 24 件)の全件が a016〜a018 で解消。実装バグ 1 件(migrate status)も修正・再現検証済み。
4. 本受入自体が建設期例外(orchestrator 検証 + マージ)下の判定であり、mryfmo の追認(D2)を要する。

## 残存決裁(mryfmo)

- D1: サーバー側保護の恒久形態(Pro 化 / public 化 / 現状受容)
- D2: 建設期承認例外の追認(本受入を含む)と F9-T7 での PR 単位承認切替
- D3: agmsg DB 同居の最終承認(実測済み・同居推奨・暫定採用中)

## evidence store への記録

hx 評価 DB は F2 で運用開始のため、本判定は Git 管理の本ファイルを一次証跡とし、F2-T6 の配線時に hx_audit へ遡及記録する(actor=orchestrator, event=phase.accept, ref=P1-F1-T9)。

## 次フェーズ

F2(観測層: テレメトリ収集 Hooks)。F2-T1 から WORKPLAN v1.2 の契約(指標ペア・アダプタ要件含む)で着手する。
