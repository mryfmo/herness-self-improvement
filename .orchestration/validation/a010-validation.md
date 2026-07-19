# a010 Validation

## Transcription normalization assertions

各新規ADRについて以下をassertした。

```text
frontmatter:
  owner: mryfmo
  last-verified: 2026-07-19
  freshness: 180d
body lines per ADR: 9
legacy names: ADR-H001 ... ADR-H006
status: Accepted
accepted provenance: Accepted: 2026-07-18 mryfmo 決裁(WORKPLAN v1.1 Decision Log #4)
transcribed fields: Context, Decision, Consequences, 根拠
normalized_sections=6
bundle_status_line_only=PASS
```

正規化は次の許可差分だけを逆変換した。

1. frontmatter、旧呼称行、Accepted provenance行を除去
2. `# ADR-000N:`を`## ADR-H00N:`へ復元
3. `- Status: Accepted`を`- Status: Proposed`へ復元
4. 6節を番号順に1 blank lineで結合

## Required line-by-line diff

```sh
diff -u <bundle-sections> <normalized-split-sections>
```

```text
<no output>
exit=0
```

```text
bundle sections sha256:
28ccbb3afaa06b4adef289df6dfa6d04c383f14af5982b3039a4915fab62b0f3

normalized split sections sha256:
28ccbb3afaa06b4adef289df6dfa6d04c383f14af5982b3039a4915fab62b0f3
```

判定: PASS。6 ADRのContext / Decision / Consequences / 根拠に書換え・要約・省略なし。

## Bundle one-line-only proof

変更前bundleをmerge baseから取得し、現行bundleのline 1を次の指定文字列と照合した。

```text
Status: 分割登録済み(ADR-0001〜0006 参照)。本書は審議時の歴史的資料。
```

現行bundleのline 2以降と変更前bundle全体をbyte比較:

```text
bundle_status_line_only=PASS
```

Git diffでもadditions=1、deletions=0、追加箇所=line 1だけを確認した。

判定: PASS。

## Files and docs check

```text
ADR-0001-git-single-source-of-truth.md
ADR-0002-two-layer-memory.md
ADR-0003-ace-knowledge-refinement.md
ADR-0004-fail-closed-pr-pipeline.md
ADR-0005-three-scope-promotion.md
ADR-0006-skill-supply-chain-governance.md
ADR-HARNESS-SELF-IMPROVEMENT-v1.0.md
README.md

docs check passed (17 documents)
verified 24 frozen files
secret scan clean
```

判定: PASS。

## Existing suites

```text
docs checker: 5 tests OK
rules generator: 5 tests OK
generated CLAUDE.md / AGENTS.md diff: clean
telemetry migration: PASS
task ledger: PASS
SQLite load hx 8 writers x 2 seconds: NFR-03 PASS
SQLite load mixed 8 writers x 20 seconds: NFR-03 PASS
evidence / freeze / secret behavioral test: PASS
git diff --check: PASS
```

判定: PASS。

## Pull request and CI

```text
PR=https://github.com/mryfmo/herness-self-improvement/pull/9
state=MERGED
mergeCommit=59c64f25faf59eea4be50f89f4ff373eeab8bfbd
push ci pass=https://github.com/mryfmo/herness-self-improvement/actions/runs/29667624486/job/88140798514
pull-request ci pass=https://github.com/mryfmo/herness-self-improvement/actions/runs/29667736134/job/88141114053
main merge ci pass=https://github.com/mryfmo/herness-self-improvement/actions/runs/29667766901
CodeRabbit=SUCCESS; walkthrough reviewed; inline comments=0
```

判定: PASS。

## Allowed and forbidden diff

PR #9は`docs/decisions/`の次の8 filesのみ:

```text
docs/decisions/ADR-0001-git-single-source-of-truth.md
docs/decisions/ADR-0002-two-layer-memory.md
docs/decisions/ADR-0003-ace-knowledge-refinement.md
docs/decisions/ADR-0004-fail-closed-pr-pipeline.md
docs/decisions/ADR-0005-three-scope-promotion.md
docs/decisions/ADR-0006-skill-supply-chain-governance.md
docs/decisions/ADR-HARNESS-SELF-IMPROVEMENT-v1.0.md
docs/decisions/README.md
```

他3保護文書、CI、protection/hooks、dependenciesは変更なし。

判定: PASS。

## Review gate

```sh
make require-crit-review
```

```text
make: *** No rule to make target `require-crit-review'. Stop.
```

repositoryにCrit gate targetは未実装。PRのfull body、8 files、commit trailer、CI、CodeRabbit walkthroughを`gh`で確認した。
