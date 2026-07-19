# a004 Validation

## Test-first evidence

generator 実装前:

```sh
python3 ci/test_generate_rules.py
```

```text
ModuleNotFoundError: No module named 'generate_rules'
exit=1
```

generator 実装後:

```text
.....
----------------------------------------------------------------------
Ran 5 tests in 0.020s

OK
```

判定: PASS。対象別区分、header/hash、3 marker 必須、冪等生成、120/121行 warning 境界を検査した。

## Generated-file idempotence

```sh
ci/generate-rules.py
git diff --exit-code -- CLAUDE.md AGENTS.md
```

```text
exit=0
```

source hash:

```text
rules.src.md sha256=4f050e18552021ebbacd4a8012c4b2831b54fe7424f5a0b485f56cf67566b1c3
CLAUDE.md header=4f050e18552021ebbacd4a8012c4b2831b54fe7424f5a0b485f56cf67566b1c3
AGENTS.md header=4f050e18552021ebbacd4a8012c4b2831b54fe7424f5a0b485f56cf67566b1c3
```

判定: PASS。

## Manual-edit detection

canonical 生成物を stage 後、`CLAUDE.md` 冒頭へ `X` を追加して stage し、生成器を再実行した。

```sh
ci/generate-rules.py
git diff --exit-code -- CLAUDE.md AGENTS.md
```

```diff
-X<!-- GENERATED FILE — edit rules.src.md -->
+<!-- GENERATED FILE — edit rules.src.md -->
```

```text
exit=1
```

その後 canonical 生成物を再 stage し、正常な index/worktree 一致を確認した。

判定: PASS。

## Line limit

```sh
wc -l CLAUDE.md AGENTS.md
```

```text
25 CLAUDE.md
25 AGENTS.md
50 total
```

unit test は120行で warning なし、121行で次形式の warning が出て処理自体は成功することを確認した。

```text
::warning file=long.md::long.md has 121 lines; limit is 120
```

判定: PASS（各25 ≤ 120）。

## Apache-2.0 and NOTICE

canonical source: https://www.apache.org/licenses/LICENSE-2.0.txt

```sh
set -e
curl -sS https://www.apache.org/licenses/LICENSE-2.0.txt | cmp LICENSE -
shasum -a 256 LICENSE
wc -c -l LICENSE
grep -c 'Apache License' LICENSE
grep -c 'Version 2.0, January 2004' LICENSE
cat NOTICE
```

```text
official byte comparison: PASS
cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30  LICENSE
202 lines
11358 bytes
Apache License matches=4
Version 2.0, January 2004 matches=1
herness-self-improvement
Copyright 2026 mryfmo <mryfmo@gmail.com>
```

判定: PASS。LICENSE は Apache 公式配布物と byte-for-byte 一致し、NOTICE は正確に2行。

## Pull request and CI

```sh
gh pr view 3 --json url,state,mergedAt,mergeCommit,title,statusCheckRollup
gh pr checks 3
```

```text
PR=https://github.com/mryfmo/herness-self-improvement/pull/3
state=MERGED
mergeCommit=bd8aa9b3d8faf0ebb9ca6afa6bfe4bed1b905d9c
ci pass https://github.com/mryfmo/herness-self-improvement/actions/runs/29627248211/job/88033971776
ci pass https://github.com/mryfmo/herness-self-improvement/actions/runs/29627264067/job/88034016179
CodeRabbit pass (rate limit のため line-by-line review は未実施、actionable comment なし)
```

判定: PASS。

## Allowed and forbidden diff

PR #3 の変更は task が許可した次の9 files のみ:

```text
.github/workflows/ci.yml
AGENTS.md
CLAUDE.md
LICENSE
NOTICE
README.md
ci/generate-rules.py
ci/test_generate_rules.py
rules.src.md
```

README diff は末尾の License 節4 added lines のみ。WORKPLAN v1.0/v1.1、SPEC、REPORT、ADR、branch protection、pre-push hook は base `b58ec94` から merge `bd8aa9b` まで diff なし。force-push、main 直接 push、protection 変更、依存変更、他 repository 操作は未実施。

判定: PASS。

## Review gate

```sh
make require-crit-review
```

```text
make: *** No rule to make target `require-crit-review'.  Stop.
```

repository に Crit gate target は未実装。PR の全9 files、commit trailer、CI、コメントを `gh` で確認した。
