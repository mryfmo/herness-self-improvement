---
owner: mryfmo
last-verified: 2026-07-19
freshness: 90d
---

# Branch protection

## Rationale

[WORKPLAN v1.1 の Decision Log #2](../plans/WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.1.md#decision-log) は、private repository `mryfmo/herness-self-improvement` の main 保護、PR 必須、CI 必須を決定している。単独運用のため required approving reviews は 0 とし、それ以外の変更経路と破壊操作は制限する。

## Current limitation

GitHub Free の private repository では branch protection と repository ruleset API が HTTP 403 を返す。サーバー側保護の有効化は、GitHub Pro 化または public 化に関するユーザー決裁待ちとする。

## Compensating controls

- version-controlled `githooks/pre-push` が、`ALLOW_MAIN_PUSH=1` の明示的な許可なしで `main` へ push する操作を拒否する。
- clone 後に `git config core.hooksPath githooks` を実行して hook を有効化する。
- 通常変更は feature branch、pull request、CI `ci` を経由する。

`ALLOW_MAIN_PUSH=1` は承認済み bootstrap または復旧操作だけに使用する。

## Server-side reproduction

サーバー側保護を利用できるプランになったら、repository 管理者として次を実行する。PR 必須、required status check `ci`、force-push/削除禁止、required approving reviews 0 を再現する。

```sh
jq -n '{
  required_status_checks: {strict: true, contexts: ["ci"]},
  enforce_admins: true,
  required_pull_request_reviews: {
    dismiss_stale_reviews: false,
    require_code_owner_reviews: false,
    required_approving_review_count: 0
  },
  restrictions: null,
  required_linear_history: false,
  allow_force_pushes: false,
  allow_deletions: false,
  block_creations: false,
  required_conversation_resolution: false,
  lock_branch: false,
  allow_fork_syncing: false
}' |
  gh api --method PUT \
    repos/mryfmo/herness-self-improvement/branches/main/protection \
    --input -
```
