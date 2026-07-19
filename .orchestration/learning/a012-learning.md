# a012 Learning Triage

- disposition: required-downstream-contract
- promoted: false
- learning: 自己改善の指標と LLM ルーブリックは、同じ仕組みが自分の正しさを再確認する循環を避けるため、対抗指標と接地測定を伴う必要がある。
- F2-T5: `docs/reference/metrics.md` は、成功率と訂正率、起票数と誤起票率のように、すべての指標をペア構造で定義する。各閾値・目標値には owner `mryfmo` と改訂周期も記録する。
- F5-T6/F6: SkillCoach 型ルーブリックなどの LLM 評価は派生指標として扱い、実行テスト/eval、人間のマージ・却下・訂正、実データ件数のうち 1 つ以上とペアにする。派生指標だけで最適化、昇格、削除、ロールバックを決定しない。
- F8-T7: 月次監査へ循環検査を加え、直近周期の各決定が接地指標に依拠したかを確認する。
- F9-T4: 起票上限、diff 比率、昇格閾値などの本値確定を、参照値の初回改訂ループとして扱う。
- evidence: ADR-0007 Decision 1 / 2 / 4 / 6
- apply_to: P1-F2-T5, P1-F5-T6, Phase F6, P1-F8-T7, P1-F9-T4
- promotion: 後続実装文書への直接変更は task の許可範囲外のため未実施

