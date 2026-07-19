# a008 P1-F1-T6 Evidence / Closed Gates / Data Guards Report

## Status

ready_for_review

## Result

- Pull request: https://github.com/mryfmo/herness-self-improvement/pull/7
- Squash merge: `10292331026807fd3703ad1a3663c5818cbdb83b`
- Branch: `f1-t6/evidence-gates-guards`（merge 後に削除）
- Dependencies added: none

## Premise correction

SPEC assumption A-5 が想定する、AIDD Platform の evidence store / closed gate / data guard を再利用できる3部品は存在しなかった。近縁の TypeScript source 2件は読み取り専用で設計原則と検出カテゴリだけを確認し、コードはコピーしていない。Node/pnpmも導入せず、shellとPython標準ライブラリで独立した最小実装とした。

SPEC A-5本文はtaskの禁止範囲なので変更していない。将来のSPEC改訂で前提を修正する必要がある。

## Implementation

- `db/hx-evidence.sh`: 既存append-only `hx_audit`へのrecord、list、trace。既存migrated DB、valid JSON、non-empty identityを要求し、ホーム `.agents` 配下を拒否する。
- `ci/hash-freeze.py`: `githooks/`、`ci/`、`db/`、`.github/workflows/` のregular filesをdeterministic SHA-256 manifestへfreeze/verifyする。manifest自身、Python bytecode、`__pycache__`は除外し、symlinkを拒否する。
- `ci/secret-scan.py`: API key/token、bearer、secret-like assignment、JWT、private-key headerを走査し、findingにはpath/line/classだけを表示する。exact allowlistを提供する。
- `ci/test_evidence_gates.sh`: evidence往復とappend-only拒否、freeze対象の改変・追加・削除、dummy secret検出・非表示・allowlistをbehavioral testとして確認する。
- CI: behavioral test、21-file frozen manifest verify、repository secret scanを追加した。
- Reference: 3部品の呼出し口とA-5訂正を `docs/reference/evidence-and-gates.md` に記録した。

## Completed procedure

1. task fileを最初に読み、AIDD再利用前提の訂正とallowed/forbidden scopeを確認した。
2. AIDD source 2件を読み取り専用で参照し、コードをコピーしない方針を確定した。
3. 先行testを作り、最初のentrypoint不在で失敗することを確認した。
4. 3部品、config、manifest、reference、CI stepsを実装した。
5. 新規behavioral testと既存CI、ShellCheck、Python compile、diff checkを通した。
6. PR #7の本文、commit、9-file diff、CI、inline commentを `gh` で確認した。
7. 全checks成功後にsquash mergeし、main上で3つのtask validationを再実行した。

実運用agmsg DB、AIDD repository、保護された4文書、protection/hooks、dependenciesは変更していない。
