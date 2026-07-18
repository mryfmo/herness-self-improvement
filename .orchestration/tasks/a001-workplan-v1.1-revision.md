# Task a001: WORKPLAN v1.1 改訂

- task_id: a001
- repo: /Users/mryfmo/Workspace/herness-self-improvement
- issued: 2026-07-18
- orchestrator: claude-fable5high-herness
- worker: codex-gpt56solhigh-herness
- max_turns: 3

## Objective

`WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.0.md` を、承認済み改訂計画
`.agents/worklog/claude/md-stateless-origami.md`(必読)に**完全準拠**して v1.1 に改訂する。

成果物は 2 つ:

1. 新規作成: `WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.1.md`
2. 編集: `WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.0.md` — Status 節に「Superseded by WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.1.md」の 1 行を追記するのみ。他は一切変更しない。

## 必読ファイル(編集禁止・読むだけ)

- `.agents/worklog/claude/md-stateless-origami.md` — 承認済み改訂計画。改訂内容 7 項目(Decision Log / Assumptions / P1-F1-T0 追加 / 単独運用調整 / 依存関係・クリティカルパス / TBD 表更新 / 実行体制)の正確な仕様はここに従う。
- `WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.0.md` — 改訂元。全タスク ID と構成を保持すること。
- `SPEC-HARNESS-SELF-IMPROVEMENT-v1.0.md` — FR/NFR 番号の参照整合の確認用。

## 要件(改訂計画の要約 — 詳細は計画ファイルが正)

1. v1.0 の全タスク ID(P1-F1-T1〜P1-F9-T7)・全フェーズ構成・Tests/Done Criteria/Open Questions を欠落なく保持。削除・改番禁止。
2. 決裁 5 点(2026-07-18, 決裁者 mryfmo)を Decision Log として追記: (1) v1.1 改訂が成果物 (2) GitHub private mryfmo/herness-self-improvement + main 保護 + PR 必須 + CI 必須 (3) 承認者は mryfmo 単独全ロール兼任 (4) ADR-0001〜0006 新規採番(旧呼称 H001〜H006 併記) (5) 本ディレクトリを git init して本体化・4 文書は F1 で docs/ へ移設。
3. P1-F1-T0(ブートストラップ、Owner: orchestrator)を F1 冒頭に追加(内容は計画ファイル §3)。
4. 単独運用への文言調整(計画ファイル §4 の 6 項目、タスク ID 不変)。
5. 「依存関係・クリティカルパス」節とマイルストーン表 M1〜M9 を新設(計画ファイル §5。日付は入れない)。
6. TBD(HUMAN) 一覧表を更新: #1/#2/#3/#6 と #9 の承認者部分をクローズ(決裁内容記載)、残存(#4/#5/#7/#8/#10/#11/パイロット選定)を残存決裁事項表に再掲。
7. Status 節に実行体制 1 段落(orchestrator=Claude Code / worker=Codex / agmsg AGMSG-TASK/RESULT/ACCEPTANCE 運用、詳細は SPEC 5.3 参照)を追記。

## Allowed files(編集してよいのはこれだけ)

- `WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.1.md`(新規)
- `WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.0.md`(Status 1 行追記のみ)
- `.orchestration/reports/a001-report.md`
- `.orchestration/validation/a001-validation.md`
- `.orchestration/sandboxes/a001-sandbox.md`
- `.orchestration/learning/a001-learning.md`
- `.orchestration/autoskill/runs/a001-autoskill.md`

## Forbidden actions

- SPEC / ADR / REPORT / .agents/ / .claude/ / .codex/ / .orchestration/tasks/ の編集
- git 操作全般(init / commit / push — リポジトリ化は別タスク F1-T0 で行う)
- ネットワークアクセス、依存パッケージの追加・変更
- ファイル削除・リネーム
- スキル登録の promotion 判断(candidate 記録まで)

## Validation(実行して出力を validation ファイルに記録)

```sh
# 1. タスク ID 完全性: 差分が P1-F1-T0 の追加のみであること
grep -o 'P1-F[0-9]*-T[0-9]*' WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.0.md | sort -u > /tmp/ids-v10.txt
grep -o 'P1-F[0-9]*-T[0-9]*' WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.1.md | sort -u > /tmp/ids-v11.txt
diff /tmp/ids-v10.txt /tmp/ids-v11.txt   # 期待: "> P1-F1-T0" の 1 行のみ

# 2. 残存 TBD(HUMAN) が残存決裁事項(#4/#5/#7/#8/#10/#11/パイロット選定)のみであること
grep -n 'TBD(HUMAN)' WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.1.md

# 3. v1.0 の変更が Status 1 行のみであること(改訂前に cp でバックアップを取り diff)
```

## Expected artifacts

- report: `.orchestration/reports/a001-report.md` — 実施内容・7 要件それぞれへの対応箇所(v1.1 内の節名)・判断に迷った点
- validation: `.orchestration/validation/a001-validation.md` — 上記 3 検証のコマンド実行出力
- sandbox: `.orchestration/sandboxes/a001-sandbox.md` — サンドボックス状態または fallback 理由
- learning: `.orchestration/learning/a001-learning.md` — 再利用可能な学び(なければ none 記録)
- autoskill: `.orchestration/autoskill/runs/a001-autoskill.md` — 未使用なら not-used 記録

## Done signal

全 artifact を書いたうえで `AGMSG-RESULT v1 task_id=a001 status=ready_for_review report=... validation=... sandbox=... learning=... autoskill=...` を orchestrator(claude-fable5high-herness)へ送信。ブロック時は status=blocked で理由を report に記載。
