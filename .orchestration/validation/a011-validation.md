# a011 Validation

## Content assertions

次の 18 marker の存在をローカル Python assertion で確認した。

```text
owner: mryfmo
last-verified: 2026-07-19
freshness: 180d
2026-04-03
2026-04-04
task 指定 gist id
2025-10
2026-02-11
ADR-0001〜ADR-0006
REPORT
wiki-conventions.md
rules.src.md
A-5
```

結果:

```text
content markers=PASS
external URLs=1 task-provided gist
REPORT omission=PASS
```

REPORT omission assertion は、REPORT v1.0 に `LLM Wiki` が存在し、`Karpathy` が存在しないことを確認する。

## Documentation checks

```text
python3 ci/test_check_docs.py
Ran 5 tests in 0.024s
OK

python3 ci/check-docs.py
docs check passed (18 documents)

python3 ci/secret-scan.py
secret scan clean

python3 ci/hash-freeze.py verify
verified 24 frozen files

git diff HEAD^ HEAD --check
PASS
```

## Diff scope

```text
docs/reference/llm-wiki-genealogy.md
```

source commit `fb4469218975f29d8e11fb7dae8f2d0efd124dfd` は 1 file、53 insertions。許可対象外の変更は含まない。

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
PR=https://github.com/mryfmo/herness-self-improvement/pull/10
source commit=fb4469218975f29d8e11fb7dae8f2d0efd124dfd
merge commit=664ac7374037d99235612c4f2894bf4728472eb7
push ci=https://github.com/mryfmo/herness-self-improvement/actions/runs/29668338856/job/88142738874
pull-request ci=https://github.com/mryfmo/herness-self-improvement/actions/runs/29668469373/job/88143088034
main merge ci=https://github.com/mryfmo/herness-self-improvement/actions/runs/29668497811/job/88143165783
checks=3 successful, 0 failing, 0 pending
```

PR の full body、`Agent: worker` footer、commit trailer、1-file diff を `gh` で確認した。CodeRabbit status は success、review limit により本文レビューなし、inline review comments は 0 件。PR は squash merge済みで、main / origin/main は merge commit に一致する。

## Network boundary

revision により GitHub 操作だけが許可されたため、`git push` と `gh` による PR / checks / merge 確認を実施した。gist、X、その他の外部 Web は取得していない。
