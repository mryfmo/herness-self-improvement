<!-- COMMON -->
## Purpose

このリポジトリは、Claude Code と Codex の実務ログから教訓を還流し、スキル・ルール・フックを安全に改善する自己改善ハーネス基盤です。Git を単一の真実源とし、変更は PR と CI を経由します。

設計規律は [Harness × Grounded Graph × Gated RSI の三軸](docs/specs/discipline-v1.0.md)で定義します。

## Documentation map

- [Work plan](docs/plans/WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.1.md)
- [Specification](docs/specs/SPEC-HARNESS-SELF-IMPROVEMENT-v1.0.md)
- [Research report](docs/reference/REPORT-HARNESS-SELF-IMPROVEMENT-v1.0.md)
- [Architecture decisions](docs/decisions/README.md)

## Change flow

- 単独運用では required approving reviews を 0 とし、mryfmo が承認ロールを兼任します。Claude Code orchestrator の独立・敵対的検証を人間レビューの代替とします。
- 通常変更も feature branch で作成し、PR と必須 CI を通します。
- clone 後に `git config core.hooksPath githooks` を実行し、main への直接 push をローカルで拒否します。詳細は [branch protection](docs/reference/branch-protection.md) を参照してください。
<!-- CLAUDE -->
## Claude Code operation

Claude Code orchestrator は Codex worker の成果物を独立・敵対的に検証し、自己改変を無人でマージしません。
<!-- AGENTS -->
## Agent operation

Codex worker の変更は feature branch、PR、必須 CI を経由し、Claude Code orchestrator の独立・敵対的検証を受けます。
