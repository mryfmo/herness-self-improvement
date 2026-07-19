# a009 Sandbox Record

- status: completed
- filesystem: workspace-write
- network: GitHub (`github.com`, `api.github.com`) のbranch/Actions/PR/CI操作のみ
- tests: temporary directory内のsynthetic README/docs/exemptionだけを作成し、終了時に削除
- fail proof: push-only temporary branchへ不正文書1件をcommitし、CI failure URL取得後にremote/local branchを削除。PRは未作成
- live database: agmsgの実運用databaseにread/write/schema applicationは未実施
- git operations: feature branchと一時proof branchのswitch / stage / commit / push、proof branch削除、PR作成、squash merge、feature branch削除のみ
- protected path handling: WORKPLAN 2 versions、SPEC、REPORT、ADR bundle、protection/hooksは未変更・未stage
- existing worktree: orchestrator管理task/acceptanceと先行task artifactsは未変更・未stage
- forbidden actions: protected document body change、force-push、main直接push、依存追加、live agmsg DB使用はいずれも未実施
