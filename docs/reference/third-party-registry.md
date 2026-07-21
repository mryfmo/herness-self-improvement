---
owner: harness-operators
last-verified: 2026-07-21
freshness: 90d
---

# Third-party registry

第三者資産は `vendor/` で保管・審査する。plugin manifest、settings、hook からは参照せず、
稼働中の個人 install と切り離している。F7-T1 で再パッケージを審査するまでは、
このリポジトリ内での確認に限る。

vendor 内の上流 `AGENTS.md` / `CLAUDE.md` は無改変性の対象であり、agent がその
配下を作業ディレクトリにすると harness に発見され得る。vendor は作業ディレクトリや
skill 読込元にせず、F7-T1 ではこれらを除いた再パッケージを審査する。

secret scan の exact-match 例外は `crit` と `superpowers` に35値ある。40箇所すべての
ファイル・行・良性根拠は task a030 の `.orchestration/validation/a030-validation.md`
に記録した。vendor 全体を走査対象に残したまま、値単位で許可している。

| Asset | 状態 | 固定元 | License | D4 | 実行面 | F7 の扱い |
| --- | --- | --- | --- | --- | --- | --- |
| [crit](../../vendor/crit/PROVENANCE.md) | vendored | `162981c` | MIT | no | harness hooks、loopback server、share、GitHub sync、E2E scripts | hooks / network を分離審査して再パッケージ |
| [ponytail](../../vendor/ponytail/PROVENANCE.md) | vendored | `16f2980` | MIT | no | lifecycle hooks、build/uninstall、ClawHub publish | hooks / publish を分離審査して再パッケージ |
| [superpowers](../../vendor/superpowers/PROVENANCE.md) | vendored | `d884ae0` | MIT | no | SessionStart、GitHub sync、localhost companion server | 必要 skill と実行面を選別して再パッケージ |
| [typescript-lsp](../../vendor/typescript-lsp/PROVENANCE.md) | vendored | cache `1.0.0` | Apache-2.0 | no | README に npm / yarn install 手順。hook/script なし | LSP 依存を含めて再パッケージ審査 |
| [andrej-karpathy-skills](../../vendor/andrej-karpathy-skills/PROVENANCE.md) | vendored | `2c60614` | none identified | yes | prompt のみ。hook/script なし | ライセンス確定まで再配布不可 |
| [find-skills](../../vendor/find-skills/PROVENANCE.md) | vendored | local payload hash | unknown | yes | `npx skills`、skills.sh、GitHub の検索・導入手順 | origin / license 確定まで再配布不可 |
| [improve](../../vendor/improve/PROVENANCE.md) | vendored | local payload hashes | origin unknown | yes | read-only audit、subagent、明示時の GitHub issue 作成手順 | origin / license 確定まで再配布不可 |
| [customizable-agent-teams](../../vendor/customizable-agent-teams/PROVENANCE.md) | vendored + integrated | `2e47a0f` | none identified | yes | 上流 tree は保管のみ。別の安全適合レイヤが `hx-team.sh` から Herdr を起動 | 上流は再配布不可。適合レイヤを個別審査 |

## Reference-install-only

Codex runtime と connector plugin はコピーしない。現在の install を参照し、F7 では
許可 scope、重複版、配布条件だけを管理する。

| Assets | 状態 | License | 実行面 | F7 の扱い |
| --- | --- | --- | --- | --- |
| browser / chrome | reference-install-only | runtime 管理、未確認 | browser client、native host、user-specified target | runtime 配布を維持。再パッケージしない |
| documents / presentations / spreadsheets | reference-install-only | runtime 管理、未確認 | artifact、Google Docs / Slides / Sheets runtime | runtime 配布を維持。再パッケージしない |
| data-analytics / github / google-drive / product-design / openai-templates / codex-security | reference-install-only | plugin ごとに未確認 | connector、Sites、local helper scripts | license と connector 条件を確認するまで方針管理のみ |
