# a003 Validation

## Pre-change failure

```text
missing: docs/lessons
missing: .claude/skills
missing: .claude/agents
missing: .claude/hooks
missing: .claude/commands
missing: ci
```

判定: 期待どおり FAIL。実装後に同じ `test -d` 群が PASS した。

## Repository tree

指定コマンド:

```sh
tree -a -I '.git' -L 3
```

```text
zsh: command not found: tree
exit=127
```

依存追加は禁止されているため `tree` を導入せず、`find . -maxdepth 3 -not -path './.git' -not -path './.git/*' -print | sort` で同じ深さを確認した。対象部分:

```text
.
./.claude
./.claude/agents
./.claude/agents/.gitkeep
./.claude/commands
./.claude/commands/.gitkeep
./.claude/hooks
./.claude/hooks/.gitkeep
./.claude/skills
./.claude/skills/.gitkeep
./.github
./.github/workflows
./.github/workflows/ci.yml
./ci
./ci/.gitkeep
./docs
./docs/decisions
./docs/lessons
./docs/lessons/.gitkeep
./docs/plans
./docs/reference
./docs/specs
```

判定: PASS。SPEC 5.1 対応表は report に記録した。

## README line limit and links

```sh
wc -l README.md
```

```text
31 README.md
```

Work plan、Specification、Research report、Architecture decisions、branch protection のリンク先を `test -f` で確認した。

判定: PASS（31 ≤ 120）。

## Local CI-equivalent checks

既存 5 文書の `test -f` と、追加した 10 ディレクトリの `test -d` を main で実行した。

```text
main local CI-equivalent checks: PASS
```

判定: PASS。

## Pull request and CI

```sh
gh pr view 2 --json url,state,mergedAt,mergeCommit,title,statusCheckRollup
gh pr checks 2
```

```text
PR=https://github.com/mryfmo/herness-self-improvement/pull/2
state=MERGED
mergeCommit=b58ec9454c59ca0fc1fe758bb1592112f80d5769
ci pass https://github.com/mryfmo/herness-self-improvement/actions/runs/29626597059/job/88032152551
ci pass https://github.com/mryfmo/herness-self-improvement/actions/runs/29626693402/job/88032426710
CodeRabbit pass (rate limit のため line-by-line review は未実施、actionable comment なし)
```

判定: PASS。

## Allowed and forbidden diff

PR #2 の変更は次の 9 files のみ:

```text
.claude/agents/.gitkeep
.claude/commands/.gitkeep
.claude/hooks/.gitkeep
.claude/skills/.gitkeep
.github/workflows/ci.yml
README.md
ci/.gitkeep
docs/lessons/.gitkeep
docs/reference/branch-protection.md
```

WORKPLAN v1.0/v1.1、SPEC、REPORT、ADR は base `8f3f82f` から merge `b58ec94` まで diff なし。force-push、main 直接 push、protection 変更、依存変更、他 repository 操作は未実施。

判定: PASS。

## Review gates

```sh
make require-crit-review
```

```text
make: *** No rule to make target `require-crit-review'.  Stop.
```

repository に Crit gate target は未実装。PR の全 9 files、commit trailer、CI、コメントを `gh` で確認した。

plan-quality-gate が参照する validator、hook、subagent definition、CI もこの repository には存在しなかったため、worklog plan は AGENTS.md の frontmatter と必須見出しを手動確認した。
