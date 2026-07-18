# Branch protection

## Current limitation

GitHub Free の private repository では branch protection と repository ruleset API が HTTP 403 を返す。サーバー側保護の有効化は、GitHub Pro 化または public 化に関するユーザー決裁待ちとする。

## Compensating controls

- version-controlled `githooks/pre-push` が、`ALLOW_MAIN_PUSH=1` の明示的な許可なしで `main` へ push する操作を拒否する。
- clone 後に `git config core.hooksPath githooks` を実行して hook を有効化する。
- 通常変更は feature branch、pull request、CI `ci` を経由する。

`ALLOW_MAIN_PUSH=1` は承認済み bootstrap または復旧操作だけに使用する。

## Server-side migration

サーバー側保護が利用可能になったら、次の設定を適用し、PR 必須、required status check `ci`、force-push/削除禁止、required approving reviews 0 を有効にする。

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
