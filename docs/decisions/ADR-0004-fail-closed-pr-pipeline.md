---
owner: mryfmo
last-verified: 2026-07-19
freshness: 180d
---

# ADR-0004: 自動生成・自動最適化は fail-closed の 6 段 PR パイプラインに限定する（無人デプロイ禁止）
旧呼称: ADR-H004

- Status: Accepted
Accepted: 2026-07-18 mryfmo 決裁(WORKPLAN v1.1 Decision Log #4)
- Context: 繰り返しプロンプトからの SKILLS/Hooks/Rules/SubAgents 自動生成は要件だが、2026 年時点の研究はスキル自動生成の成功率をおおむね 7 割前後と報告しており、スキル供給網への攻撃も実証されている。
- Decision: パターン検出 → ドラフト生成（skill-creator 規約）→ 隔離検証（スキルあり/なし差分測定）→ 評価スイート → PR 起票 → 承認、の 6 段を必須とし、いずれかの不合格で停止（fail-closed）。Hooks・Rules・自己改善パイプライン自身の変更は自動マージ対象外（常に人間承認）。周期あたり起票上限を設ける。
- Consequences: (+) 品質不良・悪性生成物が本番へ到達しない。承認負荷は上限値で制御。(−) 反映速度は無人型より遅い。承認者の稼働が前提（名簿 TBD(HUMAN)）。
- 根拠: MUSE-Autoskill の生成成功率 68.6% 報告。SkillsBench のスキル効果の非一様性。EvoSkills の検証必須性の指摘。ToxicSkills / PoisonedSkills が示す供給網リスク。既存全社方針（closed gates / fail-closed）との整合。
