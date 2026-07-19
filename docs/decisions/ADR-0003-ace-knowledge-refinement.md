---
owner: mryfmo
last-verified: 2026-07-19
freshness: 180d
---

# ADR-0003: 知識還流・スキル最適化に ACE 型（Reflector/Curator・デルタ更新・grow-and-refine）を採用する
旧呼称: ADR-H003

- Status: Accepted
Accepted: 2026-07-18 mryfmo 決裁(WORKPLAN v1.1 Decision Log #4)
- Context: Wiki・SKILLS を LLM に継続更新させると、一括リライトによる「コンテキスト崩壊」（詳細の消失）と「簡潔化バイアス」が発生することが知られている。
- Decision: 更新は常にデルタ単位（追記 / 行更新 / 重複統合 / 陳腐化削除）に限定し、Generator（実務セッション）/ Reflector（教訓抽出）/ Curator（デルタ構成）の分業で還流する。一括リライトは CI が diff 比率（既定 40% 超）で検出し人間承認へ格上げ。定期 GC が重複排除と鮮度管理を行う。
- Consequences: (+) 知識の詳細が保存され、変更が小さくレビュー可能。改善効果を A/B で実測できる。(−) 大規模リファクタは人間承認付きの例外フローが必要。役割別プロンプトの保守コスト。
- 根拠: ACE（arXiv:2510.04618、+10.6%/エージェント、教師ラベル不要、公開実装あり）。Dynamic Cheatsheet 系譜。OpenAI の夜間 GC（逸脱スキャン → 小刻みな是正 PR）という本番実証。RIZZ（arXiv:2606.20638）による粒度別プレイブックへの一般化。
