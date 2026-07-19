# a018 Validation

## 文書とタスク契約

### タスク ID / 順序 / 構造

```text
v1.1=79 v1.2=79 added=[] removed=[]
task_order_equal=True v1.1=79 v1.2=79
phase_structure_equal=True
```

独立レビューでは 79 件について ID、名称、Owner、順序も完全一致した。

### v1.1 一行差分

`git diff 16f0b2a^ 16f0b2a -- docs/plans/WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.1.md`

```diff
@@ -3,6 +3,7 @@
 ## Status

+- Superseded by WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.2.md
 - 状態: 決裁反映済み・F1 着手可
```

### a018 改訂項目

専用 assertion で次を確認し、全項目 `True`:

```text
frontmatter, status, spec_v1.1, discipline, adr_index, evidence,
extras(a011-a017), adapter, metrics, l2, l3_config, l3_scope,
circular, arbitration, frontmatter_empty, approval_switch, decisions
```

## ローカル検証

```text
$ python3 ci/check-docs.py
docs check passed (23 documents)

$ python3 ci/hash-freeze.py verify
verified 35 frozen files

$ python3 ci/test_check_docs.py
Ran 5 tests in 0.015s
OK

$ python3 ci/secret-scan.py
secret scan clean

$ git diff --cached --check
exit 0
```

SHA-256:

```text
f485923a2b3e3d1b2a1ae1f1aa8a6dc417f3873d5a7aef8b85f525470b5cfe1a  docs/plans/WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.1.md
48b6a01dd7d4425c89206df3f8d9b0755e647bcaf549c57f738dba780f6a619c  docs/plans/WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.2.md
```

## Plan quality / review

外部 validator の exact command:

```sh
env UV_OFFLINE=1 UV_CACHE_DIR=$TMPDIR/a018-uv-cache uv run python scripts/validate_plan_quality.py ../herness-self-improvement/docs/plans/WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.2.md
```

結果: exit 1。別リポジトリ専用の `# Plan`、12 節、Effort、checkbox、Current state の `file:line` を要求したためで、a018 の v1.1 構造保持契約には適用不能。scope-scaled line count 589 は PASS。外部 hook は対象パターン外のため exit 0 / 出力なし。

独立 reviewer の 4 所見はすべて修正後に再検証した。対象リポジトリの `make require-crit-review` は target 不在:

```text
make: *** No rule to make target `require-crit-review'.  Stop.
```

## GitHub validation

- PR: https://github.com/mryfmo/herness-self-improvement/pull/16
- PR files: v1.1（+1/-0）、v1.2（+589/-0）の 2 件だけ。
- push CI: success
- pull_request CI: success
- CodeRabbit status: success。issue comment は rate-limit 通知のみ。
- reviews API: `[]`
- inline comments API: `[]`
- merge state: MERGED
- merge commit: `16f0b2a0c55f06812495c52adc523b784384e7cf`
- main CI: https://github.com/mryfmo/herness-self-improvement/actions/runs/29672535249
- main CI conclusion: success（14 step success。Node.js 20 deprecation annotation は非 blocking）
- final local HEAD = origin/main = `16f0b2a0c55f06812495c52adc523b784384e7cf`
