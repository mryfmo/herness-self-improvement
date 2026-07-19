# a014 Validation

## Independence

- `.orchestration/tasks/a014-independent-audit-three-axis.md` を inbox 後の最初の repository task source として読んだ。
- 禁止された `.orchestration/reports/orchestrator-audit-v2-findings.md` は直接開いておらず、内容をモデルへ表示・検索・引用していない。
- ただし `python3 ci/secret-scan.py` は `Path.cwd().rglob("*")` で repository text 全体を読む実装であり、禁止 file も間接走査した。出力は `secret scan clean` のみだったため内容は worker へ露出していないが、strict read prohibition は違反した。
- 外部 Web、GitHub API、remote fetch は使用していない。
- subagent は使用せず、単一 worker が自力で走査した。

## Coverage

```text
SPEC files=1
ADR files=8
WORKPLAN files=1
WORKPLAN task headings=79
reference pages=7
implementation text/config files=25
supporting canonical-map files=6
```

### Read files

```text
docs/specs/SPEC-HARNESS-SELF-IMPROVEMENT-v1.0.md
docs/decisions/ADR-0001-git-single-source-of-truth.md
docs/decisions/ADR-0002-two-layer-memory.md
docs/decisions/ADR-0003-ace-knowledge-refinement.md
docs/decisions/ADR-0004-fail-closed-pr-pipeline.md
docs/decisions/ADR-0005-three-scope-promotion.md
docs/decisions/ADR-0006-skill-supply-chain-governance.md
docs/decisions/ADR-0007-loop-graph-anchoring.md
docs/decisions/ADR-0008-recursive-self-improvement-strata.md
docs/plans/WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.1.md
docs/reference/REPORT-HARNESS-SELF-IMPROVEMENT-v1.0.md
docs/reference/branch-protection.md
docs/reference/evidence-and-gates.md
docs/reference/llm-wiki-genealogy.md
docs/reference/sqlite-load-test.md
docs/reference/telemetry-schema.md
docs/reference/wiki-conventions.md
githooks/pre-push
ci/.gitkeep
ci/check-docs.py
ci/docs-frontmatter-exempt.txt
ci/frozen-manifest.json
ci/frozen-paths.txt
ci/generate-rules.py
ci/hash-freeze.py
ci/secret-allowlist.txt
ci/secret-scan.py
ci/test_check_docs.py
ci/test_evidence_gates.sh
ci/test_generate_rules.py
ci/test_migrations.sh
ci/test_sqlite_load.sh
ci/test_task_ledger.sh
db/hx-evidence.sh
db/hx-task.sh
db/load-test.sh
db/migrate.sh
db/migrations/0001_telemetry.down.sql
db/migrations/0001_telemetry.up.sql
db/migrations/0002_ledger.down.sql
db/migrations/0002_ledger.up.sql
.github/workflows/ci.yml
README.md
rules.src.md
AGENTS.md
CLAUDE.md
docs/decisions/ADR-HARNESS-SELF-IMPROVEMENT-v1.0.md
docs/decisions/README.md
```

Python bytecodeは binary/generated なので内容監査の対象外とした。

## Scan commands

```sh
rg --files docs/specs docs/decisions docs/plans docs/reference githooks ci db .github | sort
find docs/specs docs/decisions docs/plans docs/reference githooks ci db .github -type f -not -path '*/__pycache__/*' -exec wc -l {} +
nl -ba <各対象ファイル>
rg -c '^\*\*P1-F[0-9]+-T[0-9]+' docs/plans/WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.1.md
rg -n 'ADR-000[78]|接地|メタ指標|カナリア|不動点|循環検査' docs/plans/WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.1.md
rg -n 'WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1\.0|ADR-HARNESS-SELF-IMPROVEMENT-v1\.0' README.md rules.src.md CLAUDE.md AGENTS.md docs/
rg -n '一括再生成|一括リライト|40%' SPEC ADR-0003 WORKPLAN
rg -n 'frontmatter|exempt|freshness|TTL' SPEC WORKPLAN wiki-conventions ci/docs-frontmatter-exempt.txt ci/check-docs.py
rg -n 'hx-task|hx_tasks|task.assign|AGMSG-TASK' db ci SPEC WORKPLAN README.md rules.src.md .github githooks
git config --get core.hooksPath
git log --oneline -20 -- docs githooks ci db .github
```

`WORKPLAN` の ADR-0007/0008 関連語検索は 0 件だった。閾値・L2 change site は別検索で F3-T6、F4-T9、F5-T6、F6-T8 等を確認した。

## Read-only checks

```text
python3 ci/test_generate_rules.py
Ran 5 tests: OK

python3 ci/test_check_docs.py
Ran 5 tests: OK

python3 ci/check-docs.py
docs check passed (20 documents)

ci/test_migrations.sh
PASS: up/up, FTS5, foreign keys, append-only audit, WAL, busy_timeout
PASS: down/down
PASS: final up
PASS: schema documentation table names

ci/test_task_ledger.sh
PASS: normal terminal paths and invalid transitions
PASS: idempotent create and SQL quoting
PASS: timed requeue and attempts ceiling
PASS: required payload validation
PASS: ledger up/up/down/down/up

ci/test_evidence_gates.sh
PASS: evidence record, trace, validation, and append-only enforcement
PASS: frozen modification, addition, deletion, and manifest refresh
PASS: dummy secret detection, non-disclosure, and exact allowlist

python3 ci/hash-freeze.py verify
verified 24 frozen files

python3 ci/secret-scan.py
secret scan clean

ci/test_sqlite_load.sh
hx: nfr03=PASS, missing=0, deadlocks=0, p95=9.367ms
mixed: nfr03=PASS, missing=0, deadlocks=0, p95=9.884ms
```

いずれも repository source は変更せず、scratch data は OS の temporary directory だけに作成された。

## Targeted reproduction

0002 ledger を scratch DB から除去した状態で migration status を実行した。

```text
ledger_rows=0001_telemetry
status_output=0001_telemetry applied
hx_tasks_exists=0
```

A014-17 を再現した。scratch DB は終了時に削除した。

## Artifact validation

```text
required artifacts=5
report finding rows=19
report types: contradiction=5, omission=8, error=5, ambiguity=1
forbidden findings file direct/model read=NO
forbidden findings file indirect scanner traversal=YES
external web fetch=NO
repository source changes=NO
```

このため a014 の status は `blocked`。同じ independence requirement を満たす再監査では、全 repository scanner を使わず、明示 allowlist の対象 path だけを検査する必要がある。
