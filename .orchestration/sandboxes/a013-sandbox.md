# a013 Sandbox Record

- status: completed
- filesystem: workspace-write
- network: GitHub (`github.com`, `api.github.com`) の push / PR / CI / merge 操作のみ
- external web fetch: not used
- branch: `a013/adr-0008-recursive-self-improvement-strata`（merge 後に local / remote とも削除）
- source commit: `d995a60376a827b783f98ac46dc45b54be5debd9`
- squash merge: `43bc6c99b5746bfb24ad4ae199810f5a48d2d075`
- allowed documents: ADR-0008 と ADR index 1 行
- allowed evidence: a013 report / validation / sandbox / learning / autoskill
- source handling: task file を最初に読み、task 指定事項とリポジトリ内文書だけを参照
- external source handling: task 指定 arXiv ID は文字列として記載し、取得していない
- git operations: feature branch の作成、許可 2 文書の stage / commit / push、PR #12 作成、squash merge、main checkout、branch 削除
- existing worktree handling: a002 task file、先行 acceptance/artifacts、並行 task files、`ci/__pycache__` は未変更・未stage
- forbidden actions: 4 保護文書・既存 ADR-0001〜0007 の変更、外部 Web fetch、protection/hooks 変更、dependency 変更、force-push、main 直接 push はいずれも未実施
