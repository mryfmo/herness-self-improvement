# a030 Sandbox

- repository: `/Users/mryfmo/Workspace/herness-self-improvement`
- branch: `a030/third-party-vendor`
- task-file-first: inbox の task file と secret-scan addendum を全文読了後、ledger を
  claim / start
- ledger id: `hx-ff8b32a66241252f92bdb6dca8bcb629`
- acquisition: task が許可した pinned GitHub API / shallow clone と local cache / skill
  read のみ。Git source は `/private/tmp/herness-a030.LOmltR`
- product writes: vendor 7件、registry、NOTICE、exact allowlist、同 allowlist の frozen
  manifest hash に限定
- artifact writes: a030 report / validation / sandbox / learning / autoskill
- dependencies: 追加・installなし
- vendor boundary: payload無改変。追加は PROVENANCE と D4 LICENSE notice のみ
- execution boundary: vendor script / hook / skill は実行せず、既存実行経路へ接続なし
- secret boundary: raw allowlist value は validation に転記せず、SHA-256 prefix のみ記録
- forbidden actions: force-push、main直接push、scanner除外・弱体化、githook、ADR、
  4文書、規律文書、dependency の変更なし
- worklog: task Allowed files に含まれないため `.agents/worklog/codex/` は更新せず、
  turn plan と必須 artifact で進行管理
- existing dirty worktree: a019以降の未追跡 orchestration files と `ci/__pycache__/` は
  stage、変更、削除していない
