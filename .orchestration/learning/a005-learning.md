# a005 Learning Triage

- disposition: candidate-only
- promoted: false
- learning: SQLite CLI migration は `.bail on`、明示 transaction、事前の action/file validation を組み合わせないと、SQL error 後にも後続 statement が走って部分適用を見逃し得る。注入 database path と namespace を併用すると、物理 DB の同居/分離を後決めにしたまま schema 契約を先に検証できる。
- evidence: up/up/down/down/up、FTS5、FK、append-only、WAL/busy timeout の隔離DB test と PR #4 CI green。
- apply_to: SQLite migration runners and isolated schema tests
- ceiling: concurrent writer 負荷に基づく DB 同居/分離と busy timeout の恒久値は P1-F1-T5 の計測まで決めない。
- promotion: task では禁止されているため未実施
