# a016 Validation

## A014-17 reproduction

scratch DB を migration 済みにした後、`0002_ledger` entry、`hx_task_messages`、`hx_tasks` だけを削除して `status` を実行した。

```text
0001_telemetry applied
0002_ledger pending
exit=1
```

出力の完全一致と非ゼロ終了を shell の `test` でも確認した。実運用 agmsg DB は使用していない。

## Required checks

```text
ci/test_migrations.sh && ci/test_task_ledger.sh
PASS: missing 0002 is reported and fails
PASS: up/up, FTS5, foreign keys, append-only audit, WAL, busy_timeout
PASS: down/down
PASS: final up
PASS: schema documentation table names
PASS: normal terminal paths and invalid transitions
PASS: idempotent create and SQL quoting
PASS: timed requeue and attempts ceiling
PASS: required payload validation
PASS: ledger up/up/down/down/up

python3 ci/hash-freeze.py verify
verified 35 frozen files

python3 ci/check-docs.py
docs check passed (21 documents)
```

## Additional local checks

```text
sh -n db/migrate.sh ci/test_migrations.sh ci/test_task_ledger.sh
PASS

python3 -m json.tool ci/frozen-manifest.json
PASS

ci/test_evidence_gates.sh
PASS: evidence record, trace, validation, and append-only enforcement
PASS: frozen modification, addition, deletion, and manifest refresh
PASS: dummy secret detection, non-disclosure, and exact allowlist

ci/test_sqlite_load.sh
hx profile: nfr03=PASS
mixed profile: nfr03=PASS

python3 ci/secret-scan.py
secret scan clean

git diff --cached --check
PASS
```

rules generator、docs checker の unit tests、生成物無差分も成功した。

## Frozen scope

`ci/frozen-paths.txt` へ次の2件を追加した。

```text
docs/decisions/
docs/specs/discipline-v1.0.md
```

manifest は35ファイルを収録し、ADR-0001〜0008、ADR束、ADR index、三軸規律を含む。`ci/hash-freeze.py verify` はローカルと全 GitHub CI で成功した。

## Diff scope

```text
M ci/frozen-manifest.json
M ci/frozen-paths.txt
M ci/test_migrations.sh
M ci/test_task_ledger.sh
M db/migrate.sh
M docs/reference/evidence-and-gates.md
```

source commit `5fb24b02d777d10f4bb7abccc11b3a4b3c9e5083` は 6 files、61 insertions、16 deletions。4文書、ADR群、三軸規律本文、workflow に差分がないことを `git diff --exit-code` で確認した。

## Review gate

```sh
make require-crit-review
```

```text
make: *** No rule to make target `require-crit-review'. Stop.
```

repository に Crit gate target は未実装。ブラウザ Crit は使用せず、staged diff と禁止ファイル無差分を直接確認した。

## Pull request and CI

```text
PR=https://github.com/mryfmo/herness-self-improvement/pull/14
source commit=5fb24b02d777d10f4bb7abccc11b3a4b3c9e5083
merge commit=53db170c5f4470a9fd146621995a08455a78978b
push ci=https://github.com/mryfmo/herness-self-improvement/actions/runs/29670982133/job/88149756332
pull-request ci=https://github.com/mryfmo/herness-self-improvement/actions/runs/29671003608/job/88149816242
main merge ci=https://github.com/mryfmo/herness-self-improvement/actions/runs/29671030471/job/88149891488
checks=all successful, 0 failing, 0 pending
```

PR の full body、`Agent: worker` footer、commit trailer、6-file diff を `gh` で確認した。CodeRabbit、push CI、pull-request CI、main CI は成功し、review / inline comments は 0 件。main / origin/main は merge commit に一致する。

## Network boundary

GitHub 操作だけを許可範囲として、`git push` と `gh` による PR / checks / merge 確認を実施した。外部 Web は取得していない。
