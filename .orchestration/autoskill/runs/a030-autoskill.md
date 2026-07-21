# a030 AutoSkill Run

- status: not-generated
- reason: repository固有の vendor / governance integration であり、新規skillを作る作業ではない
- applied skills: agmsg, agmsg-orchestration, humanizer-ja, ponytail,
  gh-first-workflow
- agmsg effect: task file first、ledger claim / start、5 artifact、adapter result の順序を維持
- ponytail effect: vendor wrapper、dependency、独自scannerを追加せず、既存scannerの
  exact allowlist と Python standard library の整合性検証を使用
- humanizer effect: registry / provenance / evidence を事実を増やさず運用判断しやすい日本語へ整理
- gh-first effect: GitHub情報はghを先に用い、全差分を要約したPR本文とURLを記録
- output skill: none
