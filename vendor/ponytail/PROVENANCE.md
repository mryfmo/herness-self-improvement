# Provenance

- Upstream: https://github.com/DietrichGebert/ponytail
- Retrieved: 2026-07-21
- Commit: `16f29800fd2681bdf24f3eb4ccffe38be3baec6b`
- Git tree: `956c22dde535d6e9a222c1e01a180c6e45d54a7e`
- License: MIT（upstream `LICENSE`）

`PROVENANCE.md` を除く内容は上記 commit の tracked tree と同一である。
利用は当リポジトリ内に限る。marketplace での再配布は F7-T1 の再パッケージ審査後とする。

## 実行面

- `SessionStart`、`SubagentStart`、`UserPromptSubmit` から Node.js を呼ぶ lifecycle hooks
- OpenClaw skill の build/check scripts
- `clawhub skill publish` を起動する publish script
- uninstall script と GitHub Actions の publish workflow

この vendor tree は保管・審査用であり、hook、plugin、publish の実行経路には接続していない。
