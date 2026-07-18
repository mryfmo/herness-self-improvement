# REPORT-HARNESS-SELF-IMPROVEMENT v1.0
# Harness Engineering 自己改善システム — 調査・評価・意思決定報告書

- 作成日: 2026-07-18
- 作成者: Claude Fable 5（調査・分析・意思決定担当）
- 読者: 部門関係者、および後続の Claude Code（オーケストレーター）/ Codex（ワーカー）
- 関連文書: SPEC-HARNESS-SELF-IMPROVEMENT-v1.0.md / WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.0.md / ADR-HARNESS-SELF-IMPROVEMENT-v1.0.md

---

## 1. エグゼクティブサマリー

**結論: 自己改善ハーネスの最適解は「Git を単一の真実源とし、SQLite（agmsg 拡張）を体験ログ層、ACE 型 Reflector/Curator パイプラインを知識還流層とする、fail-closed な PR 駆動自己改善アーキテクチャ」であり、外部メモリ SaaS・重量オーケストレーションフレームワーク・無人自動デプロイはいずれも不採用とする。**

総合評価: **83 / 100（加重平均、確信度: 中〜高）**

要点は次の 5 つである。

1. **業界の実証が揃った。** OpenAI Codex チームは 2026 年 2 月、人手コード 0 行で約 100 万行・1,500 PR を 5 か月で構築した事例を公開し、その中核が「約 100 行の AGENTS.md をマップとし、構造化された docs/ ディレクトリ（= LLM Wiki に相当）を CI とバックグラウンドエージェント（夜間ガベージコレクション）で自己維持する」仕組みであることを示した。本設計はこの実証済みパターンを土台にする。
2. **SKILLS の自動生成・自動最適化は 2026 年上半期に研究が急伸したが、成功率は未だ 7 割前後。** EvoSkills・SkillOS・MUSE-Autoskill・AutoSkill・Trace2Skill 等が複数ファイル構成のスキルパッケージ自動生成と進化を実証した一方、MUSE-Autoskill はスキル生成成功率 68.6% と報告している。したがって自動生成は「ドラフト → 検証 → PR → 承認」の fail-closed フローに限定し、無人デプロイは行わない。
3. **コンテキスト自己最適化には ACE（Agentic Context Engineering）を採用する。** Generator / Reflector / Curator の 3 役割によるデルタ更新（grow-and-refine + 重複排除）は、一括書き換えによる「コンテキスト崩壊」と「簡潔化バイアス」を防ぎつつエージェント性能を +10.6% 改善したと報告され、公開実装も存在する。SKILLS・Wiki の継続改善ループはこの方式で構築する。
4. **メモリは外部 SaaS ではなく二層構造（SQLite の体験ログ + Git 上の恒久知識）とする。** Mem0 / Zep / Letta 等の専用メモリ基盤は成熟しつつあるが、ベンチマーク結果が当事者間で係争中であり、トークンフットプリント・非同期反映遅延・ガバナンス監査性の課題が報告されている。Claude Code / Codex が「ネイティブに読む形式」は結局 Git 上の Markdown（CLAUDE.md / AGENTS.md / SKILL.md / docs/）であるため、恒久知識は Git に還流させるのが最短経路である。
5. **ガバナンスが本システムの成立条件。** Snyk の ToxicSkills 調査はスキルエコシステムの 36% に欠陥・1,467 件の脆弱スキル・実働する悪性ペイロードを報告し、PoisonedSkills 研究は Claude Code を含む主要エージェントで 11.6〜33.5% の注入バイパス率を示した。よって第三者マーケットプレイスからの自動取込は禁止し、社内レジストリ + スキャン + 署名 + deny-by-default Hooks + 人間承認ゲートを必須とする（AIDD Platform で確立済みの closed gates / data guards / evidence store を再利用）。

---

## 2. 評価観点別 採点結果

### 2.1 総括表

| # | 評価観点 | 採点 | 確信度 | 一言結論 |
|---|---|---|---|---|
| 1 | LLM Wiki × Agents Memory 統合設計 | **88** | 高 | docs-as-code Wiki + 二層メモリで実証済みパターンに乗れる |
| 2 | Workflows/SKILLS/Hooks/Rules/SubAgents 連動アーキテクチャ | **90** | 高 | Claude Code の公式一次資料で責務分担が確立済み。最も確度が高い |
| 3 | 繰り返しプロンプトからの自動生成・自動組合せ | **76** | 中 | 研究は豊富だが生成成功率 ~7 割。PR ゲート必須 |
| 4 | SKILLS 自動最適化ループ | **82** | 中〜高 | ACE のデルタ更新 + OpenAI の夜間 GC が実証。評価器の整備が鍵 |
| 5 | プロジェクト/ユーザー/業務スコープの調和 | **85** | 高 | Claude Code のスコープ優先順位 + RIZZ のスコープ別プレイブック研究が直接支持 |
| 6 | Claude Code × Codex × agmsg 実装可能性 | **80** | 中 | Agent Skills 標準の相互運用（~40 ツール、Codex CLI 含む）が追い風。agmsg は社内実績のみ |
| 7 | ガバナンス・安全性 | **77** | 高（脅威）/ 中（対策十分性） | 脅威は定量的に実証済み。fail-closed 設計で運用可能水準に到達可能 |
| — | **総合（加重平均）** | **83** | 中〜高 | 実装着手可能。最大リスクは観点 3・7 |

加重: 観点 2・7 を 1.2 倍（成立条件のため）、他は 1.0。

### 2.2 観点別詳細

#### 観点 1: LLM Wiki × Agents Memory 統合設計 — 88 点（確信度: 高）

**採点理由**
- 実運用エビデンスが最も厚い領域。OpenAI のハーネスエンジニアリング報告（2026-02-11）は、単一巨大 AGENTS.md の失敗を経て「AGENTS.md を約 100 行の『マップ』に縮小し、設計判断・実行計画・製品仕様・リファレンスを構造化 docs/ に分離、CI が相互リンクの整合を検証、夜間のバックグラウンドエージェントが逸脱をスキャンして修正 PR を自動作成」という構成に到達したと報告。これは「エージェントが維持する LLM Wiki」の実証そのものである。
- 参考実装として DeepWiki（Cognition、2025-04 公開）が「リポジトリ → 構造化 Wiki 自動生成 + MCP 経由でエージェントから照会」を商用実証済み。
- メモリ側は Mem0（GitHub 約 48K スター、ECAI 2025 論文）、Zep/Graphiti(時制ナレッジグラフ)、Letta/MemGPT（階層メモリ）が成熟。ただし (a) LoCoMo ベンチ結果を巡り Mem0 と Zep が相互に反論中、(b) Zep は 1 会話あたり 60 万トークン級のフットプリントと取込直後の検索失敗（非同期グラフ構築待ち）が報告、(c) Mem0 は大規模時のインデックス信頼性問題が報告されており、「外部メモリ基盤を中核に据える」判断は時期尚早。
- 減点要素: Wiki の鮮度維持（陳腐化検知）の定量評価手法が業界的に未確立。本設計では鮮度メタデータ + GC ジョブで補うが、初期は運用チューニングが必要。

**推奨理由（採用アプローチ）**
- LLM Wiki = リポジトリ内 docs/ ツリー（Markdown、Git 版管理、CI リンク検査、エージェントによる更新 PR）。AGENTS.md / CLAUDE.md は「マップ」に徹し 100 行程度に保つ。
- Agents Memory = 二層構造。第 1 層（体験・episodic）: セッションログ・ツール実行結果・失敗事例を SQLite（agmsg と同居可能なスキーマ）に全件記録。第 2 層（恒久・semantic/procedural）: Reflector/Curator が第 1 層から教訓を抽出し、Wiki・SKILLS へデルタ PR として還流。検索は SQLite FTS5 + frontmatter メタデータで賄い、必要になった時点でのみグラフ拡張（Graphiti 等）を検討する。

#### 観点 2: Workflows/SKILLS/Hooks/Rules/SubAgents 連動アーキテクチャ — 90 点（確信度: 高）

**採点理由**
- 一次情報（Claude Code 公式ドキュメント）で責務分担が明文化済み: CLAUDE.md は毎セッション注入される永続コンテキスト、Skills は再利用可能な知識・手順で自動/明示起動可能かつサブエージェントの隔離コンテキストでも実行可能、Hooks はライフサイクルイベント（PreToolUse / PostToolUse / SessionStart / PreCompact / Stop / SubagentStop 等）で shell / HTTP / MCP ツール / プロンプト / サブエージェントをハンドラとして起動、Plugins が Skills・Hooks・SubAgents・MCP を名前空間付きで束ねる配布単位。
- 「Hooks はモデルのコンテキスト外で実行されモデルが上書きできない」性質が公式に保証されており、確率的遵守（Rules 文書）と決定的強制（Hooks）の二層ガードが素直に組める。これは AIDD Platform で採用済みの「ガバナンス部品を Hooks から型付きコードとして呼ぶ」方針と完全に整合する。
- Skills / Subagents / Agent Teams を「同一コンテキスト ↔ 隔離コンテキスト ↔ 別プロセス」の分離度グラデーションとして使い分ける整理が実務者の間で定着している。
- 減点要素: Hooks イベント数・ハンドラ種別は活発に拡張中で、バージョン追随コストが恒常的に発生する。

**推奨理由**
- 責務マトリクスを固定する: Rules（常時制約）= CLAUDE.md/AGENTS.md の簡潔な規範 + Hooks による決定的強制。SKILLS（オンデマンド手続き知識）= SKILL.md パッケージ。Workflows（定型フロー）= スラッシュコマンド/Plugin として SKILLS を合成。SubAgents（隔離実行）= 調査・レビュー・GC 等のコンテキスト汚染回避。連携プロトコルは「Hooks がイベントを SQLite に記録 → GC/Reflector サブエージェントが読む → PR で artefact を更新」の一方向ループに限定し、循環依存を作らない。

#### 観点 3: 自動生成・自動組合せ機構 — 76 点（確信度: 中）

**採点理由**
- 2026 年上半期に直接関連する研究が集中的に出現: EvoSkills（arXiv:2604.01687、複数ファイル構成のスキルパッケージを生成し、情報隔離されたサロゲート検証で 5 ラウンドの進化により人手キュレーションを超過と主張）、Trace2Skill（arXiv:2603.25158、軌跡から転移可能スキルへ蒸留）、AutoSkill（arXiv:2603.01145、経験駆動の生涯スキル自己進化）、MUSE-Autoskill（arXiv:2605.27366、生成・記憶・管理・評価の統合）、SkillOS（arXiv:2605.06614、スキルキュレーション学習）、EvoSkill（arXiv:2603.02766、マルチエージェントの自動スキル発見）、Skill-MAS（arXiv:2606.18837）。系譜の起点は Voyager(2023) のスキルライブラリ。
- 自動「組合せ」は Claude Code のネイティブ機能（description マッチによる自動ロード、Plugin 名前空間）で既に大半が満たされ、追加実装は薄いルーティング層とメタデータ規約で足りる。
- 減点要素（大）: MUSE-Autoskill 自身がスキル生成成功率 68.6%（51 タスク中 35）・単一軌跡由来の過適合を報告。SkillsBench（arXiv:2602.12670）はスキル効果がタスク横断で一様でないことを示す。EvoSkills も一部先行研究の教師信号依存を指摘。すなわち「無人で生成 → 即適用」は現時点で品質保証不能。
- Anthropic 公式の skill-creator スキル（生成・評価・説明文最適化を含む）が存在し、生成規約のリファレンスとして利用可能である点は加点。

**推奨理由**
- パターン検出（SQLite 上のプロンプト/セッションログを夜間マイニング、頻度 × 失敗率 × 所要時間でスコアリング）→ skill-creator 規約でドラフト生成 → EvoSkills 型の隔離検証（サロゲートタスクで実行）→ 評価スイート合格 → PR 起票 → 人間承認、の 6 段 fail-closed パイプラインとする。組合せ側は SKILL.md frontmatter（description / triggers / scope / owner / freshness）標準化 + SQLite FTS のスキル索引で実現し、独自ルーターの新規開発は行わない。

#### 観点 4: SKILLS 自動最適化ループ — 82 点（確信度: 中〜高）

**採点理由**
- ACE（arXiv:2510.04618、v3 2026-03）が中核根拠。コンテキストを「進化するプレイブック」として扱い、Generator（実行）/ Reflector（実行フィードバックから教訓抽出）/ Curator（非冗長な構造化デルタとして統合）の分業と grow-and-refine（追記 + 更新 + 定期重複排除）により、一括リライトが招くコンテキスト崩壊・簡潔化バイアスを回避。エージェントベンチで +10.6%、教師ラベルなし（実行フィードバックのみ）で適応可能、AppWorld で本番級エージェントと同等と報告。公開コード（github.com/ace-agent/ace）あり。
- 実運用側の裏付けとして OpenAI の夜間 GC（黄金原則からの逸脱スキャン → モジュール別品質グレード更新 → 是正 PR 自動起票、多くが 1 分以内に自動マージ）が存在。
- 派生研究も厚い: SkillCoach（arXiv:2607.01874、自己進化ルーブリックでスキル利用を評価・改善）、SkillClaw（arXiv:2604.08377、集合的スキル進化）、CODESKILL（arXiv:2605.25430、コーディングエージェント向け自己進化スキル）、RIZZ（arXiv:2606.20638、ACE を粒度別プレイブックへ一般化）、Agentic Harness Engineering（arXiv:2604.25850、可観測性駆動でハーネス自体を自動進化）。
- 減点要素: 「最適化が改善だったか」を判定する評価器（スキル毎の合否指標・回帰スイート）の整備コストが高く、評価器なしのループは劣化を検知できない。ここが実装上の最大工数。

**推奨理由**
- SKILLS・Wiki への変更は常に「デルタ」単位（行追加・行更新・重複統合・陳腐化削除）とし、一括再生成を禁止（ACE の教訓）。トリガーは (a) 夜間定期 GC、(b) スキル起動失敗・ユーザー訂正の閾値超過、(c) 依存ツール/API のバージョン変化検知の 3 系統。反映は必ず PR 経由、マージ条件は評価スイート（skill-creator の eval 機構 + SkillsBench 型タスクサンプル）合格 + 影響範囲に応じた承認レベル。

#### 観点 5: スコープ分離と調和 — 85 点（確信度: 高）

**採点理由**
- Claude Code はユーザースコープ（~/.claude/skills 等）とプロジェクトスコープ（.claude/）の二層探索、settings の階層（managed/enterprise → project → user）優先順位、Plugin marketplace による組織配布を公式にサポートしており、「業務（組織）/ プロジェクト / ユーザー」3 層は製品機能に自然に写像できる。
- 研究側では RIZZ（arXiv:2606.20638）が単一プレイブックではなく branch-local / family-level / global の粒度別プレイブック保持 + ルーティングを提案し、干渉最小化の観点からスコープ分離の有効性を直接支持。
- 減点要素: 「調和」= スコープ間の知識昇格（ユーザーの工夫 → プロジェクト標準 → 全社標準）は製品機能では提供されず、昇格パイプライン（利用統計 + 評価 + 承認 PR）を自作する必要がある。命名衝突・重複スキルの横断的検出も自作範囲。

**推奨理由**
- 3 層レジストリ: 全社 = 社内 Plugin marketplace（Git リポジトリ）、プロジェクト = 各リポジトリ .claude/、個人 = ~/.claude/。優先順位はプロジェクト > 個人 > 全社の明示規約とし、昇格は「利用回数・成功率の閾値超過 → Curator が汎化ドラフト作成 → 上位スコープへ PR → 承認」の一方向フロー。全スキルの frontmatter に scope / owner を必須化し、GC ジョブが層をまたぐ重複・矛盾を検出する。

#### 観点 6: Claude Code × Codex × agmsg 実装可能性・運用信頼性・フェイルセーフ性 — 80 点（確信度: 中）

**採点理由**
- 相互運用の追い風が大きい: Agent Skills は 2025 年 12 月にオープン標準として公開され、2026 年 6 月時点で OpenAI Codex CLI・Gemini CLI・GitHub Copilot 等およそ 40 ツールが対応と報告されており、同一 SKILL.md を Claude Code（オーケストレーター）と Codex（ワーカー）で共用できる。Rules は CLAUDE.md / AGENTS.md の二重管理になるが、単一ソースからの生成で吸収可能（AGENTS.md は入れ子上書き・探索仕様が Codex 側で文書化済み）。
- スループットの実証: OpenAI 事例はエンジニア 3→7 名で 1 日 1 人あたり 3.5 PR、5 か月で約 100 万行に到達しており、オーケストレーター + 自律ワーカー構成が本番規模で成立することを示す。
- agmsg（SQLite ベース CLI メッセージング）は AI Ops Platform / AIDD Platform で社内実績があり、SQLite はトランザクション・耐久性・オフライン動作の点でエージェント間台帳に適する。ただし外部公開の実績・ベンチマークは存在せず、単一ホスト前提・書込み競合（WAL 設定・busy_timeout 等）の検証は本計画内で必須。
- 減点要素: (a) agmsg のスキーマ拡張（テレメトリ・タスク台帳）が未設計、(b) Codex 側 Hooks 相当の決定的強制はランナー（CI / ラッパー）で代替する必要、(c) 二重エージェント環境での「どちらが artefact を更新したか」の帰属管理が必要。

**推奨理由**
- 通信は agmsg の非同期メッセージ + SQLite タスク台帳（状態機械: queued → claimed → running → done/failed/blocked）に一本化し、直接のプロセス間 RPC を作らない。フェイルセーフは「ワーカー無応答タイムアウト → 台帳上で requeue、冪等キー必須、成果物は PR としてのみ提出（直接 push 禁止）」。Claude Code 側の Hooks と CI を二重の強制点とし、Codex は常にサンドボックス + 最小権限で起動する。

#### 観点 7: ガバナンス・安全性 — 77 点（確信度: 脅威側は高、対策十分性は中）

**採点理由**
- 脅威は定量的に実証済み: Snyk ToxicSkills（2026-02）はスキルエコシステムの 36% にセキュリティ欠陥、脆弱スキル 1,467 件、資格情報窃取・バックドア・データ持出用の悪性ペイロード 76 件（一部は公開继続）を報告し、2026 年 2 月には Claude Code 等の利用者を狙う組織的マルウェアキャンペーンが確認された。PoisonedSkills 研究（arXiv:2604.03081）は Claude Code / OpenHands / Codex / Gemini CLI × 5 モデルに対し 1,070 の敵対的スキルで評価し、明示的注入は最良構成で 0% に抑えられる一方、難読化手法（DDIPE）は 11.6〜33.5% のバイパス率を達成、さらに「Claude Code はスキル内容を専用の許可プロンプトなしに実行指示として扱う」旨の HackerOne 開示を含む。Datadog は SKILL.md の動的コンテキスト（`!` コマンド）が「モデルがスキルを読む前に」実行され、モデル側の注入防御が介在できないリスクを指摘。CI 経由の注入（claude-code-action の権限バイパス、Nx 侵害での資格情報標的化）も実例がある。
- 対策側の材料も揃う: Hooks の deny-by-default（PreToolUse ブロック）、Plugin の社内マーケットプレイス限定配布、MalSkillBench（arXiv:2606.07131）等のスキャン用ベンチ、AIDD Platform で実装済みの closed gates / data guards / evidence store。プロンプト注入がモデル層だけでは解決不能である以上、インフラ層の決定的制御に寄せる方針は業界コンセンサスと一致。
- 減点要素: 難読化注入の残存リスク（>10%）は構造的に消せないため、「侵入前提」の権限最小化・監査・即時停止に依存する。ここは点数上限を制約する。

**推奨理由**
- 7 つの必須制御を仕様化する: (1) 第三者マーケットプレイス自動取込の全面禁止（社内レジストリのみ）、(2) スキル取込/変更時の静的スキャン（動的コンテキスト実行の検出・ネットワーク到達先の許可リスト照合・MalSkillBench 系パターン）、(3) スキル署名と出所記録、(4) PreToolUse deny-by-default + 書込み系は PR フロー限定、(5) 自己改善パイプライン自体の変更は人間承認必須（自己改変の暴走防止）、(6) evidence store への全イベント監査記録、(7) kill switch（GC・自動生成ジョブの即時停止フラグ）。

---

## 3. 決定した最適解と選定理由

### 3.1 決定（結論）

**「Git 中心・二層メモリ・ACE 型還流・fail-closed PR 駆動」アーキテクチャ** を採用する。構成要素は次の 6 点。

1. **単一の真実源 = Git**: LLM Wiki（docs/）、SKILLS（.claude/skills/）、Rules（CLAUDE.md + 生成される AGENTS.md）、Hooks 設定、SubAgents 定義、Workflows（コマンド/Plugin）をすべて Git 管理し、変更は PR のみで反映。
2. **二層メモリ**: 体験層 = SQLite（agmsg 拡張スキーマ: セッション・プロンプト・ツールイベント・スキル起動・成否）。恒久層 = Git 上の Wiki / SKILLS。外部メモリ SaaS は v1 不採用。
3. **ACE 型知識還流**: Reflector / Curator サブエージェントが体験層から教訓を抽出し、デルタ更新（追記・更新・重複排除・陳腐化削除）として Wiki / SKILLS へ PR。一括再生成は禁止。
4. **自動生成 = 6 段 fail-closed パイプライン**: パターン検出 → ドラフト生成（skill-creator 規約）→ 隔離検証 → 評価スイート → PR → 人間承認。
5. **3 層スコープ + 昇格パイプライン**: 全社 Plugin marketplace / プロジェクト .claude/ / 個人 ~/.claude/、優先順位規約と一方向昇格フロー。
6. **ガバナンス 7 制御**（観点 7 推奨のとおり）+ AIDD 由来の closed gates / data guards / evidence store 再利用。

### 3.2 比較した代替案と却下理由

| 案 | 概要 | 却下理由（簡潔） |
|---|---|---|
| A: 外部メモリ基盤中核型（Mem0 / Zep / Letta を知識ストアの中心に据える） | 恒久知識をメモリ SaaS/自ホスト基盤に保持し、エージェントは API 経由で読み書き | ベンチ結果が当事者間で係争中で選定根拠が不安定。トークンフットプリント・取込直後の検索失敗・大規模時の信頼性問題の報告あり。Claude Code / Codex が直接消費する形式（Git 上の Markdown）と二重管理になり、監査性も低下。※体験層の検索補助として将来採用余地は残す |
| B: 重み更新型自己改善（SkillRL / SEAgent 系の RL・ファインチューニング） | 経験をモデル重みへ内在化 | 非検査・非移植（Claude Code と Codex の 2 モデル体制で共有不能）、運用コスト過大、ガバナンス監査不能。研究側（EvoSkills 等）も非検査性を明確な難点として指摘 |
| C: 無人自動デプロイ型（生成スキルを承認なしで即時適用） | 完全自動の自己改善ループ | 生成成功率 ~68.6% とスキル供給網攻撃の実証（ToxicSkills / PoisonedSkills）に照らし品質・安全の両面で不可。fail-closed 原則（既存 ADR）にも違反 |
| D: 汎用オーケストレーションフレームワーク導入（LangGraph / CrewAI 等で独自ハーネス構築） | フレームワーク上に独自制御ループを実装 | 既存の全社決定「Claude Code を唯一のエントリポイント・基盤標準とする」（AIDD Platform ADR）に反し、Skills/Hooks/Plugins のネイティブ機構と二重投資になる |
| E: 採用案（Git 中心・二層メモリ・ACE 型還流・fail-closed PR 駆動） | 上記 3.1 | — （採用） |

### 3.3 決定の確信度と残存リスク

- 確信度: **中〜高**。観点 1・2・5 は一次資料 + 本番実証で裏付けられ高確信。観点 3・4 は 2026 年の査読前研究への依存度が高く、数値（+10.6% 等）の自社環境での再現は未検証（Phase 4・6 の評価スイートで実測する計画とした）。観点 6 の agmsg は社内実績のみで外部裏付けなし。
- 残存リスク: (a) 難読化プロンプト注入の残存（>10% バイパス率の報告）→ 権限最小化と監査で受容水準へ、(b) 評価スイート整備前に最適化ループを回すと劣化を検知できない → WORKPLAN で評価器整備（F4）を最適化ループ稼働（F6)より前に配置、(c) SQLite 書込み競合 → F1 で負荷検証タスクを設定。

---

## 4. 主要参照情報源（実際に取得・確認したもの）

**一次資料・本番事例**
- OpenAI, "Harness engineering: leveraging Codex in an agent-first world"（2026-02-11） https://openai.com/index/harness-engineering/
- Claude Code 公式ドキュメント（機能全体像・Skills/Hooks/Subagents/Plugins） https://code.claude.com/docs/en/features-overview
- Anthropic, Agent Skills（オープン標準・公式スキル集） https://github.com/anthropics/skills
- Anthropic, "Effective harnesses for long-running agents"（awesome-harness-engineering 経由で確認）

**ArXiv（2025-10〜2026-07）**
- ACE: Agentic Context Engineering — arXiv:2510.04618（v3: 2026-03-29、コード: github.com/ace-agent/ace）
- RIZZ（スコープ別プレイブック） — arXiv:2606.20638
- EvoSkills — arXiv:2604.01687 / SkillOS — arXiv:2605.06614 / MUSE-Autoskill — arXiv:2605.27366 / SkillClaw — arXiv:2604.08377 / CODESKILL — arXiv:2605.25430 / SkillCoach — arXiv:2607.01874 / Skill-MAS — arXiv:2606.18837
- SkillsBench — arXiv:2602.12670（他論文の参照経由で確認）/ AutoSkill — arXiv:2603.01145（同）/ Trace2Skill — arXiv:2603.25158（同）
- Agentic Harness Engineering（可観測性駆動ハーネス自動進化） — arXiv:2604.25850
- PoisonedSkills — arXiv:2604.03081 / MalSkillBench — arXiv:2606.07131
- 自己進化エージェント survey — arXiv:2508.07407 / Memp（手続きメモリ） — arXiv:2508.06433（参照経由）

**セキュリティ・運用**
- Snyk, "ToxicSkills"（2026-02-05） https://snyk.io/blog/toxicskills-malicious-ai-agent-skills-clawhub/
- Datadog Security Labs, 動的コンテキストリスク（2026-05） https://securitylabs.datadoghq.com/articles/malicious-skills-supply-chain-risks-in-coding-agents-with-dynamic-context/
- CSA Research Note, claude-code-action プロンプト注入（2026-06）

**メモリ基盤比較（2026 年時点）**
- Mem0 "State of AI Agent Memory 2026" / Zep・Graphiti / Letta 各種比較記事（atlan.com, vectorize.io, graphlit.com ほか。ベンダー発信のため相互に利害あり — 係争中の数値は本報告では判断材料から除外）

**未確認事項の明示**
- agmsg の性能・信頼性は外部情報源なし（社内実績のみ）。WORKPLAN F1 で実測検証タスクを設定。
- ACE の改善幅（+10.6% 等）の自社タスクでの再現性は未検証。F6 の A/B 評価で実測。
