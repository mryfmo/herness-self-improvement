# a002 P1-F1-T0 Bootstrap Report

## Status

ready_for_review

## Result

- Repository: https://github.com/mryfmo/herness-self-improvement
- Pull request: https://github.com/mryfmo/herness-self-improvement/pull/1
- Squash merge: `8f3f82f900a99edcdbca13d9a1e633289f670421`

## Completed procedure

1. `.gitignore` を作成し、`.codex/`、`.claude/settings.local.json`、`/tmp/` を除外した。`.orchestration/` と `.agents/worklog/claude/` は初回コミットに含めた。
2. main で Git を初期化し、`84bee52 chore: bootstrap harness repository (P1-F1-T0)`（`Agent: worker`）を作成した。
3. private repository を作成して main を push した。
4. 最小 CI（job `ci`）と単独運用のレビュー代替説明を `7360b5a ci: add bootstrap document check`（`Agent: worker`）で main へ push した。
5. branch protection / ruleset API の HTTP 403 を確認し、補遺 r1 に従って version-controlled `githooks/pre-push`、PR、CI を代償統制として実装した。
6. `f1-t0/docs-move` で WORKPLAN、SPEC、REPORT、ADR 束を `docs/` 配下へ移設し、文書内の相互参照パスだけを更新した。
7. GitHub Free の制約、代償統制、将来の server-side migration コマンドを `docs/reference/branch-protection.md` に記録した。
8. PR #1 の全差分を `gh` で確認し、2 件の `ci` と CodeRabbit が pass 後に squash merge した。追加 commit はなく、PR 本文の再更新は不要だった。
9. ローカル main を merge commit へ fast-forward し、`git config core.hooksPath githooks` を確認した。
10. main を汚さない一時 commit object の push を試行し、pre-push hook が exit 1 で拒否することを実証した。

## Compensating control

GitHub Free の private repository では server-side branch protection が利用できない。補遺 r1 の完了条件に従い、通常変更は feature branch → PR → CI とし、ローカル hook が `ALLOW_MAIN_PUSH=1` なしの main push を拒否する。

server-side protection は GitHub Pro 化または public 化のユーザー決裁後、F1-T9 までに再評価する。public 化、force-push、履歴改変は実施していない。

## Judgment

ローカル hook は `--no-verify` や未設定 clone では強制できないため server-side protection と同等ではない。しかし、README の setup 指示、version-controlled hook、PR の CI green、実拒否証跡が補遺 r1 の読み替え完了条件を満たす。
