---
owner: harness-operators
last-verified: 2026-07-19
freshness: 90d
---

# SKILL.md frontmatter 標準 v1

この標準は personal、project、org の三層で SKILL.md の由来と保守責任を
追跡するためのもの。Agent Skills の起動キーである `name` と `description` は
top-level に残し、統制用の項目を `metadata` 配下へ置く。

## 必須項目

| 項目 | v1 の制約 |
|---|---|
| `name` | 64 文字以内。小文字英数字と単一ハイフン区切り |
| `description` | 1024 文字以内で `<` / `>` を含まない文字列。何をするかと、いつ使うかを書く |
| `metadata.scope` | `personal`、`project`、`org` のいずれか |
| `metadata.owner` | 空でない個人名またはチーム名 |
| `metadata.last-verified` | `YYYY-MM-DD` |
| `metadata.freshness` | 再検証までの日数。正の整数 + `d`（例: `90d`） |
| `metadata.provenance` | 自作は `self`。外部資産は `repo=owner/repo; license=SPDX` |

`provenance` の外部資産形式は、暫定 scanner が Python 標準ライブラリだけで
確実に読める単一行に固定する。`license` には確認済みの SPDX identifier を書く。
ライセンスファイルを確認できない資産は標準化を保留し、`unknown` のまま移行しない。

`metadata.triggers` と `metadata.dependencies` は任意。文字列または YAML
sequence で記録できる。`license` や `allowed-tools` など platform 固有の
top-level 項目も残してよい。v1 scanner は未知の項目を拒否しない。

```yaml
---
name: release-check
description: Run the repository release checks before a pull request or merge.
metadata:
  scope: project
  owner: release-engineering
  last-verified: 2026-07-19
  freshness: 90d
  provenance: self
  triggers:
    - release check
    - pre-merge verification
  dependencies:
    - mise
---
```

外部資産は次の形になる。

```yaml
metadata:
  provenance: repo=obra/superpowers; license=MIT
```

## Claude Code / Codex 互換性

相互運用の核は `name` と `description`。この 2 項目の名前と意味を変えないため、
Claude Code と Codex の既存の skill 選択はそのまま動く。統制用の追加項目は
選択ロジックではなく、このリポジトリの CI が読む。

2026-07-19 時点のローカル確認では、Codex の skill-creator は起動判定に
`name` と `description` だけを読むと明記している。同梱 validator の
top-level allowlist には `metadata`、`license`、`allowed-tools` が含まれる。
この標準は独自項目を `metadata` の内側へ置くため、その validator と衝突しない。
`metadata` を持つ installed skill が Claude Code / Codex の一覧へ読み込まれる
ことも確認済み。runtime 更新時と P1-F5-T5 の代表 skill 互換試験で再検証する。

## 暫定 skill-scan

`ci/skill-scan.py` は既定で `.claude/skills/**/SKILL.md` を調べる。
任意の SKILL.md または親 directory も引数で渡せる。

```sh
python3 ci/skill-scan.py
python3 ci/skill-scan.py ~/.agents/skills/gh-first-workflow
```

現行 gate は次を行う。

- v1 の必須 frontmatter と値形式を検査する
- SKILL.md 本文の ``!`command` `` 形式を検出したら fail する
- SKILL.md と同階層の `scripts/` を走査する
- SKILL.md または `scripts/` 配下の symlink を fail する
- `ci/secret_patterns.py` の規則で秘密情報を検出し、値を表示せず fail する
- scripts 内の URL / domain を `unknown-network` として列挙する

`unknown-network` はこの暫定版では情報表示であり、終了 status を変えない。
[ADR-0006](../decisions/ADR-0006-skill-supply-chain-governance.md) が求める
悪性パターン照合、難読化検出、network allowlist 照合は P1-F4-T6 で追加する。
それまでは `unknown-network` のある skill を自動移行・昇格しない。
