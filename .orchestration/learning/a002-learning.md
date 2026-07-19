# a002 Learning Triage

- disposition: candidate-only
- promoted: false
- learning: private GitHub repository の protection entitlement を事前確認し、利用不可なら公開化を自動選択せず、明示承認された version-controlled hook + PR + CI を代償統制とする。
- evidence: protection / ruleset API の HTTP 403、PR #1 の CI green と squash merge、pre-push hook の実拒否。
- apply_to: P1-F1-T0 bootstrap preflight
- ceiling: ローカル hook は clone ごとの設定が必要で `--no-verify` を防げないため、server-side protection を F1-T9 までに再評価する。
- promotion: task では禁止されているため未実施
