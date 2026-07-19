# a002 Sandbox Record

- status: completed-with-compensating-controls
- filesystem: workspace-write
- network: GitHub (`github.com`, `api.github.com`) のみ使用
- escalation: sandbox が `.git` ref/config/object 書込みまたは GitHub 接続を拒否した場合のみ、task で明示許可された同一操作を再実行
- git operations: task a002 と補遺 r1 で明示許可された init / switch / move / config / commit / push / pull / squash merge のみ
- forbidden actions: force-push、履歴改変、public 化、他 repository 操作、依存変更はいずれも未実施
- server-side limitation: private repository の branch protection / ruleset は HTTP 403
- compensating controls: version-controlled pre-push hook + PR #1 + CI
