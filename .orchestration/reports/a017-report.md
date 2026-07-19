# a017 SPEC v1.1 改訂レポート

## Status

ready_for_review

## Result

- Specification: `docs/specs/SPEC-HARNESS-SELF-IMPROVEMENT-v1.1.md`
- Pull request: https://github.com/mryfmo/herness-self-improvement/pull/15
- Source commit: `cb1e57fc4034cb13ebe0f13dfc8484aa9cb6277e`
- Squash merge: `051cc46c952e81a708a13006465f6a82fbb40bfe`
- SPEC v1.1 SHA-256: `e07236b3bc75f47311c49a6a7d02c50197e46762324c5480e08ddd2d14b953a2`
- Branch: `a017/spec-v1.1-three-axis`（merge 後に local / remote とも削除）

## Structure and requirements

- v1.0 の 1〜8 章、5.1〜5.4、6.1〜6.6 を同じ順序で保持した。
- FR-01〜13 と NFR-01〜08 の番号と趣旨を保持した。
- 新規番号は FR-14〜16 だけである。FR-14 は接地指標と対抗指標、FR-15 は L0〜L3 と L2 / L3 の gate、FR-16 は月次循環検査を定める。
- frontmatter は owner `mryfmo`、last-verified `2026-07-19`、freshness `90d`。v1.1 は frontmatter 免除リストに追加していない。
- v1.0 には Superseded 行を1行だけ追加し、その他の byte は変更していない。

## Audit integration

- A014-02 / A014-11 / A014-12 / A014-13 を A-4、A-5、関連文書・ADR参照、FR-03へ反映した。
- A014-01 / A014-10 と統合所見 A3 を NFR-01 / NFR-02へ反映した。L3 全域の承認者を mryfmo とし、worker 隔離の現時点の実体と OS レベル隔離の Open 事項を分けた。
- 統合所見 A4 を 5.2 へ反映し、orchestrator Hooks と worker 起動ラッパーの双方を収集範囲にした。
- A014-16 / A014-19 を 5.3 へ反映した。AGMSG v1 を正規契約とし、旧メッセージ、hx_tasks 台帳、worker の feature branch push + PR 経路を対応づけた。
- A014-07 を 6.2 へ反映し、SkillCoach ルーブリック単独で F-OPT を駆動できないようにした。
- A014-03 と a016 の訂正を 6.5 へ反映し、hash-freeze を変更の強制可視化、人間承認を権限の実体とした。
- 8章を ADR-0001〜0008 の現行番号と status に更新し、ADR-0001〜0006 は旧呼称 H001〜H006 を併記した。

## Pending decisions

- D1: GitHub Pro 化 / public 化 / 現状受容。server-side trust root の恒久形態は未決である。
- D2: 建設期例外として orchestrator の敵対的検証 + マージを暫定承認とみなし、F9-T7 で mryfmo の PR 単位承認へ切り替える案は未決である。

いずれも解決済みとは記載していない。

## PR flow

- GitHub 操作は `gh` から開始し、外部 Web は取得していない。
- commit は `docs(spec): revise self-improvement specification`、本文 trailer は `Agent: worker`。
- PR 本文に全改訂、番号保持、残存決裁、検証、禁止範囲を記載し、末尾に `Agent: worker` footer を付けた。
- push CI、pull-request CI、merge 後 main CI はすべて成功した。
- CodeRabbit status は success。walkthrough 1 件、review と inline comment は 0 件だった。
- PR #15 を squash mergeした。main と origin/main は `051cc46c952e81a708a13006465f6a82fbb40bfe` で一致する。

## Scope

PR #15 は新規 SPEC v1.1 と、SPEC v1.0 の Superseded 1行だけを変更した。WORKPLAN、REPORT、ADR、三軸規律、frontmatter 免除リスト、frozen paths / manifest、protection/hooks、dependencies は変更していない。既存 dirty worktree、先行 artifacts、並行 task filesは変更・stageしていない。
