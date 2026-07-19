# a006 Learning Triage

- disposition: candidate-only
- promoted: false
- learning: 状態遷移を CLI の case 分岐だけで守らず SQLite trigger に集約すると、CLI と direct SQL の両方を同じ不変条件で拒否できる。条件付き UPDATE と message INSERT を同じ `BEGIN IMMEDIATE` に置けば、state と履歴の二重書込みも小さく原子的に保てる。
- evidence: 3 terminal paths、running/claimed requeue、不正 direct SQL、冪等 create、PR #5 の push/PR CI green。
- apply_to: SQLite-backed task ledgers and state machines
- ceiling: 複数プロセスでの lock contention と timeout 値の妥当性は P1-F1-T5 の負荷計測で判断する。
- promotion: task では禁止されているため未実施
