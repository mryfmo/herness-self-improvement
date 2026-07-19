# a009 P1-F1-T7 Wiki Frontmatter and Link CI Report

## Status

ready_for_review

## Result

- Pull request: https://github.com/mryfmo/herness-self-improvement/pull/8
- Squash merge: `26e3d0ece94b2d9bcb20227125aca8a01b24a0c2`
- Branch: `f1-t7/wiki-frontmatter-ci`（merge 後に削除）
- Dependencies added: none

## Implementation

- `docs/reference/wiki-conventions.md`: owner / last-verified / freshness規約、コピー用template、5 directory responsibilities、relative link方針を記録した。
- `ci/check-docs.py`: `docs/**/*.md`のfrontmatterと、同文書およびREADMEのrelative inline/image/reference-style Markdown linkをPython標準ライブラリだけで検査する。
- `ci/docs-frontmatter-exempt.txt`: protected legacy document群の5 pathsをfrontmatterだけ免除し、改訂時にfrontmatter付与と除外解除を要求する先頭commentを置いた。link検査は免除しない。
- `ci/test_check_docs.py`: 正常、frontmatter欠落、3 field形式不正、broken link、frontmatter-only exemptionの5観点をtemporary treeで検証する。
- `docs/reference/branch-protection.md`: 既存referenceで唯一不足していたfrontmatterを追補した。
- CI: behavioral testと現行repository checkerを追加し、frozen manifestを24 filesへ更新した。

## Fail-closed proof

PRを作らない一時branchへfrontmatter欠落とbroken linkを同時に含む文書をpushし、Actionsの`Check docs` stepが両方を報告してfailureになった。

https://github.com/mryfmo/herness-self-improvement/actions/runs/29667056477

run取得後、一時branchと不正文書を削除した。

## Completed procedure

1. task fileを最初に読み、allowed files、protected legacy documents、fail実証手順を確認した。
2. 先行testを作り、checker不在で失敗することを確認した。
3. 単一checker、5観点test、exemption、wiki規約、CIを最小実装した。
4. 現行10 docsとREADME、24-file freeze、secret scan、全既存CIを検証した。
5. 一時push-only branchで意図したCI failureを実証し、URL取得後に削除した。
6. PR #8のfull body、commit、7-file diff、CI、commentsを`gh`で確認した。
7. 全checks成功後にsquash mergeし、main上でtask validationを再実行した。

保護5 pathsの本文、protection/hooks、dependencies、実運用agmsg DBは変更していない。
