# a005 Sandbox Record

- status: completed
- filesystem: workspace-write
- network: GitHub (`github.com`, `api.github.com`) の PR/CI 操作のみ
- database isolation: migration test は test が所有する system temporary database path だけを使用
- live database: agmsg の実運用 database に read/write/schema application は未実施
- git operations: feature branch の switch / stage / commit / push、PR 作成、squash merge、branch 削除のみ
- protected path handling: orchestrator 管理の task/acceptance、先行 task artifacts、指定外 docs/protection/hooks は未変更・未 stage
- forbidden actions: live agmsg schema 変更、force-push、main 直接 push、依存追加、他 repository 操作はいずれも未実施
