# a030 Report

## Status

- status: pr_open
- task: 第三者資産7件の無改変 vendor と登録台帳
- ledger: `hx-ff8b32a66241252f92bdb6dca8bcb629`
- branch: `a030/third-party-vendor`
- commit: `a450e34`
- PR: https://github.com/mryfmo/herness-self-improvement/pull/30

## Result

- `crit`、`ponytail`、`superpowers`、`typescript-lsp` をライセンス付きで固定した。
- `andrej-karpathy-skills`、`find-skills`、`improve` は D4 として取り込み、
  Apache-2.0 対象外・再配布不可を `LICENSE` notice、provenance、`NOTICE` に明記した。
- Git upstream 4件は commit / tree SHA、local source 3件は version / SHA-256 を記録した。
  上流 payload は file bytes、symlink target、mode を照合し、差異は0件だった。
- hooks、publish / sync、loopback server、install 手順、agent instruction file を
  実行面として列挙した。vendor を plugin、hook、skill、CLI の実行経路へ接続していない。
- secret scan は vendor を除外せず、35値・40箇所だけを完全一致 allowlist に追加した。
  全箇所はコード識別子、決定的テスト fixture、または文書化された dummy である。
- 既存の `customizable-agent-teams` も登録台帳へ追記し、上流 vendor と既存の
  安全適合レイヤを区別した。

## Review

Codex native review の3指摘中、secret-scan evidence の追跡と既存 vendor の台帳登録を
反映した。vendored agent instruction の自動発見リスクは、上流無改変と追加ファイル制約上
rename せず、vendor 配下を workdir / skill source にしない運用境界と F7 再パッケージ要件を
台帳に明記した。新たな実行配線は追加していない。
