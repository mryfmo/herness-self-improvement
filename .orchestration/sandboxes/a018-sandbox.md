# a018 Sandbox

- execution: local workspace-write sandbox
- repository: `mryfmo/herness-self-improvement`
- branch flow: `a018/workplan-v1.2-audit-integration` → PR #16 → squash merge → remote branch delete
- OpenSandbox: not used。文書 2 件の変更とローカル検証で完結し、追加隔離環境を必要としなかった。
- write boundary: v1.1、v1.2、a018 の 5 artifact のみ。
- existing dirty worktree: a002 task file、既存 `.orchestration/` artifact、`ci/__pycache__/` を変更・stage・commit せず保存した。merge 時の autostash は正常に復元された。
- network: GitHub の `git` / `gh` 操作だけを許可範囲内で使用。外部 Web 取得なし。
- forbidden actions: SPEC / REPORT / ADR / discipline / protection / hooks / dependency は変更していない。force-push と main 直接 push も行っていない。
- dependency changes: none
- secrets: `python3 ci/secret-scan.py` pass。artifact に credential や raw secret は含めていない。
