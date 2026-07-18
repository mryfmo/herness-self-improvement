# Harness Self Improvement

単独運用では required approving reviews を 0 とし、Claude Code orchestrator の敵対的検証を人間レビューの代替とする。

clone 後に `git config core.hooksPath githooks` を実行し、main への直接 push をローカルで拒否する（[詳細](docs/reference/branch-protection.md)）。
