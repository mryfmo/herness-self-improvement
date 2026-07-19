# Harness Self Improvement

Claude Code と Codex の実務ログから教訓を還流し、スキル・ルール・フックを安全に改善する自己改善ハーネス基盤です。Git を単一の真実源とし、変更は PR と CI を経由します。

## Canonical documents

- [Work plan](docs/plans/WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.1.md)
- [Specification](docs/specs/SPEC-HARNESS-SELF-IMPROVEMENT-v1.0.md)
- [Three-axis discipline](docs/specs/discipline-v1.0.md)
- [Research report](docs/reference/REPORT-HARNESS-SELF-IMPROVEMENT-v1.0.md)
- [Architecture decisions](docs/decisions/README.md)

## Repository map

SPEC 5.1 の構成を次の責務に分けます。

```text
docs/                         LLM Wiki（decisions, plans, specs, reference, lessons）
.claude/skills/               スキル定義・補助スクリプト・評価
.claude/agents/               SubAgent 定義
.claude/hooks/                テレメトリ収集と実行時ガード
.claude/commands/             定型ワークフロー
ci/                           lint・scan・eval・生成物検証
```

`CLAUDE.md` と `AGENTS.md` は後続タスクで単一ソースから生成する短いマップとして追加します。

## Operation

単独運用では required approving reviews を 0 とし、mryfmo が承認ロールを兼任します。通常変更も feature branch で作成し、PR と必須 CI を通します。Claude Code orchestrator は Codex worker の成果物を独立・敵対的に検証し、自己改変を無人でマージしません。

clone 後に `git config core.hooksPath githooks` を実行し、main への直接 push をローカルで拒否してください。制約とサーバー側設定の再現手順は [branch protection](docs/reference/branch-protection.md) を参照してください。

## License

Licensed under the Apache License 2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
