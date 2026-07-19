---
owner: mryfmo
last-verified: 2026-07-19
freshness: 90d
---

# Evidence store and closed gates

## Premise correction

SPEC assumption A-5 says the AIDD Platform closed gates, data guards, and evidence store can be reused as typed code. Repository inspection on 2026-07-19 found no reusable three-component package.

The closest references are:

- `ai-ops-platform/packages/shared/src/auditLog.ts`
- `ai-ops-platform/packages/shared/src/secretSanitizer.ts`

They are TypeScript components in a Node/pnpm workspace and do not provide the requested SHA-256 freeze gate. Copying them would add an incompatible toolchain and a second maintenance line. This repository therefore uses an independent minimal Python/shell implementation. The AIDD files were read only for the append-only, traceability, and secret-category design principles; no code was copied or modified.

A future SPEC revision must replace A-5 with this corrected premise. The four protected SPEC/WORKPLAN/REPORT/ADR bodies remain unchanged in P1-F1-T6.

## Evidence store

The existing `hx_audit` table is the evidence store. Its database triggers reject UPDATE and DELETE.

```sh
db/hx-evidence.sh <db-path> record <actor> <event> <ref> <detail-json>
db/hx-evidence.sh <db-path> list
db/hx-evidence.sh <db-path> trace <ref>
```

`record` requires non-empty actor, event, and ref values plus valid JSON detail. It returns the inserted row id. `trace` orders matching evidence by row id. The command requires an existing migrated database.

Paths under the live home `.agents` directory are refused by default. An
operator may allow one intentional invocation by setting
`HX_EVIDENCE_ALLOW_LIVE=1` on that command:

```sh
HX_EVIDENCE_ALLOW_LIVE=1 db/hx-evidence.sh \
  "$HOME/.agents/skills/agmsg/db/messages.db" \
  record <actor> <event> <ref> <detail-json>
```

Do not export this variable for a shell session. The live opt-in still rejects
a missing database or a database without the `hx_audit` table.

Future Hooks can record generated artefact, review, scan, merge, rejection, and rollback events through this command. Secrets must pass the data guard before recording.

## SHA-256 change-visibility gate

`ci/frozen-paths.txt` currently freezes:

- `githooks/`
- `ci/`
- `db/`
- `docs/decisions/`
- `docs/specs/discipline-v1.0.md`
- `.github/workflows/`

Create or intentionally refresh the deterministic manifest:

```sh
ci/hash-freeze.py freeze
```

Verify it:

```sh
ci/hash-freeze.py verify
```

The manifest is `ci/frozen-manifest.json`. The manifest excludes itself, Python bytecode, and `__pycache__`; configured symlinks are rejected. Any added, removed, or changed frozen file fails verification until `freeze` updates the manifest.

This hash freeze does not mechanically enforce who may change a frozen file. It forces every such change to appear in review as an explicit file diff accompanied by a manifest update. Human approval under NFR-01 is the authority boundary. Moving the trust root outside the pull request checkout, through server-side protection or signing, awaits user decision D1.

## Secret data guard

Run:

```sh
ci/secret-scan.py
```

The scanner walks repository text files, excluding `.git`, symlinks, and binary data. It detects common GitHub and Anthropic token prefixes, AWS access keys, bearer values, secret-like key/value assignments, JWTs, and private-key headers.

Findings report only path, line, and secret class; the matched value is never printed. `ci/secret-allowlist.txt` accepts one exact value per line for a reviewed deterministic fixture. Pattern-wide suppression is not supported.

## CI

CI runs the behavioral test, then frozen-path verification and repository secret scanning. The behavioral test proves:

- evidence record/trace round-trip and append-only rejection;
- modified, added, and deleted frozen files fail until the manifest is refreshed;
- a harmless runtime-generated dummy secret is detected without disclosure and can be exactly allowlisted.
