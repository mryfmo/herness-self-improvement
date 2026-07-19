# Task a010: P1-F1-T8 ADR-0001〜0006 の正式登録(束の分割)

- task_id: a010
- repo: /Users/mryfmo/Workspace/herness-self-improvement
- issued: 2026-07-19
- orchestrator: claude-fable5high-herness
- worker: codex-gpt56solhigh-herness
- max_turns: 4
- 根拠: WORKPLAN v1.1 P1-F1-T8 / Decision Log #4(ADR-0001〜0006 新規採番、旧呼称併記)
- 前提: a009 受入済み(frontmatter 規約・check-docs CI が稼働)。全変更は PR 経由。

## Objective

`docs/decisions/ADR-HARNESS-SELF-IMPROVEMENT-v1.0.md`(束)を 1 決定 1 ファイルに分割し、ADR-0001〜0006 として登録、束に分割済み注記を付して PR でマージする。

## 要件

1. 各 ADR を `docs/decisions/ADR-000N-<slug>.md` として作成(N=1〜6、束の H001〜H006 の順)。slug は英小文字ケバブ(例: ADR-0001-git-single-source-of-truth.md)。
2. **本文は束の該当節を忠実に転記**(Status / Context / Decision / Consequences / 根拠)。文言の書き換え・要約・省略は禁止。追加してよいのは:
   - frontmatter(owner: mryfmo / last-verified: 2026-07-19 / freshness: 180d)
   - 冒頭に「旧呼称: ADR-H00N」行
   - Status を `Accepted` に更新し、根拠行「Accepted: 2026-07-18 mryfmo 決裁(WORKPLAN v1.1 Decision Log #4)」を追記
3. 束ファイルは本文を保持したまま、冒頭に 1 行だけ追記: 「Status: 分割登録済み(ADR-0001〜0006 参照)。本書は審議時の歴史的資料。」(F1-T8 が明示的に許可する唯一の 4 文書変更)
4. `docs/decisions/README.md`(または index): 6 件の一覧(番号・題名・旧呼称・Status)。frontmatter 付き。
5. check-docs(リンク・frontmatter)と既存 CI が green であること。免除リストの ADR 束は維持(本文はまだ frontmatter なしのため)。

## 転記忠実性の検証(必須)

分割 6 ファイルから frontmatter・旧呼称行・Accepted 行を機械的に除去して結合した本文が、束の対応節と行単位で一致することを diff で実証し、validation に記録する。

## Allowed files

`docs/decisions/`(新規 6 + README + 束への 1 行追記)、PR ブランチ操作、`.orchestration/` の a010 5 artifact。凍結対象(ci/ 等)は変更なし(ADR は凍結対象外)。

## Forbidden actions

- 束の本文変更(冒頭 1 行追記以外)、他 3 文書変更、保護/フック変更、依存追加、force-push、main 直接 push

## Validation

```sh
ls docs/decisions/
転記忠実性 diff(上記)の出力
python3 ci/check-docs.py
gh pr checks <PR番号>
```

## Expected artifacts

- report / validation / sandbox / learning / autoskill: `.orchestration/{reports,validation,sandboxes,learning,autoskill/runs}/a010-*.md`

## Done signal

`AGMSG-RESULT v1 task_id=a010 status=ready_for_review report=... validation=... sandbox=... learning=... autoskill=...`
