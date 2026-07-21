# Provenance

- Upstream: https://github.com/tomasz-tomczyk/crit
- Retrieved: 2026-07-21
- Commit: `162981c16ed2df6c458c2a551ce8ba591b101316`
- Git tree: `9b3affb8af7a06eb2f5abbb7e593da90d5b36883`
- License: MIT（upstream `LICENSE`）

`PROVENANCE.md` を除く内容は上記 commit の tracked tree と同一である。
利用は当リポジトリ内に限る。marketplace での再配布は F7-T1 の再パッケージ審査後とする。

## 実行面

- Claude Code の `PermissionRequest`、Codex の `Stop` など、各 harness 向け hook manifest
- `crit` の loopback HTTP server、指定 URL の proxy、`crit.md` への share
- `gh` を使った GitHub PR comment の同期
- build / E2E 用 shell scripts

この vendor tree は保管・審査用であり、hook、plugin、CLI の実行経路には接続していない。
