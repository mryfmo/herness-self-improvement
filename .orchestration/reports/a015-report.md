# a015 Three-Axis Discipline and ADR Acceptance Report

## Status

ready_for_review

## Result

- Discipline: `docs/specs/discipline-v1.0.md`
- Pull request: https://github.com/mryfmo/herness-self-improvement/pull/13
- Source commit: `55d6fd30131fedc7d15037431a2bce70ae5eab0c`
- Squash merge: `56e2d443f3485caf2b324c8671333eebd8048802`
- Discipline SHA-256: `d52869140e749918a26225a3da8bfaf62a01bd8316187537641acf74c8b12a1e`
- Branch: `a015/discipline-and-adr-acceptance`（merge 後に local / remote とも削除）

## Implementation

- Harness Engineering、Grounded Graph Engineering、Gated RSI を対象・位相・深さの三軸として定式化した。
- 単一ループを最小構成要素に位置づけ、ADR-0007 の四つの構造的失敗へ接続した。
- Graph Engineering を改善ループ位相の工学に限定し、LangGraph などの実行グラフとの混用を禁止した。
- Grounded と Gated を安全性の実体として明記し、人間不動点を mryfmo に置いた。
- Karpathy の原典、ユーザー提供エッセイ、2026-07-19 の三軸統合指示を系譜として整理し、ADR-0001〜0008 の相対リンクを列挙した。
- ADR-0007 / ADR-0008 を Accepted に更新し、各 Status 直下へ指定どおりの受理根拠を 1 行追加した。その他の行は不変である。
- ADR index の両行を Accepted に更新した。
- README と `rules.src.md` から規律文書を参照し、Architecture decisions の正規リンクを ADR 束から `docs/decisions/README.md` へ変更した。WORKPLAN の参照は v1.1 のままである。
- ルール生成器を再実行し、`CLAUDE.md` と `AGENTS.md` を更新した。

## PR flow

- GitHub 調査・操作は `gh` を最初に使用し、外部 Web は取得していない。
- commit は `docs(governance): establish three-axis discipline`、本文 trailer は `Agent: worker`。
- PR 本文に変更範囲と検証を記載し、末尾に `Agent: worker` footer を付けた。
- push CI、pull-request CI、merge 後 main CI はすべて成功した。
- CodeRabbit status は success。review と inline comment はいずれも 0 件だった。
- PR #13 を squash merge した。main と origin/main は `56e2d443f3485caf2b324c8671333eebd8048802` で一致する。

## Scope

PR #13 は指定された 8 ファイルだけを変更した。README は規律文書 1 行の追加に加え、Objective 5 で指定された既存 Architecture decisions リンク 1 行を置換した。SPEC、WORKPLAN v1.1、REPORT、ADR 束、ADR-0001〜0006、CI、protection/hooks、dependencies は変更していない。既存 dirty worktree、先行 artifacts、並行 task files は変更・stage していない。
