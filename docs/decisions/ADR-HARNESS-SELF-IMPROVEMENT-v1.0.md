Status: 分割登録済み(ADR-0001〜0006 参照)。本書は審議時の歴史的資料。
# ADR-HARNESS-SELF-IMPROVEMENT v1.0（ADR 束）

本ファイルは審議用の束。承認後、対象リポジトリの ADR 規約（new-adr スキル規約、採番開始 TBD(HUMAN)）に従い 1 決定 1 ファイルへ分割して登録する（WORKPLAN P1-F1-T8）。各 ADR の形式: Status / Context / Decision / Consequences / 根拠。

---

## ADR-H001: Git を単一の真実源とし、ハーネス artefact の変更を PR 駆動に限定する

- Status: Proposed
- Context: LLM Wiki・SKILLS・Rules・Hooks・SubAgents・Workflows という複数種の artefact を、複数エージェント（Claude Code / Codex）と複数の自動ジョブが更新する。更新主体が増えるほど、レビュー可能性・ロールバック可能性・由来追跡が成立条件になる。
- Decision: 全 artefact を Git 管理し、反映経路を PR のみに限定する。エージェント・ジョブによる直接 push は Hooks と CI の双方で拒否する。CLAUDE.md / AGENTS.md は単一ソース rules.src.md から生成し、約 120 行の「マップ」に保って詳細は docs/（Wiki）へ委譲する。
- Consequences: (+) 全変更が diff・承認・履歴で統制でき、二重管理（CLAUDE.md/AGENTS.md）が生成で解消。(−) 反映レイテンシが PR フロー分だけ増える。緊急変更も PR 経由（ただし承認者による即時マージは可）。
- 根拠: OpenAI ハーネスエンジニアリング報告（2026-02、AGENTS.md をマップ化し構造化 docs/ + CI + 夜間 GC で維持する構成へ収斂した実証）。Claude Code 公式の設定スコープ・保護機構。AIDD Platform 既定方針（Claude Code を唯一のエントリポイントとする）との整合。

## ADR-H002: メモリ二層構造（SQLite 体験層 + Git 恒久層）。外部メモリ SaaS と重み更新型自己改善は不採用

- Status: Proposed
- Context: Agents Memory の実現方式は (a) 外部メモリ基盤（Mem0 / Zep / Letta 等）、(b) モデル重みへの内在化（RL/FT）、(c) ファイル・DB による自前二層、の 3 系統がある。
- Decision: (c) を採用。体験層（episodic）= SQLite（agmsg 拡張スキーマ）に全セッション・ツール・スキルイベントを記録。恒久層（semantic/procedural）= Git 上の Wiki / SKILLS へ Reflector/Curator が還流。検索は FTS5 + frontmatter。外部メモリ基盤は `memory_export` ビューを介した将来拡張に留め、v1 では導入しない。重み更新型は不採用。
- Consequences: (+) Claude Code / Codex がネイティブに読む形式（Markdown/Git）に恒久知識が直接乗り、監査・ロールバック・可搬性が Git の機構で担保される。運用部品が増えない。(−) グラフ推論・高度な時制推論は当面持たない（必要性が実証された時点で再評価）。再評価条件: 体験層クエリの再現率不足が実測で示され、かつ Graphiti 等の自ホスト運用コストを許容する決裁が出た場合。
- 根拠: メモリ基盤のベンチマーク（LoCoMo）を巡る Mem0 / Zep の相互反論が未決着であること。Zep のトークンフットプリント（1 会話 60 万トークン級の報告）と取込直後検索失敗、Mem0 の大規模時インデックス信頼性問題の報告。重み更新型（SEAgent 等）の非検査性・非移植性は研究側（EvoSkills）も難点として明記。二重モデル体制（Claude/Codex）では重み内在化は共有不能。

## ADR-H003: 知識還流・スキル最適化に ACE 型（Reflector/Curator・デルタ更新・grow-and-refine）を採用する

- Status: Proposed
- Context: Wiki・SKILLS を LLM に継続更新させると、一括リライトによる「コンテキスト崩壊」（詳細の消失）と「簡潔化バイアス」が発生することが知られている。
- Decision: 更新は常にデルタ単位（追記 / 行更新 / 重複統合 / 陳腐化削除）に限定し、Generator（実務セッション）/ Reflector（教訓抽出）/ Curator（デルタ構成）の分業で還流する。一括リライトは CI が diff 比率（既定 40% 超）で検出し人間承認へ格上げ。定期 GC が重複排除と鮮度管理を行う。
- Consequences: (+) 知識の詳細が保存され、変更が小さくレビュー可能。改善効果を A/B で実測できる。(−) 大規模リファクタは人間承認付きの例外フローが必要。役割別プロンプトの保守コスト。
- 根拠: ACE（arXiv:2510.04618、+10.6%/エージェント、教師ラベル不要、公開実装あり）。Dynamic Cheatsheet 系譜。OpenAI の夜間 GC（逸脱スキャン → 小刻みな是正 PR）という本番実証。RIZZ（arXiv:2606.20638）による粒度別プレイブックへの一般化。

## ADR-H004: 自動生成・自動最適化は fail-closed の 6 段 PR パイプラインに限定する（無人デプロイ禁止）

- Status: Proposed
- Context: 繰り返しプロンプトからの SKILLS/Hooks/Rules/SubAgents 自動生成は要件だが、2026 年時点の研究はスキル自動生成の成功率をおおむね 7 割前後と報告しており、スキル供給網への攻撃も実証されている。
- Decision: パターン検出 → ドラフト生成（skill-creator 規約）→ 隔離検証（スキルあり/なし差分測定）→ 評価スイート → PR 起票 → 承認、の 6 段を必須とし、いずれかの不合格で停止（fail-closed）。Hooks・Rules・自己改善パイプライン自身の変更は自動マージ対象外（常に人間承認）。周期あたり起票上限を設ける。
- Consequences: (+) 品質不良・悪性生成物が本番へ到達しない。承認負荷は上限値で制御。(−) 反映速度は無人型より遅い。承認者の稼働が前提（名簿 TBD(HUMAN)）。
- 根拠: MUSE-Autoskill の生成成功率 68.6% 報告。SkillsBench のスキル効果の非一様性。EvoSkills の検証必須性の指摘。ToxicSkills / PoisonedSkills が示す供給網リスク。既存全社方針（closed gates / fail-closed）との整合。

## ADR-H005: 3 層スコープ（全社 marketplace / プロジェクト .claude / 個人 ~/.claude）と一方向昇格パイプライン

- Status: Proposed
- Context: 業務（組織）・プロジェクト・ユーザーの各単位でスコープを分離しつつ、孤立させず調和させる要件がある。
- Decision: Claude Code のネイティブスコープ機構に 3 層を写像する。優先順位はプロジェクト > 個人 > 全社。frontmatter `scope` と命名接頭辞を必須化。昇格は利用統計閾値 → Curator による汎化ドラフト → 上位スコープへの PR（scan + eval + 上位承認者必須）の一方向フローとし、降格・廃止も同フローで扱う。層をまたぐ重複・矛盾は GC が検出する。
- Consequences: (+) 個人の工夫が統制された経路で全社資産へ育つ。製品ネイティブ機構に乗るため実装が薄い。(−) 昇格時の汎化品質（固有情報の除去）に検査が必要。閾値チューニングの運用負荷。
- 根拠: Claude Code の settings/skills スコープ優先順位と marketplace 機能（公式）。RIZZ の branch-local / family / global プレイブック分離による干渉最小化の知見。

## ADR-H006: スキル供給網ガバナンス — 社内レジストリ限定・スキャン必須・動的コンテキスト禁止・自己改変の人間承認

- Status: Proposed
- Context: スキルはエージェントの全権限で動作する事実上の実行可能依存物であり、2026 年に供給網攻撃が実証・観測されている（エコシステムの 36% に欠陥、悪性キャンペーン、難読化注入のバイパス率 11.6〜33.5%、SKILL.md 動的コンテキストの「モデルが読む前の」コマンド実行）。
- Decision: (1) 導入元は社内 marketplace と自リポジトリのみ（外部 marketplace は設定で無効化、第三者スキルの自動取込禁止）。(2) 取込・変更時の静的スキャン必須: 動的コンテキスト実行の検出＝即不合格、scripts 到達先の許可リスト照合、悪性パターン照合、秘密情報検出。(3) マージ時のハッシュ・由来記録と実行時ハッシュ照合。(4) PreToolUse deny-by-default とハーネス artefact への PR フロー外書込み全ブロック。(5) 自己改善パイプライン自身の変更は常に人間承認。(6) kill switch。(7) evidence store への全量監査と月次レポート。
- Consequences: (+) 実証済み攻撃面（供給網・動的コンテキスト・CI 注入）を構造的に遮断し、残存する難読化注入は権限最小化・監査・即時停止で被害限定。(−) 外部の有用スキルは人手審査を経た再パッケージが必要。開発体験に若干の摩擦。
- 根拠: Snyk ToxicSkills（2026-02）、PoisonedSkills（arXiv:2604.03081、Claude Code のスキル内容が専用許可プロンプトなしで実行指示扱いされる旨の開示を含む）、Datadog Security Labs（動的コンテキストリスク、2026-05）、MalSkillBench（arXiv:2606.07131）、claude-code-action の権限バイパス事例（CSA Research Note, 2026-06）。プロンプト注入がモデル層単独では解決不能である点は業界コンセンサス。
