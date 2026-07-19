# a010 P1-F1-T8 ADR Split Report

## Status

ready_for_review

## Result

- Pull request: https://github.com/mryfmo/herness-self-improvement/pull/9
- Squash merge: `59c64f25faf59eea4be50f89f4ff373eeab8bfbd`
- Branch: `f1-t8/adr-split`（merge 後に削除）
- Registered: ADR-0001〜ADR-0006, all Accepted

## Implementation

- bundleのADR-H001〜H006を同順でADR-0001〜0006へ分割した。
- 各新規ADRへowner `mryfmo`、last-verified `2026-07-19`、freshness `180d`を設定した。
- 各fileに新番号見出し、旧呼称、Accepted Status、`Accepted: 2026-07-18 mryfmo 決裁(WORKPLAN v1.1 Decision Log #4)`を追加した。
- Context / Decision / Consequences / 根拠はbundleの各行を無変更で転記した。
- `docs/decisions/README.md`へ番号・題名・旧呼称・Statusの6件indexを追加した。
- bundleは指定された歴史Status 1行だけをline 1へ追加し、既存本文を保持した。

## Transcription fidelity

新規6 filesからfrontmatter、旧呼称、Accepted根拠を除去し、許可された新番号見出しとAccepted Statusを旧番号・Proposedへ機械的に戻した。H001〜H006順に結合した結果を、変更前bundleの6節と`diff -u`した。

```text
normalized_sections=6
bundle_status_line_only=PASS
diff output: empty
diff exit: 0
source sha256:     28ccbb3afaa06b4adef289df6dfa6d04c383f14af5982b3039a4915fab62b0f3
normalized sha256: 28ccbb3afaa06b4adef289df6dfa6d04c383f14af5982b3039a4915fab62b0f3
```

さらに、現行bundleの追加line 1を除去したbytesが変更前bundle全体と一致することをassertした。

## Completed procedure

1. task fileを最初に読み、転記許容差分とbundle one-line-only制約を確認した。
2. bundleの6節と各5 fieldを行境界で確認した。
3. 6 ADR、index、bundle指定1行だけを作成した。
4. 正規化diff、SHA-256一致、bundle全体byte一致をfeature branchとmainの双方で確認した。
5. 17 docs check、secret scan、frozen verify、全既存CIを通した。
6. PR #9のfull body、commit、8-file diff、CI、CodeRabbit walkthrough、inline commentsを`gh`で確認した。
7. 全checks成功後にsquash mergeし、main CI成功を確認した。

他3保護文書、CI、protection/hooks、dependenciesは変更していない。
