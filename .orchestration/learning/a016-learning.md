# a016 Learning Triage

- disposition: reusable-implementation-rule
- promoted: false
- migration status: 適用対象の正規集合を migration ファイル名から導出すれば、status の固定リストが schema 追加時に古くなる問題を避けられる。pending を表示するだけでなく、終了値にも反映させる。
- regression shape: 一部 migration 欠落の試験は、最新 entry と対応 table だけを削除し、古い migration が applied、最新が pending、終了値が非ゼロになる三点を同時に固定する。
- freeze boundary: checkout 内の hash manifest は変更を止める権限境界ではない。凍結対象と manifest の同時 diff を強制可視化し、承認権限は人間に置く。
- apply_to: 将来の migration 追加、frozen paths 拡張、a017 の NFR-01 整合
- evidence: `db/migrate.sh`、`ci/test_migrations.sh`、`docs/reference/evidence-and-gates.md`、PR #14
- promotion: task は rule promotion を許可していないため未実施
