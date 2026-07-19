# a004 Sandbox Record

- status: completed
- filesystem: workspace-write
- network: GitHub (`github.com`, `api.github.com`) と Apache 公式 license endpoint のみ使用
- escalation: sandbox DNS/API 接続が失敗した場合だけ、Apache canonical text の read-only fetch、PR 作成、CI status check を同一操作で再実行
- git operations: feature branch の switch / stage / commit / push、PR 作成、squash merge、branch 削除のみ
- manual-edit proof: index に一時改変を stage して検出を実証後、canonical 生成物へ復元
- generated cache: test import が作った `ci/__pycache__/` は commit 前に system temporary directory へ退避し、以後 `python3 -B` でローカル検証
- protected path handling: orchestrator 管理の task/acceptance、a002/a003 artifacts、docs/protection/hooks は未変更・未 stage
- forbidden actions: docs 本文変更、protection/hook 変更、force-push、main 直接 push、依存追加、他 repository 操作はいずれも未実施
