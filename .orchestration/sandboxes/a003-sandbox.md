# a003 Sandbox Record

- status: completed
- filesystem: workspace-write
- network: GitHub (`github.com`, `api.github.com`) のみ使用
- escalation: sandbox 内の `gh pr create` が GitHub API 接続に失敗したため、同一の task 許可済み PR 作成操作だけを再実行
- git operations: feature branch の switch / commit / push、PR 作成、squash merge、branch 削除のみ
- protected path handling: orchestrator 管理の task/acceptance と a002 artifacts は未変更・未 stage
- forbidden actions: 4 文書本文変更、protection 変更、force-push、main 直接 push、依存追加、他 repository 操作はいずれも未実施
- local tooling limitation: `tree` は未導入のため exit 127、stdlib の `find` で depth-3 構造を検証
