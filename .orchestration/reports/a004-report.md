# a004 P1-F1-T2 Rules Generator Report

## Status

ready_for_review

## Result

- Pull request: https://github.com/mryfmo/herness-self-improvement/pull/3
- Squash merge: `bd8aa9b3d8faf0ebb9ca6afa6bfe4bed1b905d9c`
- Branch: `f1-t2/rules-generator-license`（merge 後に削除）

## Implementation choice

Python 3 標準ライブラリを選択した。`hashlib`、`pathlib`、`unittest`、`tempfile` だけで source hash、決定的生成、ファイル操作、5観点のテストを実装でき、POSIX/BSD/GNU 間の `sed -i` 差を generator 本体へ持ち込まず依存追加も不要になるため。

task が `python3` と依存追加禁止を明示し、pyproject/Makefile/pre-commit は allowed files 外であるため uv project 化は行っていない。

## Completed procedure

1. `rules.src.md` に `COMMON`、`CLAUDE`、`AGENTS` の3 HTML comment marker だけを持つ最小形式を定義した。
2. `ci/generate-rules.py` が source 全文の SHA-256 と generated-file 注意を冒頭に付け、共通部と対象専用部から `CLAUDE.md` / `AGENTS.md` を生成するよう実装した。
3. 生成器は各生成物が120行を超えた場合だけ GitHub Actions warning annotation を出し、exit failure にはしない。
4. `ci/test_generate_rules.py` に対象別区分、header/hash、3 marker 必須、冪等生成、120/121行境界 warning の5 tests を追加した。
5. CI は既存検査を維持し、unit test、再生成、`git diff --exit-code -- CLAUDE.md AGENTS.md` を追加した。
6. 初期 rules は既存 README の目的、4文書 map、単独運用、敵対的検証代替、pre-push guard、PR/CI flow だけを記載した。
7. Apache License 2.0 canonical text、指定2行の `NOTICE`、README 末尾の License 節を追加した。
8. `6644fad feat(rules): add generated agent maps and licensing`（`Agent: worker`）を feature branch へ push し、PR #3 の push/PR CI が green 後に squash merge した。

## Judgment

FR-13 の単一ソース・手編集検出と NFR-06 の120行 warning を、依存なしの小さい generator と unit test で満たした。LICENSE は Apache 公式正文と byte-for-byte 一致し、NOTICE はユーザー指定どおりである。禁止された docs、protection、hooks、依存、他 repository は変更していない。
