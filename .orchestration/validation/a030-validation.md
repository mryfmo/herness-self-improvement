# a030 Validation

## Ledger and sources

task file と secret-scan addendum を全文読了後、ledger adapter で claim / start した。

```text
task_id=a030
ledger_id=hx-ff8b32a66241252f92bdb6dca8bcb629
owner=codex-gpt56solhigh-herness
state=running
```

```text
crit: commit 162981c16ed2df6c458c2a551ce8ba591b101316
      tree 9b3affb8af7a06eb2f5abbb7e593da90d5b36883
ponytail: commit 16f29800fd2681bdf24f3eb4ccffe38be3baec6b
          tree 956c22dde535d6e9a222c1e01a180c6e45d54a7e
superpowers: commit d884ae04edebef577e82ff7c4e143debd0bbec99
             tree 795caed14920f27a1d2d152a09b4720194f64472
andrej-karpathy-skills: commit 2c606141936f1eeef17fa3043a72095b4765b9c2
                          tree 02718e4654045f25a518093899502c8ee932eaf1
typescript-lsp: local cache 1.0.0
find-skills / improve: local install, per-file SHA-256 in PROVENANCE.md
```

`forrestchang/andrej-karpathy-skills` は GitHub で
`multica-ai/andrej-karpathy-skills` へ canonical redirect された。GitHub license
metadata は null だったため D4 のまま扱った。

## Payload fidelity

source tree と vendor payload について regular file bytes、symlink target、permission
mode を比較した。許可された `PROVENANCE.md`、D4 の repository-side `LICENSE` notice、
typescript-lsp cache の runtime `.in_use` marker だけを比較対象外にした。

```text
crit: source_files=760 payload_files=760 mismatches=0
ponytail: source_files=156 payload_files=156 mismatches=0
superpowers: source_files=172 payload_files=172 mismatches=0
andrej-karpathy-skills: source_files=9 payload_files=9 mismatches=0
typescript-lsp: source_files=2 payload_files=2 mismatches=0
find-skills: source_files=1 payload_files=1 mismatches=0
improve: source_files=4 payload_files=4 mismatches=0
```

Git upstream 4件は `PROVENANCE.md` と許可された D4 `LICENSE` notice を除いた tree を
Git object 化し、記録した upstream tree SHA とも照合した。root / nested `.gitignore`
による欠落を防ぐため、vendor path は force-add 後に再照合した。

## Secret scan exception audit

初回 scan は `crit` と `superpowers` の40箇所、35 distinct value を
`key_value_secret` として検出した。各 context を実見し、値の形と用途を確認した。
実鍵または由来を確信できない高エントロピー値は0件だった。下表は生値を記載せず、
完全一致値の SHA-256 先頭12桁で同一性を示す。

| Location | Match SHA-256 prefix | Rule | Verified rationale |
| --- | --- | --- | --- |
| `vendor/crit/internal/auth/auth.go:102` | `c000aeb8c999` | `key_value_secret` | code identifier/property false positive |
| `vendor/crit/internal/auth/auth_test.go:662` | `10e79311f87c` | `key_value_secret` | deterministic test fixture or documented example |
| `vendor/crit/internal/server/server.go:425` | `9694587ffe49` | `key_value_secret` | code identifier/property false positive |
| `vendor/crit/internal/server/server.go:774` | `177334145662` | `key_value_secret` | code identifier/property false positive |
| `vendor/crit/internal/server/server_test.go:1235` | `ddc50827132b` | `key_value_secret` | deterministic test fixture or documented example |
| `vendor/crit/internal/share/share_test.go:881` | `ddc50827132b` | `key_value_secret` | deterministic test fixture or documented example |
| `vendor/crit/internal/share/share_test.go:963` | `ddc50827132b` | `key_value_secret` | deterministic test fixture or documented example |
| `vendor/crit/internal/server/server_test.go:1306` | `eeb0fd914088` | `key_value_secret` | deterministic test fixture or documented example |
| `vendor/crit/internal/session/session_write.go:160` | `24e63e128718` | `key_value_secret` | code identifier/property false positive |
| `vendor/crit/internal/share/cli.go:316` | `9aca84cd67f3` | `key_value_secret` | code identifier/property false positive |
| `vendor/crit/internal/share/share_test.go:893` | `dec7d211af4e` | `key_value_secret` | deterministic test fixture or documented example |
| `vendor/crit/internal/share/share_test.go:975` | `9ede66cdc1ef` | `key_value_secret` | deterministic test fixture or documented example |
| `vendor/crit/web/app.js:865` | `25bb08930f09` | `key_value_secret` | code identifier/property false positive |
| `vendor/crit/web/app.js:866` | `a2eefd46cba4` | `key_value_secret` | code identifier/property false positive |
| `vendor/crit/web/crit-line-blocks.js:494` | `a751d827fcf7` | `key_value_secret` | code identifier/property false positive |
| `vendor/crit/web/crit-line-blocks.js:496` | `a35726a909ec` | `key_value_secret` | code identifier/property false positive |
| `vendor/crit/web/crit-line-blocks.js:497` | `bcce3b230c79` | `key_value_secret` | code identifier/property false positive |
| `vendor/crit/web/crit-share.js:55` | `2b2675db6935` | `key_value_secret` | code identifier/property false positive |
| `vendor/crit/web/crit-share.js:56` | `9946f4ce1f6b` | `key_value_secret` | code identifier/property false positive |
| `vendor/crit/web/crit-share.js:342` | `35c601e32fdf` | `key_value_secret` | code identifier/property false positive |
| `vendor/crit/web/crit-share.js:353` | `ec7e18a95a51` | `key_value_secret` | code identifier/property false positive |
| `vendor/crit/web/crit-share.js:374` | `6fc9b0c94765` | `key_value_secret` | code identifier/property false positive |
| `vendor/crit/web/crit-share.js:379` | `d3844ba20ef4` | `key_value_secret` | code identifier/property false positive |
| `vendor/crit/web/live-mode.js:378` | `98a05083b5bf` | `key_value_secret` | code identifier/property false positive |
| `vendor/crit/web/live-mode.js:379` | `205ea809b9b8` | `key_value_secret` | code identifier/property false positive |
| `vendor/crit/web/markdown-it.min.js:2` | `d6a89bfe06ea` | `key_value_secret` | code identifier/property false positive |
| `vendor/crit/web/markdown-it.min.js:2` | `d6a89bfe06ea` | `key_value_secret` | code identifier/property false positive |
| `vendor/crit/web/mermaid.min.js:257` | `f2ed9f031fc6` | `key_value_secret` | code identifier/property false positive |
| `vendor/crit/web/mermaid.min.js:1226` | `4d820b633981` | `key_value_secret` | code identifier/property false positive |
| `vendor/crit/web/mermaid.min.js:1226` | `7457102fb9be` | `key_value_secret` | code identifier/property false positive |
| `vendor/crit/web/mermaid.min.js:1243` | `ba9bb5cc9294` | `key_value_secret` | code identifier/property false positive |
| `vendor/crit/web/mermaid.min.js:1243` | `68dfbe1ff92f` | `key_value_secret` | code identifier/property false positive |
| `vendor/superpowers/docs/superpowers/plans/2026-06-11-visual-companion-final-hardening-fixup.md:331` | `304151bd5a3f` | `key_value_secret` | deterministic test fixture or documented example |
| `vendor/superpowers/tests/brainstorm-server/lifecycle.test.js:353` | `304151bd5a3f` | `key_value_secret` | deterministic test fixture or documented example |
| `vendor/superpowers/docs/superpowers/plans/2026-06-11-visual-companion-final-hardening-fixup.md:387` | `9cf3a61a3095` | `key_value_secret` | deterministic test fixture or documented example |
| `vendor/superpowers/tests/brainstorm-server/lifecycle.test.js:403` | `9cf3a61a3095` | `key_value_secret` | deterministic test fixture or documented example |
| `vendor/superpowers/tests/brainstorm-server/auth.test.js:26` | `093e98a0402c` | `key_value_secret` | deterministic test fixture or documented example |
| `vendor/superpowers/tests/brainstorm-server/branding.test.js:16` | `ccf79b8d85f0` | `key_value_secret` | deterministic test fixture or documented example |
| `vendor/superpowers/tests/brainstorm-server/lifecycle.test.js:250` | `cfb4d11aa6b2` | `key_value_secret` | deterministic test fixture or documented example |
| `vendor/superpowers/tests/brainstorm-server/server.test.js:25` | `ecb360dba9a0` | `key_value_secret` | deterministic test fixture or documented example |

allowlist は35値と一致し、全 entry の直前に vendor名・location・理由の comment がある。
vendor 全体除外、regex変更、scanner弱体化はしていない。

```text
vendor_match_locations=40 distinct_matches=35
allowlist_entries=35 exact_set=True every_entry_commented=True
python3 ci/secret-scan.py
secret scan clean
```

## Execution boundary and checks

`crit` の harness hooks / loopback server / share / GitHub sync、`ponytail` の
lifecycle hooks / publish、`superpowers` の SessionStart / GitHub sync / localhost
server、text-only assets の install / issue手順を各 provenance に列挙した。
`.claude`、`.codex`、`.github`、`bin` から7 vendor path への参照は0件だった。

vendored `AGENTS.md` / `CLAUDE.md` は上流 tree の一部で、配下を agent workdir にした
場合は自動発見され得る。無改変制約に従い rename せず、vendor を workdir / skill source
にしないこと、F7 再パッケージ時に除外することを registry に明記した。

```text
ci/test_sqlite_load.sh
hx profile PASS; mixed profile PASS; missing=0; deadlocks=0

ci/test_evidence_gates.sh
PASS: evidence record, trace, validation, and append-only enforcement
PASS: frozen modification, addition, deletion, and manifest refresh
PASS: dummy secret detection, non-disclosure, and exact allowlist

python3 ci/hash-freeze.py verify
verified 48 frozen files

python3 ci/check-docs.py
docs check passed (29 documents)
```

`ci/secret-allowlist.txt` の変更に対応して、`ci/frozen-manifest.json` は同ファイルの
SHA-256 1件だけを更新した。full `git diff --check` が報告する whitespace は upstream
payload と一致し、修正すると無改変性を壊すため保持した。当方の governance / artifact
変更に限定した diff check は成功した。

## Review

`make require-crit-review` は target 不在だった。Codex native review は3件を報告し、
evidence 欠落と既存 vendor の台帳欠落を修正した。agent instruction の指摘は上記の
運用境界と残存リスクとして記録した。vendor payload は変更していない。

PR: https://github.com/mryfmo/herness-self-improvement/pull/30
