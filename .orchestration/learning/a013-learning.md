# a013 Learning Triage

- disposition: required-downstream-contract
- promoted: false
- learning: 改善機構を変更する L2 ループは、その機構の出力に接地したメタ指標で駆動し、人間承認、カナリア、悪化時のロールバック提案を伴う必要がある。統治機構を自動変更する L3 再帰は認めない。
- F3-T6: Reflector/Curator のプロンプト改訂タスクに、採択率・修正率などのメタ指標の記録と、変更後のカナリア接続を要件として含める。採択率 60% 以上を先行基準とし、実測値を L2 変更 PR 本文へ記載する。
- F6: optimizer 出力の統計的再評価と F6-T5 の自動ロールバック提案タスクに、誤起票率・ロールバック率などのメタ指標記録と、次周期の悪化を判定するカナリア接続を要件として含める。
- change bound: L2 変更は 1 ループにつき 1 周期 1 件までとし、悪化時は F6-T5 で自動ロールバックを提案する。
- governance boundary: 起票上限、diff 閾値、承認要件、timeout、昇格閾値は L3 所有で、自動提案による緩和を認めない。
- evidence: ADR-0008 Decision 1〜5
- apply_to: P1-F3-T6, Phase F6, P1-F6-T5
- promotion: 後続実装文書への直接変更は task の許可範囲外のため未実施
