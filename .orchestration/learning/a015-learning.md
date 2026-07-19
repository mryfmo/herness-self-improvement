# a015 Learning Triage

- disposition: reusable-governance-pattern
- promoted: false
- learning: 分割された ADR 群の正規入口は、履歴上の束ファイルではなく、現行 ADR を列挙する index に置く。上位の README と生成ルールは同じ入口を参照させる。
- acceptance provenance: ADR の Proposed から Accepted への昇格は、Status 変更と決裁者・日付・指示を示す根拠行を隣接させると、本文を不変に保ったまま決裁履歴を監査できる。
- generated rules: 正規リンクや規律への参照を `rules.src.md` に追加したら、生成器の再実行と生成後の無差分検査を一組にする。
- apply_to: a017/a018 の正規リンク修正、将来の ADR 昇格、生成ルール変更
- evidence: `docs/specs/discipline-v1.0.md`、ADR-0007/0008 の限定 diff、PR #13
- promotion: 後続タスクの予約文書は a015 の許可範囲外であるため未変更
