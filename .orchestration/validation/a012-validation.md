# a012 Validation

## Content assertions

```text
required markers=PASS (20)
Status: Proposed (mryfmo 決裁待ち)=1
Status: Accepted=0
Decision principles=6
task-provided external URLs=2
ADR index Proposed row=PASS
ADR index additions=1 row
```

確認対象には frontmatter、4 失敗、ループのグラフ、アンカー、6 原則、Goodhart、double-loop learning、サイバネティクス、P1-F2-T5 / F4-T9 / F5-T6 / F8-T7 / F9-T4 を含む。

## Local checks

```text
python3 ci/test_check_docs.py
Ran 5 tests
OK

python3 ci/check-docs.py
docs check passed (19 documents)

python3 ci/secret-scan.py
secret scan clean

python3 ci/hash-freeze.py verify
verified 24 frozen files

git diff main...HEAD --check
PASS
```

## Diff scope

```text
A docs/decisions/ADR-0007-loop-graph-anchoring.md  19 insertions
M docs/decisions/README.md                         1 insertion
```

source commit `0964af7ed74b73bd3ba902c274e3f2e40ad0ca65` は 2 files、20 insertions。許可対象外の変更を含まない。

## Review gate

```sh
make require-crit-review
```

```text
make: *** No rule to make target `require-crit-review'. Stop.
```

repository に Crit gate target は未実装。ブラウザ Crit は使用していない。

## Pull request and CI

```text
PR=https://github.com/mryfmo/herness-self-improvement/pull/11
source commit=0964af7ed74b73bd3ba902c274e3f2e40ad0ca65
merge commit=a782c2359671871f75acd29e3c56a1b1123c9fa2
push ci=https://github.com/mryfmo/herness-self-improvement/actions/runs/29668641720/job/88143548471
pull-request ci=https://github.com/mryfmo/herness-self-improvement/actions/runs/29668674206/job/88143635431
main merge ci=https://github.com/mryfmo/herness-self-improvement/actions/runs/29668702891/job/88143708678
checks=3 successful, 0 failing, 0 pending
```

PR の full body、`Agent: worker` footer、commit trailer、2-file diff を `gh` で確認した。CodeRabbit status は success、review limit により本文レビューなし、inline review comments は 0 件。PR は squash merge済みで、main / origin/main は merge commit に一致する。

## Network boundary

GitHub 操作だけを許可範囲として、`git push` と `gh` による PR / checks / merge 確認を実施した。task に記載された X URL やその他の外部 Web は取得していない。

