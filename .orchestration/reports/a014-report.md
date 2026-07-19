# a014 三軸規律による独立監査

## 結論

- status: blocked
- 監査基準: Harness（対象）× Grounded Graph（ADR-0007）× Gated RSI（ADR-0008）
- 所見: 19 件（矛盾 5、ヌケモレ 8、間違い 5、曖昧 1）
- 重要度の高い集中点: 人間承認の代替、保護ブランチ未成立、hash-freeze の trust root、ADR-0007/0008 の WORKPLAN 未反映
- 独立性: `.orchestration/reports/orchestrator-audit-v2-findings.md` を直接開かず、内容はモデル出力へ表示・引用されていない。ただし、repository 全体を読む `ci/secret-scan.py` を実行したため、プロセスが同 file を間接走査した。厳密な read prohibition を満たせず、本結果は blocked とする。外部 Web は取得していない。

## 所見表

| ID | 種別(矛盾/ヌケモレ/間違い/曖昧) | 所在(ファイル:節) | 内容 | 三軸のどの原則に反するか | 修正先の提案(SPEC/WORKPLAN/ADR/実装) |
|---|---|---|---|---|---|
| A014-01 | 矛盾 | `rules.src.md:13-16` / `ADR-0008:20` / `WORKPLAN v1.1:32-35` / `.github/workflows/ci.yml:7-52` | `rules.src.md` は「Claude Code orchestrator の独立・敵対的検証を人間レビューの代替」とする。一方、ADR-0008 は再帰の終端を mryfmo の判断、WORKPLAN は人間承認を mryfmo の review/merge と定義する。CI に承認主体を検証する処理はない。L3 の不動点が人間ではなく同じ agent 系へ移っている。 | Gated RSI: L3 は人間のみ、不動点は mryfmo。Harness: fail-closed 人間承認。 | `rules.src.md` と WORKPLAN の承認定義を統一し、実装側で agent 自身の merge と mryfmo の承認を区別できる強制点を設ける。 |
| A014-02 | 矛盾 | `SPEC:38` / `WORKPLAN v1.1:17,33,75-83,125-127` / `docs/reference/branch-protection.md:13-23` / `githooks/pre-push:14-18` | SPEC/WORKPLAN は main 保護・PR 必須・CI 必須を前提・F1 完了条件とするが、reference は private repo の server-side protection が 403 で未成立と明記する。代償 hook は clone ごとの設定が必要で、同じ呼出し側が `ALLOW_MAIN_PUSH=1` を設定できるため、agent に対する強制境界ではない。 | Harness: Git/PR 単一経路。Gated RSI: L3 gate の自己緩和禁止。 | WORKPLAN の F1 状態を blocked/未達に直し、server-side ruleset か agent と分離された承認 gate を実装する。SPEC A-4 も現状の制約を反映する。 |
| A014-03 | 間違い | `ADR-0008:16` / `docs/reference/evidence-and-gates.md:45-57` / `ci/hash-freeze.py:12-14,53-66` / `ci/test_evidence_gates.sh:44-67` | ADR-0008 は hash-freeze が L3 を「機械的に強制」とするが、検証器・対象設定・保護対象・manifest を同じ PR で更新でき、manifest 自体は snapshot から除外される。テストも変更後の `freeze` で manifest を更新すれば pass することを確認している。現実の機能は差分可視化であり、変更権限の強制ではない。 | Gated RSI: L3 人間専有、自己加速禁止。Grounded Graph: 凍結ノード。 | trust root を変更 PR の checkout 外（default branch の verifier/baseline、ruleset、別署名）へ置く。そこまで ADR/reference の表現を「変更可視化」に訂正する。 |
| A014-04 | ヌケモレ | `ADR-0007:16` / `ADR-0008:16` / `ci/frozen-paths.txt:1-4` | ADR-0007 は評価スイート定義・スキャン規則・凍結 manifest・ADR 群を凍結ノードとし、ADR-0008 は ADR・本階層を L3 とする。現対象は `githooks/`、`ci/`、`db/`、`.github/workflows/` だけで、`docs/decisions/` と将来の eval 定義がない。 | Grounded Graph: 凍結ノード。Gated RSI: L3 変更権限。 | 実装の frozen scope と F8-T2 の対象へ ADR 群・階層定義・評価定義を加える。 |
| A014-05 | ヌケモレ | `ADR-0007:12-13` / `WORKPLAN v1.1:153-156` | F2-T5 は成功率・訂正率・所要時間・頻度だけを列挙し、各駆動指標の対抗指標、接地/派生分類、owner `mryfmo`、改訂周期を要件にしていない。`docs/reference/metrics.md` の完了条件だけでは ADR-0007 の metric contract を満たす保証がない。 | Grounded Graph: 指標ペア、参照値 owner と改訂ループ、接地アンカー。 | WORKPLAN F2-T5 の作業・検証・完了条件へ metric pair、grounding class、owner、review cadence を追加する。 |
| A014-06 | ヌケモレ | `ADR-0008:15,17-19` / `WORKPLAN v1.1:204-207,270-273` | F3-T6 は未達時に Reflector/Curator prompt、F4-T9 は scoring/drafter を改訂するため L2 変更である。採択率等は測るが、L2 変更 PR の実測値、明示的な mryfmo 承認、canary、次周期悪化時の rollback、1 loop 1 change/cycle がタスク条件にない。 | Gated RSI: L2 接地メタ指標、人間承認、増幅封じ込め。 | WORKPLAN F3-T6/F4-T9 と F6-T5 に共通の L2 canary contract を追加する。 |
| A014-07 | 矛盾 | `ADR-0007:15` / `SPEC:160-163` / `WORKPLAN v1.1:311-314` | SPEC と F5-T6 は SkillCoach 型 LLM rubric を F-OPT の入力にするが、少なくとも 1 つの実行 test/eval、人間 merge/reject/correction、実件数との pair を条件にしていない。ADR-0007 は派生指標単独の最適化を禁止する。 | Grounded Graph: 派生指標だけの循環禁止。 | SPEC F-ROUTE と WORKPLAN F5-T6/F6 入力契約に grounded metric pair を明記する。 |
| A014-08 | ヌケモレ | `ADR-0007:17` / `WORKPLAN v1.1:459-462` | F8-T7 の月次レポートは変更・scan・却下・kill switch 履歴だけで、各 optimizer decision が接地指標に依存したかを検査する「循環検査」を含まない。 | Grounded Graph: 接地監査。 | WORKPLAN F8-T7 の作業・検証・出力 schema に循環検査を追加する。 |
| A014-09 | ヌケモレ | `ADR-0007:14` / `WORKPLAN v1.1:194-202,347-350,398-406` | Curator の追記と GC の削除、汎化と project 特化が競合した場合の上位調停経路が WORKPLAN にない。F6-T4 は矛盾を検出して統合 PR を作るだけで、当事者 loop 外の orchestrator 提案と mryfmo 決裁を完了条件にしていない。 | Grounded Graph: loop 速度分離と上位調停。 | WORKPLAN F3/F6/F7 に conflict record、orchestrator arbitration proposal、mryfmo decision の経路を追加する。 |
| A014-10 | ヌケモレ | `ADR-0008:16,18` / `SPEC:63` / `WORKPLAN v1.1:367-370,434-437` | NFR-01 と F8-T2 の自己改変防護は code・CI・Hooks に狭く、gate、kill switch、ADR、凍結 manifest、本階層を含まない。F6-T8 は L3 の diff 閾値を worker 所有の設定へ移すが、その設定変更を人間専有にする検証がない。 | Gated RSI: L3 全域、人間のみ、自己加速禁止。 | SPEC NFR-01 と WORKPLAN F6-T8/F8-T2 の protected path・approval test を ADR-0008 の L3 列挙へ揃える。 |
| A014-11 | 間違い | `SPEC:39` / `docs/reference/evidence-and-gates.md:9-20` / `docs/reference/llm-wiki-genealogy.md:49-53` | SPEC A-5 は AIDD の 3 部品を typed code として再利用可能とするが、repo 調査済み reference は該当 package がなく独立実装したと明記する。既知の誤前提が canonical SPEC に残っている。 | Harness: 実装可能性の正確な前提。Grounded Graph: raw evidence への接地。 | SPEC A-5 と関連 WORKPLAN/REPORT の再利用表現を independent minimal implementation に訂正する。 |
| A014-12 | 間違い | `README.md:5-10` / `rules.src.md:6-11` / `SPEC:7` / `WORKPLAN v1.1:9,40` / `REPORT:7` / `ADR bundle:1-4` | canonical map が歴史資料の ADR bundle を「Architecture decisions」として指し続ける。bundle 内は H001〜H006 が Proposed のままで、Accepted の ADR-0001〜0006と Proposed の ADR-0007/0008を載せる index を案内しない。SPEC は WORKPLAN v1.0 も参照する。 | Harness: agent map の正確性。Grounded Graph: canonical node と由来。 | README/rules/SPEC/WORKPLAN/REPORT の canonical link を `docs/decisions/README.md` と WORKPLAN v1.1 へ更新する。 |
| A014-13 | 矛盾 | `SPEC:49,168` / `ADR-0003:13` / `WORKPLAN v1.1:184-187,367-370` | FR-03 は一括再生成を CI が「拒否」とするが、同じ SPEC 6.3、ADR-0003、WORKPLAN は diff 40% 超を人間承認へ「格上げ」し、例外 merge を認める。fail 条件が二通りある。 | Harness: 検証 gate の一意性。Gated RSI: approval threshold の明確性。 | SPEC FR-03 を「拒否」または「人間承認へ格上げ」のどちらかに統一し、CI test 期待値も合わせる。 |
| A014-14 | 矛盾 | `docs/reference/sqlite-load-test.md:9-13,60-70` / `docs/reference/telemetry-schema.md:9-13` / `WORKPLAN v1.1:127,538-543` | F1-T5 は同居を採用する測定判断を記録済みだが、telemetry schema は選択が open、WORKPLAN は F1 末 TBD のままである。同一 decision の状態がページごとに異なる。 | Grounded Graph: 接地測定から decision node への反映。Harness: deployment assumption。 | WORKPLAN の OQ #4 を resolved に移し、telemetry schema の deployment choice を測定範囲付きで更新する。 |
| A014-15 | ヌケモレ | `SPEC:175-176` / `docs/reference/wiki-conventions.md:29` / `ci/docs-frontmatter-exempt.txt:1-6` / `WORKPLAN v1.1:110-113,199-202` | SPEC は docs 全ページに owner/last-verified/freshness を必須とするが、SPEC・WORKPLAN・REPORT・ADR bundle 等の基準文書が無期限の例外である。例外を解消する task/期限がなく、F3 の TTL GC から重要 node が外れる。 | Grounded Graph: anchor の owner・鮮度・監査可能性。 | WORKPLAN に legacy frontmatter 例外解消 task と期限を追加し、CI exemption を段階的に空にする。 |
| A014-16 | ヌケモレ | `SPEC:56,129-135` / `WORKPLAN v1.1:95-98` / `db/hx-task.sh:15-28` / repo 内 `hx-task` 参照全件 | F1-T4 は `agmsg task` CLI と SPEC 5.3 protocol への統合を完了条件にするが、実装は独立した `db/hx-task.sh` で、repo 内の利用者は tests/docs だけである。AGMSG-TASK/RESULT/ACCEPTANCE と `hx_tasks` を接続する adapter がなく、現在の授受が台帳を唯一経路にしている証拠がない。 | Harness: Claude/Codex/agmsg の単一 protocol、NFR-04 ledger。 | 実装に agmsg adapter を追加するか、SPEC/WORKPLAN を「独立 hx CLI」に変更して統合 task を別途置く。 |
| A014-17 | 間違い | `db/migrate.sh:63-71` / `docs/reference/telemetry-schema.md:17-28` / `ci/test_migrations.sh:36-38` | migration は `0001_telemetry` と `0002_ledger` の 2 本だが、`status` は 0001 しか確認しない。scratch DB で 0002 entry/table を除去しても `status_output=0001_telemetry applied`、`hx_tasks_exists=0` を再現した。tests もこの不完全な出力を正解として固定する。 | Harness: migration/ledger correctness と観測可能性。 | `db/migrate.sh status` と tests を全 migration の状態表示・非ゼロ判定へ拡張する。 |
| A014-18 | 間違い | `WORKPLAN v1.1:4-6,42-47` / `git log --oneline` | WORKPLAN は状態を「F1 着手可」、Current State を repo 未作成・schema 未拡張・AIDD 組込み未実施とするが、main には F1-T0〜T8 相当の repo、schema、ledger、load test、CI、ADR が存在する。79 task のどこまで完了したかを canonical plan から判定できない。 | Harness: 実行計画と現状態。Grounded Graph: current-state node の鮮度。 | WORKPLAN の status/current state と task status/evidence link を更新する。 |
| A014-19 | 曖昧 | `ADR-0001:13` / `SPEC:133-135` / `githooks/pre-push:14-18` / `rules.src.md:13-17` | ADR は agent/job の「direct push」を拒否、SPEC は Codex が「直接 push せず branch + PR URL を返す」とする一方、hook は main だけを拒否し、operation は feature branch + PR を通常経路とする。remote PR 作成に必要な feature-branch push を許すのか、orchestrator が代行するのかが不明。 | Harness: PR handoff protocol の一意性。Gated RSI: gate の境界。 | SPEC/ADR/rules で「main への direct push 禁止」「feature branch push の主体」を明示する。 |

## 監査済み・所見なし

- ADR-0001〜0008: 全文を確認した。上表以外では ADR-0002 の二層メモリ、ADR-0005 の三層 scope の内部整合に所見なし。
- WORKPLAN v1.1: 79 task 見出しを F1〜F9 まで全読した。未着手の将来 task であること自体は所見にしていない。
- reference: 7 ページを全読した。SQLite load test の記録値と `db/load-test.sh` の出力項目、Wiki link 規約には上表以外の所見なし。
- DB: migration up/down、FTS、append-only audit、task state transition、timeout requeue、SQL quoting の tests は成功。上表 A014-16/17 以外の再現可能な不具合なし。
- CI: rules generator、docs path/frontmatter checker、secret scanner、evidence behavior test は成功。上表 A014-01〜04/15 の governance scope 外に追加所見なし。
- githooks / `.github`: 実装内容を全読した。shell の ref parsing と CI の既存 step 自体に追加所見なし。

## 修正順の提案

1. A014-01〜04: 人間不動点と trust root を先に確立する。
2. A014-05〜10: ADR-0007/0008 を SPEC/WORKPLAN の task contract に反映する。
3. A014-11〜19: canonical docs と実装状態の drift を解消する。

本監査は所見提出だけを行い、修正・commit・push・外部取得は行っていない。所見は scanner 出力（`secret scan clean` のみ）を根拠にしておらず、禁止 report の内容はモデルへ渡っていないが、独立性を再保証するには別 worker による再監査が必要である。
