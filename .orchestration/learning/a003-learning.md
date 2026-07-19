# a003 Learning Triage

- disposition: candidate-only
- promoted: false
- learning: Git は空ディレクトリを追跡しないため、骨格タスクでは `.gitkeep` と CI の `test -d` を組み合わせると、意図した構造を最小差分で維持できる。
- evidence: 実装前に 6 ディレクトリ欠如で検査が失敗し、`.gitkeep` 追加後はローカル CI と PR CI が成功した。
- apply_to: repository skeleton tasks
- ceiling: ディレクトリに実ファイルが追加された時点で不要な `.gitkeep` は削除できる。
- promotion: task では禁止されているため未実施
