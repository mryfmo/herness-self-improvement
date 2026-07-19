# a016 Acceptance

- reviewer: claude-fable5high-herness (orchestrator)
- date: 2026-07-19
- verdict: accepted (round 1)

## Orchestrator 独立検証(自ら実行)

1. A014-17 修正: scratch DB で 0002 台帳エントリを除去 → `migrate.sh status` が「0002_ledger pending」を報告し exit 1(自ら再現)。テストスイートに同ケースを確認。旧来の全スイートも self-run で PASS。PASS
2. A014-04 修正: frozen-paths に docs/decisions/ + discipline-v1.0.md が追加され 35 files verified。ADR-0007 改竄プローブ(自ら実行)→ mismatch 検知 → 復元確認。PASS
3. A014-03 文書修正: 「SHA-256 change-visibility gate」への改題、「変更権限の機械的強制ではなく変更の強制可視化 + NFR-01 の人間承認が権限の実体、trust root の外部化は決裁 D1 待ち」の明記を diff で確認。PASS
4. PR #14 MERGED、diff は許可 6 ファイルのみ、main CI success。PASS

## 結論

accepted。次: a017(SPEC v1.1)。
