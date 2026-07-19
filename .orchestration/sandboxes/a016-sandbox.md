# a016 Sandbox Record

- status: completed
- filesystem: workspace-write
- network: GitHub (`github.com`, `api.github.com`) の push / PR / CI / merge 操作のみ
- external web fetch: not used
- branch: `a016/migration-freeze-fixes`（merge 後に local / remote とも削除）
- source commit: `5fb24b02d777d10f4bb7abccc11b3a4b3c9e5083`
- squash merge: `53db170c5f4470a9fd146621995a08455a78978b`
- allowed product files: migrate script、migration / ledger tests、frozen paths / manifest、evidence-and-gates reference
- allowed evidence: a016 report / validation / sandbox / learning / autoskill
- source handling: task file を最初に読み、許可された a014 report、リポジトリ実装、過去 learn だけを参照
- database handling: `mktemp` で作成した scratch SQLite DB のみ使用し、実運用 agmsg DB は未使用
- git operations: feature branch の作成、許可6ファイルの stage / commit / push、PR #14 作成、squash merge、main checkout、branch 削除
- existing worktree handling: a002 task file、先行 acceptance/artifacts、並行 task files、`ci/__pycache__` は未変更・未stage
- forbidden actions: 4文書・ADR群・三軸規律本文の変更、外部 Web fetch、protection/hooks 変更、dependency 変更、force-push、main 直接 push、実運用 agmsg DB 操作はいずれも未実施
