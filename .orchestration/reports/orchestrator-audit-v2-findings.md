# 三軸統合規律に対する現状監査 — orchestrator 初期所見

- author: claude-fable5high-herness (orchestrator)
- date: 2026-07-19
- 目的: 「Harness(対象)× Grounded Graph(位相)× Gated RSI(深さ)」の統合規律に照らした、SPEC / ADR / WORKPLAN / 実装の矛盾・ヌケモレ・間違い・曖昧の棚卸し。ワーカーの独立監査(a014)と突合して修正計画(SPEC v1.1 / WORKPLAN v1.2)の入力とする。

## 間違い(事実と不一致)

- E1. SPEC A-5: AIDD の closed gates / data guards / evidence store を「型付きコードとして再利用可能」— 実在せず(a008 で実証、独立再実装で代替済み)。SPEC 改訂で修正要。
- E2. SPEC/WORKPLAN の FR-01 前提「保護ブランチ + PR 必須 + 必須 CI」— GitHub Free private では実現不能(403 実証)。現実装は代償統制(ローカル pre-push + CI + PR 運用)。SPEC は「サーバー側強制 or 代償統制」の二形態を明文化し、決裁(Pro 化 / public 化 / 受容)を条件として記載すべき。
- E3. REPORT: 「LLM Wiki」の用語を原典(Karpathy 2026-04)引用なしで使用。REPORT は日付付き歴史文書として凍結し、SPEC v1.1 が genealogy 文書を正式参照する形で修正。

## 矛盾(文書間・文書と実装)

- C1. SPEC 6.2 F-ROUTE「SkillCoach 型ルーブリックを eval に含め F-OPT の入力にする」 vs ADR-0007 原則 4(派生指標のみの最適化禁止)。ルーブリック(LLM 評価)単独入力は循環。SPEC に「接地指標とのペア必須」を明記する修正要。
- C2. SPEC 5.3 メッセージ種別(task.assign/claim/progress/result/error, ctrl._)+ hx_tasks 台帳(a006 実装)vs 実運用プロトコル(agmsg-orchestration の AGMSG-TASK/RESULT/ACCEPTANCE v1 契約 + .orchestration artifact)。二重定義。統合方針: AGMSG-_ を上位のオーケストレーション契約、SPEC 5.3 台帳を実行状態機械とし、対応写像(AGMSG-TASK→task.assign+create、RESULT→task.result、ACCEPTANCE→done/failed 遷移)を SPEC に明文化。実装接続は F2-T4(ラッパー)で。
- C3. WORKPLAN F3-T6「未達時は T1/T2 のプロンプト改訂」= L2 再帰変更だが、メタ指標駆動・人間承認・カナリアの ADR-0008 制約が未記載。WORKPLAN v1.2 で条件を付記。
- C4. ADR-0007/0008 は Proposed のまま、SPEC は未反映。ユーザー指示(2026-07-19「取り込み」「RSI 追加」「根本修正」)を決裁として Accepted へ昇格し、SPEC v1.1 に統合する。

## ヌケモレ(統合規律が要求するが現状にない)

- G1. 指標ペアの体系: SPEC 6.3 F-OPT の完了指標(成功率・訂正率・所要時間)がペア構造で定義されていない。FR 追加(全最適化駆動指標は対抗指標とペア)+ F2-T5 metrics.md 要件化。
- G2. 参照値(閾値)のオーナー・改訂ループ: WORKPLAN は初期値と F9-T4 の一括確定のみ。L3 所有の設定ファイル + 改訂周期の定義がない。
- G3. ループ間調停: curator 追記 vs GC 削除、昇格汎化 vs プロジェクト特化の衝突解決規則が SPEC にない(ADR-0007 原則 3 の SPEC 反映)。
- G4. 接地監査(循環検査): F8-T7 月次レポートの要件に「派生指標のみで回った決定の検出」がない。
- G5. メタ指標とカナリア: F3/F6 の改善器変更に対するメタ指標記録・次周期ロールバックが WORKPLAN タスク要件にない(ADR-0008 原則 2/4)。
- G6. WORKPLAN v1.1 は a011〜a014 系の追加作業(genealogy、ADR-0007/0008、規律文書、本監査)を含まない。v1.2 で実績として編入。
- G7. 三軸規律の自己記述文書が存在しない(進行中の a014 系で作成)。
- G8. 残存決裁 #4(DB 同居/分離): 実測データと推奨(同居)が揃ったが決裁記録がない。ユーザー決裁を求める項として明示。

## 曖昧(解釈が割れる)

- A1. 「人間承認」— v1.1 Assumptions で mryfmo 承認と定義済みだが、SPEC 本文(NFR-01)は未更新。SPEC v1.1 で単独運用の定義を反映。
- A2. 「Graph Engineering」の語 — エージェント実行グラフ(LangGraph 等)と衝突。規律文書で「改善ループ位相の工学」と定義固定。
- A3. SPEC 6.1 の「隔離検証」のサンドボックス実体(OS レベル? worktree のみ?)が未指定。F4-T4 実装前に定義要。
- A4. 体験ログの記録対象範囲(orchestrator セッションのみか、worker 実行も含むか)— F2-T4 と 5.3 の関係として明確化。

## 修正実行計画(案)

1. a014(worker): 独立監査 — 本所見に依存せず SPEC/ADR/WORKPLAN/実装を三軸規律で走査し所見表を提出 → orchestrator が突合・統合。
2. a015(worker): 規律文書 docs/specs/discipline-v1.0.md(三軸定式・用語固定・ADR 対応)+ ADR-0007/0008 の Accepted 昇格(決裁根拠: ユーザー指示 2026-07-19)。
3. a016(worker): SPEC v1.1 — E1/E2/C1/C2/A1/A3/A4 修正、G1/G3/G4 の FR/機能仕様追記。規律文書を正式参照。
4. a017(worker): WORKPLAN v1.2 — C3/G2/G5/G6 反映、決裁事項表更新(G8、保護決裁)。
5. F1-T9(orchestrator): 上記完了後に Phase F1+ 拡張受入。
