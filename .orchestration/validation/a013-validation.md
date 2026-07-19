# a013 Validation

## Content assertions

```text
Status: Proposed (mryfmo 決裁待ち)=1
Status: Accepted=0
Decision principles=5
recursion strata L0-L3=PASS
grounded meta-metrics=採択率・修正率・誤起票率・ロールバック率
F3-T6 acceptance threshold=60% 以上
F6-T5 rollback proposal=PASS
L2 change cap=1 loop / 1 change / cycle
unlimited recursive self-improvement out of scope=PASS
task-provided arXiv identifiers=2
ADR index Proposed row=PASS
ADR index additions=1 row
```

最初の階層 marker 検査は shell の backtick 解釈を含む誤った式だったため、単純な `L0`〜`L3` 検査へ修正して再実行した。上記は修正版の成功結果である。

## Local checks

```text
python3 ci/check-docs.py
docs check passed (20 documents)

python3 -m unittest ci/test_check_docs.py
Ran 5 tests
OK

python3 ci/secret-scan.py
secret scan clean

python3 ci/hash-freeze.py verify
verified 24 frozen files

git diff --cached --check
PASS
```

## Diff scope

```text
A docs/decisions/ADR-0008-recursive-self-improvement-strata.md  22 insertions
M docs/decisions/README.md                                     1 insertion
```

source commit `d995a60376a827b783f98ac46dc45b54be5debd9` は 2 files、23 insertions。許可対象外の変更を含まない。

## Review gate

```sh
make require-crit-review
```

```text
make: *** No rule to make target `require-crit-review'. Stop.
```

repository に Crit gate target は未実装。ブラウザ Crit は使用していない。staged diff を直接確認した。

## Pull request and CI

```text
PR=https://github.com/mryfmo/herness-self-improvement/pull/12
source commit=d995a60376a827b783f98ac46dc45b54be5debd9
merge commit=43bc6c99b5746bfb24ad4ae199810f5a48d2d075
push ci=https://github.com/mryfmo/herness-self-improvement/actions/runs/29668936565/job/88144356423
pull-request ci=https://github.com/mryfmo/herness-self-improvement/actions/runs/29668994423/job/88144514882
main merge ci=https://github.com/mryfmo/herness-self-improvement/actions/runs/29669015182/job/88144570677
checks=3 successful, 0 failing, 0 pending
```

PR の full body、`Agent: worker` footer、commit trailer、2-file diff を `gh` で確認した。CodeRabbit status は success、review limit により本文レビューなし、inline review comments は 0 件。PR は squash merge 済みで、main / origin/main は merge commit に一致する。

## Network boundary

GitHub 操作だけを許可範囲として、`git push` と `gh` による PR / checks / merge 確認を実施した。arXiv その他の外部 Web は取得していない。
