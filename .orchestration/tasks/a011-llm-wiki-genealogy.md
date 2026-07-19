# Task a011: LLM Wiki 系譜文書の作成(ユーザー指示 2026-07-19)

- task_id: a011
- repo: /Users/mryfmo/Workspace/herness-self-improvement
- issued: 2026-07-19
- orchestrator: claude-fable5high-herness
- worker: codex-gpt56solhigh-herness
- max_turns: 3
- 根拠: ユーザー指摘「原典(初唱者)の思想を土台に、近年の知見を差分として積むべき」。REPORT は「LLM Wiki」の用語を使いながら原典(Andrej Karpathy)を引用していない欠落がある。

## Objective

`docs/reference/llm-wiki-genealogy.md` を新規作成し PR でマージする。REPORT 本文(凍結)の将来改訂事項も learning に記録する。

## 文書要件(frontmatter: owner mryfmo / last-verified 2026-07-19 / freshness 180d)

1. **原典**: Andrej Karpathy「LLM Wiki」(2026-04-03 X ポスト「LLM Knowledge Bases」、2026-04-04 gist https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)。核心思想を一次資料に忠実に要約:
   - RAG は「毎回ゼロから再発見し蓄積がない」→ LLM が漸進的に構築・維持する「永続的・複利的アーティファクト」
   - 3 層: 不変 raw sources / LLM 維持 wiki(相互リンク Markdown)/ schema(規約文書が LLM を「規律ある Wiki メンテナ」にする)
   - 分業: 人間 = ソース選定・方向付け・問い、LLM = それ以外すべて
2. **時系列の注記**: 本設計の典拠(ACE 2025-10 / OpenAI Harness Engineering 2026-02-11)は命名(2026-04)より先行。実践が名前に先行した収斂領域であること。
3. **対応表**: Karpathy 原則 ↔ 本設計の実現(二層メモリ ADR-0002 / append-only 体験ログ + docs/ + wiki-conventions.md・rules.src.md / curator + frontmatter + CI / mryfmo 決裁とエージェント保守の分業)。
4. **付加した近年の知見**(原典が扱わない領域): ACE のデルタ更新規律(ADR-0003)、OpenAI の CI + 夜間 GC の組織規模実証(ADR-0001)、供給網ガバナンス 7 制御(ADR-0006)、3 層スコープ + 昇格(ADR-0005)、PR 駆動監査(ADR-0001/0004)。
5. **既知の欠落の明記**: REPORT v1.0 は Karpathy 原典を引用していない。REPORT 改訂時に出典追加が必要(A-5 修正と併記)。
6. 相互リンク: ADR-0001〜0006、REPORT、wiki-conventions.md への相対リンク(check-docs を通ること)。

事実の创作禁止。上記に列挙した事実と、リポジトリ内文書から確認できる内容のみ記載。ネットワークアクセス不要(URL は文字列として記載)。

## Allowed files

`docs/reference/llm-wiki-genealogy.md`、PR ブランチ操作、`.orchestration/` の a011 5 artifact。

## Forbidden actions

- 4 文書(束含む)の変更、他文書変更、ネットワークアクセス、保護/フック変更、依存追加、force-push、main 直接 push

## Validation

```sh
python3 ci/check-docs.py
gh pr checks <PR番号>
```

## Expected artifacts

- report / validation / sandbox / learning / autoskill: `.orchestration/{reports,validation,sandboxes,learning,autoskill/runs}/a011-*.md`

## Done signal

`AGMSG-RESULT v1 task_id=a011 status=ready_for_review report=... validation=... sandbox=... learning=... autoskill=...`
