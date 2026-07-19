# a009 Validation

## Test-first evidence

実装前:

```sh
python3 ci/test_check_docs.py
```

```text
FileNotFoundError: ci/check-docs.py
exit=1
```

判定: PASS。

## Behavioral tests

```text
.....
----------------------------------------------------------------------
Ran 5 tests

OK
```

検証観点:

1. valid frontmatter、README relative link、document relative reference-style link、HTTP linkの正常系
2. frontmatter全体の欠落
3. owner non-string、存在しないcalendar date、`\d+d`以外のfreshness
4. broken relative link
5. exemptionによるfrontmatter-only免除と、exempt文書へのlink検査継続

判定: PASS。

## Current repository

```text
docs check passed (10 documents)
verified 24 frozen files
secret scan clean
```

判定: PASS。

## Push CI failure proof

Temporary commit:

```text
test(ci): prove docs gate failure
```

Failing run:

https://github.com/mryfmo/herness-self-improvement/actions/runs/29667056477

Failed step output:

```text
docs/reference/a009-ci-fail-proof.md: frontmatter is required
docs/reference/a009-ci-fail-proof.md: link target does not exist: does-not-exist.md
Process completed with exit code 1.
```

PRは作成していない。run確認後、remote/local temporary branchと不正文書を削除した。

判定: PASS。

## Existing suites and static checks

```text
rules generator: 5 tests OK
generated CLAUDE.md / AGENTS.md diff: clean
telemetry migration: PASS
task ledger: PASS
SQLite load hx 8 writers x 2 seconds: NFR-03 PASS
SQLite load mixed 8 writers x 20 seconds: NFR-03 PASS
evidence / freeze / secret behavioral test: PASS
Python compile: PASS
git diff --check: PASS
```

mixed loadはexpected=15,999、actual=15,999、missing=0、busy retries=0、deadlocks=0だった。

判定: PASS。

## Pull request and CI

```text
PR=https://github.com/mryfmo/herness-self-improvement/pull/8
state=MERGED
mergeCommit=26e3d0ece94b2d9bcb20227125aca8a01b24a0c2
push ci pass=https://github.com/mryfmo/herness-self-improvement/actions/runs/29667094420/job/88139310048
pull-request ci pass=https://github.com/mryfmo/herness-self-improvement/actions/runs/29667204686/job/88139616308
main merge ci=https://github.com/mryfmo/herness-self-improvement/actions/runs/29667228883
CodeRabbit=SUCCESS; inline comments=0
```

CodeRabbitは利用上限のため本文レビューを開始できなかった旨をissue commentに残した。status checkはSUCCESSで、actionable inline feedbackはなかった。

判定: PASS。

## Allowed and forbidden diff

PR #8 の変更はtaskが許可した次の7 filesのみ:

```text
.github/workflows/ci.yml
ci/check-docs.py
ci/docs-frontmatter-exempt.txt
ci/frozen-manifest.json
ci/test_check_docs.py
docs/reference/branch-protection.md
docs/reference/wiki-conventions.md
```

WORKPLAN 2 versions、SPEC、REPORT、ADR bundleの本文は変更なし。protection、hooks、dependencies、実運用agmsg DBも変更なし。

判定: PASS。

## Review and plan gates

```sh
make require-crit-review
```

```text
make: *** No rule to make target `require-crit-review'. Stop.
```

repositoryにCrit gate targetは未実装。PRのfull body、7 files、commit trailer、CI、commentsを`gh`で確認した。

plan-quality validator / hook / CI / subagent definitionは別repositoryのnumbered `plans/`専用で、`.agents/worklog/codex/plan/` schemaには適用不能だった。current taskではAGENTS指定のfrontmatterと6 headings、具体scope、肯定/敵対test、保護文書STOP条件を手動確認した。
