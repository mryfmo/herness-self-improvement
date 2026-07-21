# Provenance

- Upstream: https://github.com/obra/superpowers
- Retrieved: 2026-07-21
- Commit: `d884ae04edebef577e82ff7c4e143debd0bbec99`
- Git tree: `795caed14920f27a1d2d152a09b4720194f64472`
- License: MIT（upstream `LICENSE`）

`PROVENANCE.md` を除く内容は上記 commit の tracked tree と同一である。
利用は当リポジトリ内に限る。marketplace での再配布は F7-T1 の再パッケージ審査後とする。

## 実行面

- local command を呼ぶ `SessionStart` hook
- `gh repo clone`、`git push`、`gh pr create` を含む Codex plugin 同期 script
- package/version/lint scripts
- 既定で `127.0.0.1` に bind する brainstorming companion server

この vendor tree は保管・審査用であり、hook、plugin、sync、server の実行経路には接続していない。
