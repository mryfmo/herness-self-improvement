---
owner: mryfmo
last-verified: 2026-07-19
freshness: 180d
---

# ADR-0005: 3 層スコープ（全社 marketplace / プロジェクト .claude / 個人 ~/.claude）と一方向昇格パイプライン
旧呼称: ADR-H005

- Status: Accepted
Accepted: 2026-07-18 mryfmo 決裁(WORKPLAN v1.1 Decision Log #4)
- Context: 業務（組織）・プロジェクト・ユーザーの各単位でスコープを分離しつつ、孤立させず調和させる要件がある。
- Decision: Claude Code のネイティブスコープ機構に 3 層を写像する。優先順位はプロジェクト > 個人 > 全社。frontmatter `scope` と命名接頭辞を必須化。昇格は利用統計閾値 → Curator による汎化ドラフト → 上位スコープへの PR（scan + eval + 上位承認者必須）の一方向フローとし、降格・廃止も同フローで扱う。層をまたぐ重複・矛盾は GC が検出する。
- Consequences: (+) 個人の工夫が統制された経路で全社資産へ育つ。製品ネイティブ機構に乗るため実装が薄い。(−) 昇格時の汎化品質（固有情報の除去）に検査が必要。閾値チューニングの運用負荷。
- 根拠: Claude Code の settings/skills スコープ優先順位と marketplace 機能（公式）。RIZZ の branch-local / family / global プレイブック分離による干渉最小化の知見。
