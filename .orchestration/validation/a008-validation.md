# a008 Validation

## Test-first evidence

実装前:

```sh
ci/test_evidence_gates.sh
```

```text
FAIL: missing executable db/hx-evidence.sh
exit=1
```

判定: PASS。

## Behavioral test

main上の最終run:

```text
PASS: evidence record, trace, validation, and append-only enforcement
PASS: frozen modification, addition, deletion, and manifest refresh
PASS: dummy secret detection, non-disclosure, and exact allowlist
```

以下を確認した。

- evidence recordのactor/event/ref/detail JSON round-trip、list、trace
- `hx_audit` UPDATE/DELETE拒否
- invalid JSON、missing DB、ホーム `.agents` DB path拒否
- frozen fileのmodification/addition/deletionでverify fail、freeze refresh後にpass
- runtime生成dummy secretの検出、findingへの値非表示、exact allowlist適用

判定: PASS。

## Closed gate and data guard

```text
verified 21 frozen files
secret scan clean
```

manifestは `.github/workflows/ci.yml`、`ci/`、`db/`、`githooks/` の21 regular filesをSHA-256で固定した。manifest自身、Python bytecode、`__pycache__`は除外される。

判定: PASS。

## Existing suites and static checks

```text
rules generator: 5 tests OK
generated CLAUDE.md / AGENTS.md diff: clean
telemetry migration: PASS
task ledger: PASS
SQLite load hx 8 writers x 2 seconds: NFR-03 PASS
SQLite load mixed 8 writers x 20 seconds: NFR-03 PASS
shell syntax: PASS
ShellCheck excluding established SC1007 CDPATH idiom: PASS
Python compile: PASS
git diff --check: PASS
```

mixed load最終値はexpected=15,999、actual=15,999、missing=0、busy retries=0、deadlocks=0だった。

判定: PASS。

## Premise and provenance

- AIDD側の再利用可能な3 packageは存在しないことを確認した。
- 近縁source 2件はappend-only、traceability、secret-category原則の読み取り参照だけに使用した。
- AIDDコードのコピー・変更はない。
- implementationはshell / Python 3 stdlibによる独立した最小再実装。
- protected SPEC本文は変更せず、A-5の将来訂正要をreferenceとlearningに残した。

判定: PASS。

## Pull request and CI

```text
PR=https://github.com/mryfmo/herness-self-improvement/pull/7
state=MERGED
mergeCommit=10292331026807fd3703ad1a3663c5818cbdb83b
push ci pass=https://github.com/mryfmo/herness-self-improvement/actions/runs/29666721640/job/88138261866
pull-request ci pass=https://github.com/mryfmo/herness-self-improvement/actions/runs/29666756586/job/88138359976
main merge ci pass=https://github.com/mryfmo/herness-self-improvement/actions/runs/29666781700
CodeRabbit=SUCCESS; inline comments=0
```

CodeRabbitは利用上限のため本文レビューを開始できなかった旨をissue commentに残した。status checkはSUCCESSで、actionable inline feedbackはなかった。

判定: PASS。

## Allowed and forbidden diff

PR #7 の変更はtaskが許可した次の9 filesのみ:

```text
.github/workflows/ci.yml
ci/frozen-manifest.json
ci/frozen-paths.txt
ci/hash-freeze.py
ci/secret-allowlist.txt
ci/secret-scan.py
ci/test_evidence_gates.sh
db/hx-evidence.sh
docs/reference/evidence-and-gates.md
```

実運用agmsg DB、AIDD repository、指定外docs、protection、hooks、dependenciesは変更なし。

判定: PASS。

## Review gate

```sh
make require-crit-review
```

```text
make: *** No rule to make target `require-crit-review'. Stop.
```

repositoryにCrit gate targetは未実装。PRのfull body、9 files、commit trailer、CI、commentsを `gh` で確認した。
