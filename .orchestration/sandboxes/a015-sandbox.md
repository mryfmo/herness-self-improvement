# a015 Sandbox Record

- status: completed
- filesystem: workspace-write
- network: GitHub (`github.com`, `api.github.com`) の push / PR / CI / merge 操作のみ
- external web fetch: not used
- branch: `a015/discipline-and-adr-acceptance`（merge 後に local / remote とも削除）
- source commit: `55d6fd30131fedc7d15037431a2bce70ae5eab0c`
- squash merge: `56e2d443f3485caf2b324c8671333eebd8048802`
- allowed product files: discipline、ADR-0007/0008 の指定 2 行、ADR index、README、rules source、生成済み CLAUDE / AGENTS
- allowed evidence: a015 report / validation / sandbox / learning / autoskill
- source handling: task file を最初に読み、task 指定事項とリポジトリ内文書だけを参照
- git operations: feature branch の作成、許可 8 文書の stage / commit / push、PR #13 作成、squash merge、main checkout、branch 削除
- existing worktree handling: a002 task file、先行 acceptance/artifacts、並行 task files、`ci/__pycache__` は未変更・未stage
- forbidden actions: 4 保護文書・ADR-0001〜0006・ADR-0007/0008 の指定外行の変更、外部 Web fetch、protection/hooks 変更、dependency 変更、force-push、main 直接 push はいずれも未実施
