# a002 Validation

## Git history

```sh
git log --oneline
```

```text
8f3f82f chore: bootstrap PR-driven document layout (P1-F1-T0) (#1)
7360b5a ci: add bootstrap document check
84bee52 chore: bootstrap harness repository (P1-F1-T0)
```

3 commit とも `Agent: worker` trailer が存在する。`HEAD` と `origin/main` は `8f3f82f900a99edcdbca13d9a1e633289f670421` で一致する。

## Repository

```sh
gh repo view mryfmo/herness-self-improvement --json visibility,defaultBranchRef,url
```

```json
{
  "defaultBranchRef": {"name": "main"},
  "url": "https://github.com/mryfmo/herness-self-improvement",
  "visibility": "PRIVATE"
}
```

判定: PASS。

## Server-side protection limitation

```sh
jq -n '{required_status_checks:{strict:true,contexts:["ci"]},enforce_admins:true,required_pull_request_reviews:{dismiss_stale_reviews:false,require_code_owner_reviews:false,required_approving_review_count:0},restrictions:null,required_linear_history:false,allow_force_pushes:false,allow_deletions:false,block_creations:false,required_conversation_resolution:false,lock_branch:false,allow_fork_syncing:false}' |
  gh api --method PUT repos/mryfmo/herness-self-improvement/branches/main/protection --input -
```

```text
HTTP 403
Upgrade to GitHub Pro or make this repository public to enable this feature.
```

判定: 補遺 r1 により server-side protection をスキップし、ローカル代償統制へ移行。

## Pull request and CI

```sh
gh pr view 1 --repo mryfmo/herness-self-improvement --json url,state,mergedAt,mergeCommit,title
gh pr checks 1 --repo mryfmo/herness-self-improvement
```

```text
PR=https://github.com/mryfmo/herness-self-improvement/pull/1
state=MERGED
mergeCommit=8f3f82f900a99edcdbca13d9a1e633289f670421
CodeRabbit pass
ci pass https://github.com/mryfmo/herness-self-improvement/actions/runs/29625975882/job/88030350638
ci pass https://github.com/mryfmo/herness-self-improvement/actions/runs/29625985651/job/88030378142
```

判定: PASS。

## Local pre-push guard

```sh
git config --get core.hooksPath
git ls-files -s githooks/pre-push
```

```text
githooks
100755 424734d5cb7fe283cbd7b15c6c5e57ade7afc0c2 0 githooks/pre-push
```

実 push 拒否:

```text
proof_commit=512ed29479fe22f6dfaaf5ffb53db1db88708788
proof_status=1
Direct pushes to main are blocked. Push a branch and open a pull request.
error: failed to push some refs to 'github.com:mryfmo/herness-self-improvement.git'
```

remote main は `8f3f82f900a99edcdbca13d9a1e633289f670421` のまま。

判定: PASS。

## Document layout

```text
docs/decisions/ADR-HARNESS-SELF-IMPROVEMENT-v1.0.md
docs/plans/WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.0.md
docs/plans/WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.1.md
docs/reference/REPORT-HARNESS-SELF-IMPROVEMENT-v1.0.md
docs/reference/branch-protection.md
docs/specs/SPEC-HARNESS-SELF-IMPROVEMENT-v1.0.md
root_documents_absent=PASS
```

判定: PASS。

## Document body integrity

新パスを旧ファイル名へ正規化して移設前 blob と SHA-256 を比較した。

```text
WORKPLAN-v1.0 old=07a638e1c8f96ee0e5c4763e399ce617704d80168ec94646ff7e726e5b486c35
WORKPLAN-v1.0 normalized-new=07a638e1c8f96ee0e5c4763e399ce617704d80168ec94646ff7e726e5b486c35
WORKPLAN-v1.1 old=266f35b29c5402793c05991ad292fe1fbbfb0b254f17287a8bd39c7302ae1a19
WORKPLAN-v1.1 normalized-new=266f35b29c5402793c05991ad292fe1fbbfb0b254f17287a8bd39c7302ae1a19
SPEC old=346e52b1d4fce670e10505c681f04d7650a75b9d28085c50dc7c633415058ba3
SPEC normalized-new=346e52b1d4fce670e10505c681f04d7650a75b9d28085c50dc7c633415058ba3
REPORT old=ace9d5a371ffaad02179ab81327d5ce42ea5c28adc8268148d885c1bab3c3ca3
REPORT normalized-new=ace9d5a371ffaad02179ab81327d5ce42ea5c28adc8268148d885c1bab3c3ca3
ADR old=cd35e6882f8bd667d2cf32f7726b09d96ee8822a751d9604fe8cd0392b5b3d23
ADR new=cd35e6882f8bd667d2cf32f7726b09d96ee8822a751d9604fe8cd0392b5b3d23
```

判定: PASS。相互参照パス以外の本文変更なし。

## Review gate

```sh
make require-crit-review
```

```text
make: *** No rule to make target `require-crit-review'.  Stop.
```

repository に Crit gate target は未実装。PR #1 は `gh` で全差分を確認し、CodeRabbit と CI が pass した。
