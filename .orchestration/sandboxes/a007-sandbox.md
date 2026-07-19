# a007 Sandbox Record

- status: completed
- filesystem: workspace-write
- network: GitHub (`github.com`, `api.github.com`) のPR/CI操作のみ
- long runs: hxとmixedをrepository外の別scratch DBで各600秒、直列実行
- database safety: harnessは既存DBとホーム `.agents` 配下を拒否
- live database: agmsgの実運用databaseにread/write/schema applicationは未実施
- measurement isolation: run中の追加queryを避け、終了後だけ件数・integrityを確認
- cleanup: writer別raw latencyはharness-owned temporary directoryから終了時に削除
- git operations: feature branchのswitch / stage / commit / push、PR作成、squash merge、branch削除のみ
- protected path handling: orchestrator管理task/acceptance、先行task artifacts、指定外docs/protection/hooksは未変更・未stage
- forbidden actions: live agmsg DB使用、force-push、main直接push、依存追加、他repository操作はいずれも未実施
