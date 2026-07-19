---
owner: mryfmo
last-verified: 2026-07-19
freshness: 180d
---

# ADR-0001: Git を単一の真実源とし、ハーネス artefact の変更を PR 駆動に限定する
旧呼称: ADR-H001

- Status: Accepted
Accepted: 2026-07-18 mryfmo 決裁(WORKPLAN v1.1 Decision Log #4)
- Context: LLM Wiki・SKILLS・Rules・Hooks・SubAgents・Workflows という複数種の artefact を、複数エージェント（Claude Code / Codex）と複数の自動ジョブが更新する。更新主体が増えるほど、レビュー可能性・ロールバック可能性・由来追跡が成立条件になる。
- Decision: 全 artefact を Git 管理し、反映経路を PR のみに限定する。エージェント・ジョブによる直接 push は Hooks と CI の双方で拒否する。CLAUDE.md / AGENTS.md は単一ソース rules.src.md から生成し、約 120 行の「マップ」に保って詳細は docs/（Wiki）へ委譲する。
- Consequences: (+) 全変更が diff・承認・履歴で統制でき、二重管理（CLAUDE.md/AGENTS.md）が生成で解消。(−) 反映レイテンシが PR フロー分だけ増える。緊急変更も PR 経由（ただし承認者による即時マージは可）。
- 根拠: OpenAI ハーネスエンジニアリング報告（2026-02、AGENTS.md をマップ化し構造化 docs/ + CI + 夜間 GC で維持する構成へ収斂した実証）。Claude Code 公式の設定スコープ・保護機構。AIDD Platform 既定方針（Claude Code を唯一のエントリポイントとする）との整合。
