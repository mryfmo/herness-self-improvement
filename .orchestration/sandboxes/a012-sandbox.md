# a012 Sandbox Record

- status: completed
- filesystem: workspace-write
- network: GitHub (`github.com`, `api.github.com`) の push / PR / CI / merge 操作のみ
- external web fetch: not used
- branch: `a012/adr-0007-loop-graph-anchoring`（merge 後に local / remote とも削除）
- source commit: `0964af7ed74b73bd3ba902c274e3f2e40ad0ca65`
- squash merge: `a782c2359671871f75acd29e3c56a1b1123c9fa2`
- allowed documents: ADR-0007 と ADR index 1 行
- allowed evidence: a012 report / validation / sandbox / learning / autoskill
- source handling: task file を最初に読み、task 指定事項とリポジトリ内文書だけを参照
- external source handling: task 指定 X URL は文字列として記載し、取得していない
- git operations: feature branch の作成、許可2文書の stage / commit / push、PR #11 作成、squash merge、main checkout、branch 削除
- existing worktree handling: a002 task file、先行 acceptance/artifacts、並行 task files、`ci/__pycache__` は未変更・未stage
- forbidden actions: 4 保護文書・既存 ADR-0001〜0006 の変更、外部 Web fetch、protection/hooks 変更、dependency 変更、force-push、main 直接 pushはいずれも未実施

