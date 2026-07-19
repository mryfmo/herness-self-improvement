---
owner: mryfmo
last-verified: 2026-07-19
freshness: 180d
---

# ADR-0006: スキル供給網ガバナンス — 社内レジストリ限定・スキャン必須・動的コンテキスト禁止・自己改変の人間承認
旧呼称: ADR-H006

- Status: Accepted
Accepted: 2026-07-18 mryfmo 決裁(WORKPLAN v1.1 Decision Log #4)
- Context: スキルはエージェントの全権限で動作する事実上の実行可能依存物であり、2026 年に供給網攻撃が実証・観測されている（エコシステムの 36% に欠陥、悪性キャンペーン、難読化注入のバイパス率 11.6〜33.5%、SKILL.md 動的コンテキストの「モデルが読む前の」コマンド実行）。
- Decision: (1) 導入元は社内 marketplace と自リポジトリのみ（外部 marketplace は設定で無効化、第三者スキルの自動取込禁止）。(2) 取込・変更時の静的スキャン必須: 動的コンテキスト実行の検出＝即不合格、scripts 到達先の許可リスト照合、悪性パターン照合、秘密情報検出。(3) マージ時のハッシュ・由来記録と実行時ハッシュ照合。(4) PreToolUse deny-by-default とハーネス artefact への PR フロー外書込み全ブロック。(5) 自己改善パイプライン自身の変更は常に人間承認。(6) kill switch。(7) evidence store への全量監査と月次レポート。
- Consequences: (+) 実証済み攻撃面（供給網・動的コンテキスト・CI 注入）を構造的に遮断し、残存する難読化注入は権限最小化・監査・即時停止で被害限定。(−) 外部の有用スキルは人手審査を経た再パッケージが必要。開発体験に若干の摩擦。
- 根拠: Snyk ToxicSkills（2026-02）、PoisonedSkills（arXiv:2604.03081、Claude Code のスキル内容が専用許可プロンプトなしで実行指示扱いされる旨の開示を含む）、Datadog Security Labs（動的コンテキストリスク、2026-05）、MalSkillBench（arXiv:2606.07131）、claude-code-action の権限バイパス事例（CSA Research Note, 2026-06）。プロンプト注入がモデル層単独では解決不能である点は業界コンセンサス。
