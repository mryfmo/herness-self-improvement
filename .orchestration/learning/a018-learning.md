# a018 Learning Triage

## Candidate

- title: versioned workplan の保存契約は集合比較だけでなく順序・名称・Owner・phase gate まで検証する
- learning: タスク ID の集合が一致しても、順序、名称、Owner、phase-level Tests / Done Criteria が古いままなら実行契約は drift する。今回、79 ID の集合比較に加えて順序・名称・Owner を独立照合し、FR-16 と FR-01〜16 の phase gate 漏れを検出できた。
- evidence: `docs/plans/WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.2.md`、`.orchestration/validation/a018-validation.md`
- reusable: yes
- validated: yes
- action: candidate only。orchestrator の判断なしに rule / skill へ昇格しない。

## Process note

- plan-quality gate は保管先が `plans/` という名前だけで横展開せず、対象リポジトリの schema と適用パターンを先に確認する。
- 外部 template と task-specific preservation contract が衝突する場合、template を移植せず、validator の非適用理由と reviewer checklist による代替レビューを証跡化する。
- 新規 learn worklog は allowed_files 外なので作成していない。本 artifact を学習トリアージの正本とする。
