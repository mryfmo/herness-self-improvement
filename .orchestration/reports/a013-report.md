# a013 ADR-0008 Recursive Self-Improvement Strata Report

## Status

ready_for_review

## Result

- ADR: `docs/decisions/ADR-0008-recursive-self-improvement-strata.md`
- Status: Proposed (mryfmo 決裁待ち)
- Pull request: https://github.com/mryfmo/herness-self-improvement/pull/12
- Source commit: `d995a60376a827b783f98ac46dc45b54be5debd9`
- Squash merge: `43bc6c99b5746bfb24ad4ae199810f5a48d2d075`
- ADR SHA-256: `f55b82297b156383b3bc5220ca02700e41196b0c7e74117919756570f41ca314`
- Branch: `a013/adr-0008-recursive-self-improvement-strata`（merge 後に local / remote とも削除）

## Implementation

- L0 の業務対象、L1 のハーネス artefact、L2 の改善機構、L3 の統治機構を定義し、各階層の変更権限を明記した。
- L2 の変更を、採択率・修正率・誤起票率・ロールバック率という接地メタ指標と mryfmo の人間承認に限定した。
- すべての optimizer ループへのメタ指標、L2 PR への実測値記載、自己加速の禁止、カナリアと F6-T5 を使うロールバック提案、1 ループ 1 変更/周期を定めた。
- 再帰の不動点を mryfmo の判断に置き、統治・承認者・目的関数を自動変更する無制限の再帰的自己改善を対象外にした。
- ADR index へ ADR-0008 の Proposed 行を 1 行追加した。

## Fact boundary

Context、Decision、Consequences、根拠は task file の指定事項とリポジトリ内の WORKPLAN、REPORT、既存 ADR、hash-freeze 文書だけを使用した。外部 Web は取得していない。task file に指定された arXiv ID は識別子として転記した。

## PR flow

- GitHub 調査・操作は `gh` を最初に使用した。
- commit は `docs(adr): propose recursive improvement strata`、本文 trailer は `Agent: worker`。
- PR 本文は全差分を説明し、末尾に `Agent: worker` footer を付けた。
- push CI、pull-request CI、merge 後 main CI はすべて成功した。
- CodeRabbit status は success だが、review limit のため本文レビューは未実施。inline comments は 0 件。
- PR #12 を squash merge し、checkout を main へ戻した。HEAD と origin/main は `43bc6c99b5746bfb24ad4ae199810f5a48d2d075` で一致する。

## Scope

PR #12 は ADR-0008 の新規 22 行と index の 1 行追加だけである。4 保護文書、既存 ADR-0001〜0007、CI、protection/hooks、dependencies は変更していない。既存 dirty worktree、先行 artifacts、並行 task files は変更・stage していない。
