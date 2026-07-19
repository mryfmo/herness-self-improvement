# Task a004: P1-F1-T2 rules.src.md と CLAUDE.md/AGENTS.md 生成器

- task_id: a004
- repo: /Users/mryfmo/Workspace/herness-self-improvement
- issued: 2026-07-18
- orchestrator: claude-fable5high-herness
- worker: codex-gpt56solhigh-herness
- max_turns: 4
- 根拠: WORKPLAN v1.1 P1-F1-T2(FR-13, NFR-06)/ ADR-0001(旧 H001)
- 前提: a003 受入済み。全変更は PR 経由。

## Objective

単一ソース `rules.src.md` から `CLAUDE.md` / `AGENTS.md` を生成するスクリプトと、手編集検出・120 行超過警告の CI 検査を、ユニットテスト付きで実装し PR でマージする。

追加(ユーザー指示 2026-07-18): 同一 PR に LICENSE 整備を含める。

- `LICENSE`: Apache License 2.0 の正文(改変なしの canonical text)。
- `NOTICE`: `herness-self-improvement` / `Copyright 2026 mryfmo <mryfmo@gmail.com>` の 2 行。
- `README.md` 末尾に License 節(Apache-2.0、NOTICE 参照)を 2〜3 行追記。

## 設計制約

- 依存追加禁止。実装は python3 標準ライブラリまたは POSIX sh(worker が選択、選択理由を report に記載)。
- `rules.src.md`: frontmatter 的なマーカーで「共通部 / CLAUDE.md 専用部 / AGENTS.md 専用部」を区分できる最小フォーマット(過剰な DSL 禁止。マーカー 3 種程度)。
- 生成物の冒頭に「GENERATED FILE — edit rules.src.md」ヘッダーと、生成器が算出するソース内容ハッシュを埋める。
- 手編集検出 = CI が生成器を再実行し、コミット済み生成物と一致しなければ fail。
- 行数検査 = 生成物が 120 行超なら警告(fail ではなく GitHub Actions の warning annotation)。
- 初期 `rules.src.md` の内容: 現 README の運用注記(単独運用・敵対的検証代替・pre-push ガード・PR 駆動)+ docs/ の 4 文書への地図。規範の新規発明はしない(将来 F3-T7 で還流される)。

## 配置

- `ci/generate-rules.py`(または .sh)— 生成器
- `ci/test_generate_rules.py`(または同等)— ユニットテスト(生成一致・ヘッダー・区分マーカー・行数検査の 4 観点以上)
- `rules.src.md`(リポジトリルート)
- `CLAUDE.md` / `AGENTS.md`(生成コミット)
- `.github/workflows/ci.yml` に生成物検証 + テスト実行ステップ追加(既存チェック維持)

## Allowed files

上記配置ファイル、`LICENSE`、`NOTICE`、`README.md`(License 節追記のみ)と PR ブランチ操作。`.orchestration/` は a004 の 5 artifact のみ。

## Forbidden actions

- docs/ 配下 4 文書の変更、保護/フック設定変更、依存追加、force-push、main 直接 push、他リポジトリ操作

## Validation

```sh
python3 ci/test_generate_rules.py   # または選択言語の実行方法
ci/generate-rules.py && git diff --exit-code CLAUDE.md AGENTS.md   # 冪等
sed -i '' 's/^/X/' CLAUDE.md 相当の手編集 → CI 検査が fail することの実証(ローカル実行で可)
wc -l CLAUDE.md AGENTS.md   # ≤ 120
# LICENSE が Apache-2.0 正文であること(canonical text との一致確認方法を validation に記録)
grep -c 'Apache License' LICENSE; grep -c 'Version 2.0, January 2004' LICENSE
cat NOTICE
gh pr checks <PR番号>
```

## Expected artifacts

- report: `.orchestration/reports/a004-report.md`
- validation: `.orchestration/validation/a004-validation.md`
- sandbox: `.orchestration/sandboxes/a004-sandbox.md`
- learning: `.orchestration/learning/a004-learning.md`
- autoskill: `.orchestration/autoskill/runs/a004-autoskill.md`

## Done signal

`AGMSG-RESULT v1 task_id=a004 status=ready_for_review report=... validation=... sandbox=... learning=... autoskill=...`
