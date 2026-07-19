# a007 P1-F1-T5 SQLite Load Test Report

## Status

ready_for_review

## Result

- Pull request: https://github.com/mryfmo/herness-self-improvement/pull/6
- Squash merge: `7fff6ec64060df7499c25248c4c201dba43f7cb7`
- Branch: `f1-t5/sqlite-load-test`（merge 後に削除）
- NFR-03: PASS（hx / mixed とも）

## Implementation choice

既存 migration、POSIX shell、Python標準ライブラリ `sqlite3` だけを再利用した。shell entrypointは引数・新規DB・`.agents`外という安全境界を検証し、埋込みPythonが8 forked writers、writer別一時TSV、busy retry、件数照合、nearest-rank percentile、NFR判定を担当する。追加dependencyやbenchmark frameworkはない。

writerは10ms間隔を目標にし、各成功writeのlatencyとbusy retryを記録する。mixedは8 writers中1 writerが模擬agmsg messages、7 writersがhx eventsを同じDBへ書く。

## 600-second results

| Profile | Expected | Actual | Missing | p50 ms | p95 ms | p99 ms | Busy retries | Permanent failures | Writes/sec | Result |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| hx | 479,999 | 479,999 | 0 | 1.414 | 10.856 | 37.350 | 0 | 0 | 800.00 | PASS |
| mixed | 480,000 | 480,000 | 0 | 1.521 | 10.909 | 37.444 | 0 | 0 | 800.00 | PASS |

mixed の p95 差は +0.053ms（+0.49%）。両DBの `integrity_check` は `ok`。

## Completed procedure

1. 先行 smokeを作り、`db/load-test.sh` 不在で失敗することを確認した。
2. `hx|mixed` profiles、writer別latency、busy retry、件数独立照合、p50/p95/p99、NFR判定を実装した。
3. 既存DBとホーム `.agents` 配下を拒否し、実運用agmsg DBへの誤接続をguardした。
4. CIに8 writers ×20秒 mixed smokeと2秒 hx sanityを追加した。
5. hx 8 writers ×600秒をrepository外scratch DBで実測した。
6. mixed 8 writers ×600秒を別のrepository外scratch DBで実測した。
7. 6秒write lockを注入し、8 busy retries後に8,000/8,000件、恒久失敗0で回復することを確認した。
8. environment、PRAGMA、結果、NFR判定、残存決裁への推奨をreferenceへ記録した。
9. `1718be0 feat(db): add SQLite load test harness`（`Agent: worker`）をPR #6でsquash mergeした。

## Judgment

測定した単一host・8 writers・約800 writes/secの範囲では同居を推奨する。mixedはthroughput低下・retry・欠損がなく、p95増加も0.49%だった。writer数、write rate、payload、filesystem、reader/checkpoint圧が測定範囲を超える場合は分離判断前に再測する。

設定調整は不要だった。実運用agmsg DB、禁止された4文書、protection/hooks、dependencies、他repositoryは変更していない。
