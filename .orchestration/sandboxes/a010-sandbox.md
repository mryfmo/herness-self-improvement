# a010 Sandbox Record

- status: completed
- filesystem: workspace-write
- network: GitHub (`github.com`, `api.github.com`) のPR/CI操作のみ
- fidelity workspace: normalization verifierと比較用2 filesはrepository外temporary pathに置き、commit対象外
- source handling: bundle 6 sectionsをread-only baselineとして抽出し、許可されたmetadata差分だけを逆変換してline diff
- git operations: feature branchのswitch / stage / commit / push、PR作成、squash merge、branch削除のみ
- protected path handling: bundleは指定line 1だけ追加。他3保護文書、orchestrator task/acceptance、先行task artifactsは未変更・未stage
- forbidden actions: bundle本文改変、他文書変更、protection/hooks変更、force-push、main直接push、依存追加はいずれも未実施
