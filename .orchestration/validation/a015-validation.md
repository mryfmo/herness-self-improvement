# a015 Validation

## Content assertions

```text
discipline frontmatter=owner mryfmo / last-verified 2026-07-19 / freshness 180d
position=self-description, not a decision
decision source=ADR-0001〜0008
three axes=Harness Engineering / Grounded Graph Engineering / Gated RSI
single loop=minimal component
single-loop failures=Goodhart / upper blindness / conflicts / measurement degradation
Graph Engineering=improvement-loop topology, distinct from execution graphs such as LangGraph
safety modifiers=Grounded / Gated
human fixed point=mryfmo
genealogy=Karpathy / user essay 2026-07 / three-axis integration instruction 2026-07-19
relative ADR links=ADR-0001〜0008
ADR index Accepted rows=2
README discipline reference=1 added line
README and rules architecture target=docs/decisions/README.md
WORKPLAN target=v1.1
```

## Local checks

```text
python3 ci/check-docs.py
docs check passed (21 documents)

python3 ci/test_generate_rules.py
Ran 5 tests
OK

python3 ci/test_generate_rules.py && python3 ci/generate-rules.py && git diff --exit-code CLAUDE.md AGENTS.md
PASS

git diff --cached --check
PASS
```

## ADR exact-diff proof

`git diff --cached --unified=0` で ADR ごとに 2 insertions / 1 deletion を確認した。差分は両 ADR とも次の 3 行だけである。

```diff
-- Status: Proposed (mryfmo 決裁待ち)
+- Status: Accepted
+- Accepted: 2026-07-19 mryfmo 指示(ADR-0007/0008 の取り込み・RSI 追加・三軸統合と根本修正の指示)による。
```

さらに、旧版の Status 行を除いた内容と、新版の Status / Accepted 行を除いた内容を `diff` で比較し、差分 0 を確認した。

## Protected-file proof

作業前後で次の SHA-256 が一致した。

```text
d2e265654f33fc3b88fd2f7b78a5d6e011a58b97d3f60d2fe141b303838f5f85  SPEC v1.0
6a6d7286d32e09b1aa04c9f7aac821d6e6ebc93e39b547d9d981e0b0cb01535c  WORKPLAN v1.1
2bfab619dd2dfecc162b189cca553f70d398bfe73435ce5fead29968432c5d81  REPORT v1.0
ca90408710247250a8f500cd67c795cfc8464b0379f0d1ddeae6381d1c947ad5  ADR bundle
163d84b43680ab18ad2ea6d7ad6818913e8559f436be7bfb1a47bf48894fd484  ADR-0001
3ef6f0fa540d5d1844050c3af6280e1499e9b795b06ef8c42db4404b17949b8f  ADR-0002
9e6797e6a08626b1d4d0a9998903dfe9061da4f9c4e419ebafe26ffb9d642838  ADR-0003
34bde2dfab0ac6d9baff31a2a122e48e4e4f5f21f99e882c3083678f7cbfb751  ADR-0004
ee17581a0803548f0a2d337b78c10f121361f91036bfd57d94f339f7ac384ad0  ADR-0005
1a7e38480b768a7d9e99f156ce8fe9f775e92993a951c5ac9c568eef34a1bc21  ADR-0006
```

## Diff scope

```text
M AGENTS.md
M CLAUDE.md
M README.md
M docs/decisions/ADR-0007-loop-graph-anchoring.md
M docs/decisions/ADR-0008-recursive-self-improvement-strata.md
M docs/decisions/README.md
A docs/specs/discipline-v1.0.md
M rules.src.md
```

source commit `55d6fd30131fedc7d15037431a2bce70ae5eab0c` は 8 files、71 insertions、10 deletions。許可対象外の変更を含まない。

## Review gate

```sh
make require-crit-review
```

```text
make: *** No rule to make target `require-crit-review'. Stop.
```

repository に Crit gate target は未実装。ブラウザ Crit は使用せず、staged diff と ADR 限定差分を直接確認した。

## Pull request and CI

```text
PR=https://github.com/mryfmo/herness-self-improvement/pull/13
source commit=55d6fd30131fedc7d15037431a2bce70ae5eab0c
merge commit=56e2d443f3485caf2b324c8671333eebd8048802
push ci=https://github.com/mryfmo/herness-self-improvement/actions/runs/29670544180/job/88148589608
pull-request ci=https://github.com/mryfmo/herness-self-improvement/actions/runs/29670733076/job/88149090682
main merge ci=https://github.com/mryfmo/herness-self-improvement/actions/runs/29670757680/job/88149157553
checks=all successful, 0 failing, 0 pending
```

PR の full body、`Agent: worker` footer、commit trailer、8-file diff を `gh` で確認した。CodeRabbit、push CI、pull-request CI、main CI は成功し、review / inline comments は 0 件。PR は squash merge 済みで、main / origin/main は merge commit に一致する。

## Network boundary

GitHub 操作だけを許可範囲として、`git push` と `gh` による PR / checks / merge 確認を実施した。外部 Web は取得していない。
