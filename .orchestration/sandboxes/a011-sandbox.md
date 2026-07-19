# a011 Sandbox Record

- status: completed
- filesystem: workspace-write
- network: GitHub (`github.com`, `api.github.com`) の push / PR / CI / merge 操作のみ
- external web fetch: not used
- branch: `a011/llm-wiki-genealogy`（merge 後に local / remote とも削除）
- source commit: `fb4469218975f29d8e11fb7dae8f2d0efd124dfd`
- squash merge: `664ac7374037d99235612c4f2894bf4728472eb7`
- allowed document: `docs/reference/llm-wiki-genealogy.md`
- allowed evidence: a011 report / validation / sandbox / learning / autoskill
- source handling: task file を最初に読み、task の列挙事項とリポジトリ内文書だけを参照
- external source handling: task 指定 gist URL は文字列として記載し、取得していない
- git operations: feature branch の作成、許可文書だけの stage / commit / push、PR #10 作成、squash merge、main checkout、branch 削除
- protected path handling: 4 保護文書と他文書は未変更
- existing worktree handling: a002 task file、先行 acceptance/artifacts、`ci/__pycache__` は未変更・未stage
- forbidden actions: 外部 Web fetch、protection/hooks 変更、dependency 変更、force-push、main 直接 push はいずれも未実施
