# a008 Sandbox Record

- status: completed
- filesystem: workspace-write
- network: GitHub (`github.com`, `api.github.com`) のPR/CI操作のみ
- live database: agmsgの実運用databaseにread/write/schema applicationは未実施
- evidence tests: repository外の一時SQLite DBへmigrationを適用し、終了時に削除
- freeze tests: repository外の一時treeでmodification/addition/deletionを検証し、終了時に削除
- secret tests: 無害なdummyをruntimeで組み立てた一時treeだけで検出し、値をoutputへ表示せず終了時に削除
- AIDD handling: 指定された近縁source 2件を読み取り参照しただけで、copy、write、commitは未実施
- git operations: feature branchのswitch / stage / commit / push、PR作成、squash merge、branch削除のみ
- protected path handling: orchestrator管理task/acceptance、先行task artifacts、保護4文書、protection/hooksは未変更・未stage
- forbidden actions: live agmsg DB使用、AIDDコードコピー/変更、force-push、main直接push、依存追加はいずれも未実施
