# a017 Validation

## Inputs

task_file を最初に読み、次の指定入力をすべて全文確認してから改訂した。

```text
docs/specs/SPEC-HARNESS-SELF-IMPROVEMENT-v1.0.md
.orchestration/reports/a014-report.md
.orchestration/acceptance/a014-acceptance.md
docs/decisions/ADR-0007-loop-graph-anchoring.md
docs/decisions/ADR-0008-recursive-self-improvement-strata.md
docs/specs/discipline-v1.0.md
```

補助根拠として WORKPLAN v1.1 Decision Log、branch-protection、evidence-and-gates、wiki conventions、検証済み learn を参照した。

## FR / NFR preservation

定義行と参照トークンを別々に確認した。

```text
FR definitions: v1.0=13 v1.1=16
NFR definitions: v1.0=8 v1.1=8

v1.0 FR unique:
FR-01 FR-02 FR-03 FR-04 FR-05 FR-06 FR-07 FR-08 FR-09 FR-10 FR-11 FR-12 FR-13

v1.1 FR unique:
FR-01 FR-02 FR-03 FR-04 FR-05 FR-06 FR-07 FR-08 FR-09 FR-10 FR-11 FR-12 FR-13 FR-14 FR-15 FR-16

v1.0 / v1.1 NFR unique:
NFR-01 NFR-02 NFR-03 NFR-04 NFR-05 NFR-06 NFR-07 NFR-08
```

新規番号が FR-14〜16 だけであること、欠落・重複・改番がないことを明示リストで検査した。v1.0 / v1.1 の `##` / `###` 見出し列も `diff` で一致した。

## v1.0 exact-diff proof

```diff
@@ -3,0 +4 @@
+- Superseded by docs/specs/SPEC-HARNESS-SELF-IMPROVEMENT-v1.1.md
```

追加行を除いた v1.0 と改訂前の SHA-256 は一致した。

```text
d2e265654f33fc3b88fd2f7b78a5d6e011a58b97d3f60d2fe141b303838f5f85  stripped current v1.0
d2e265654f33fc3b88fd2f7b78a5d6e011a58b97d3f60d2fe141b303838f5f85  original v1.0
```

## Content assertions

```text
version=v1.1
revision basis=mryfmo 2026-07-19 three-axis instruction + 24 consolidated findings
canonical documents=discipline-v1.0.md + docs/decisions/README.md + WORKPLAN v1.1
A-4=403 evidence + compensating controls + D1 pending
A-5=independent minimal implementation
A-7=private mryfmo/herness-self-improvement + mryfmo all approval roles
FR-03=40% L3-owned threshold + no auto-merge + mryfmo escalation
FR-14=grounded input + no derived-only decision + counter-metric pair
FR-15=L0-L3 + meta-metrics + mryfmo + canary + rollback + one change/cycle + no self-relaxation
FR-16=monthly circularity inspection
NFR-01=L3 full scope + mryfmo + D2 construction exception pending + F9-T7 transition
NFR-02=worktree/network/wrapper controls + OS isolation open
5.2=orchestrator hooks + worker F2-T4 wrapper
5.3=AGMSG v1 canonical + ledger mapping + main push prohibited + feature branch PR normal
6.2=SkillCoach derived metric requires grounded pair
6.5=forced change visibility + human approval authority
ADR index=ADR-0001〜0008; H001〜H006 retained only as old names
```

## Local checks

```text
python3 ci/test_check_docs.py
Ran 5 tests
OK

python3 ci/check-docs.py
docs check passed (22 documents)

python3 ci/hash-freeze.py verify
verified 35 frozen files

git diff --cached --check
PASS
```

`ci/docs-frontmatter-exempt.txt` に v1.0 が残り、v1.1 が存在しないことを確認した。`ci/frozen-paths.txt` は discipline だけを個別凍結しており、SPEC v1.0 / v1.1 は対象外である。discipline と frozen manifest の SHA-256 は a016 後から不変だった。

## Review gate

```sh
make require-crit-review
```

```text
make: *** No rule to make target `require-crit-review'. Stop.
```

repository に Crit gate target は未実装。ブラウザ Crit は使用せず、staged diff、要件番号、見出し構造、禁止ファイル無差分を直接確認した。

## Diff scope

```text
M docs/specs/SPEC-HARNESS-SELF-IMPROVEMENT-v1.0.md  1 insertion
A docs/specs/SPEC-HARNESS-SELF-IMPROVEMENT-v1.1.md  236 insertions
```

source commit `cb1e57fc4034cb13ebe0f13dfc8484aa9cb6277e` は 2 files、237 insertions。許可対象外の変更を含まない。

## Pull request and CI

```text
PR=https://github.com/mryfmo/herness-self-improvement/pull/15
source commit=cb1e57fc4034cb13ebe0f13dfc8484aa9cb6277e
merge commit=051cc46c952e81a708a13006465f6a82fbb40bfe
push ci=https://github.com/mryfmo/herness-self-improvement/actions/runs/29671956114/job/88152527997
pull-request ci=https://github.com/mryfmo/herness-self-improvement/actions/runs/29672013949/job/88152681719
main merge ci=https://github.com/mryfmo/herness-self-improvement/actions/runs/29672042816/job/88152760292
checks=all successful, 0 failing, 0 pending
```

PR の full body、`Agent: worker` footer、commit trailer、2-file diff を `gh` で確認した。CodeRabbit は walkthrough のみで review / inline comments は 0 件。main / origin/main は merge commit に一致する。

## Network boundary

GitHub 操作だけを許可範囲として、`git push` と `gh` による PR / checks / merge 確認を実施した。外部 Web は取得していない。
