# a017 Sandbox Record

- status: completed
- filesystem: workspace-write
- network: GitHub (`github.com`, `api.github.com`) の push / PR / CI / merge 操作のみ
- external web fetch: not used
- branch: `a017/spec-v1.1-three-axis`（merge 後に local / remote とも削除）
- source commit: `cb1e57fc4034cb13ebe0f13dfc8484aa9cb6277e`
- squash merge: `051cc46c952e81a708a13006465f6a82fbb40bfe`
- allowed product files: SPEC v1.1 新規、SPEC v1.0 Superseded 1行、frontmatter exemption（変更不要）
- allowed evidence: a017 report / validation / sandbox / learning / autoskill
- source handling: task fileを最初に読み、taskが列挙した全入力を本文作成前に全文確認
- frozen handling: `docs/specs/discipline-v1.0.md` は参照のみ。SPEC files は frozen paths 対象外で、manifest は変更していない
- git operations: feature branch の作成、許可2文書の stage / commit / push、PR #15 作成、squash merge、main checkout、branch削除
- existing worktree handling: a002 task file、先行 acceptance/artifacts、並行 task files、`ci/__pycache__` は未変更・未stage
- forbidden actions: v1.0 の指定外変更、WORKPLAN / REPORT / ADR / discipline の変更、外部 Web fetch、protection/hooks 変更、dependency 変更、force-push、main 直接 pushはいずれも未実施
