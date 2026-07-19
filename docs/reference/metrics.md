---
owner: mryfmo
last-verified: 2026-07-19
freshness: 90d
---

# Harness metrics

指標は単独で判断材料にしない。次の表では、同じ行の対抗指標を必ず一緒に
確認する。成功率だけを追って訂正が増える、失敗率だけを下げて実行自体が
減る、といった最適化を避けるための組み合わせである。

<!-- metric-schema:start -->
| 指標名 | 定義（SQL 相当） | 対抗指標 | 分類 | owner | 改訂周期 |
| --- | --- | --- | --- | --- | --- |
| スキル別成功率 | `SUM(outcome = 'success') / COUNT(*)` を日付・`skill_name` 別に算出 | スキル別訂正率 | 接地 | mryfmo | 四半期 |
| スキル別訂正率 | `SUM(corrected = 1) / COUNT(*)` を日付・`skill_name` 別に算出 | スキル別成功率 | 接地 | mryfmo | 四半期 |
| スキル別平均所要時間 | 同じ `session_id`・`ts` の `Skill` tool event を対応づけ、非 NULL の `duration_ms` を平均 | スキル別成功率 | 派生 | mryfmo | 四半期 |
| スキル別成功率 | `SUM(outcome = 'success') / COUNT(*)` を日付・`skill_name` 別に算出 | スキル別平均所要時間 | 接地 | mryfmo | 四半期 |
| ツール別失敗率 | `SUM(status = 'failure') / COUNT(*)` を日付・`tool` 別に算出 | 実行件数 | 派生 | mryfmo | 四半期 |
| 実行件数 | `COUNT(hx_tool_events.id)` を日付・`tool` 別に算出 | ツール別失敗率 | 接地 | mryfmo | 四半期 |
| 繰り返しプロンプト頻度 | 同日・同一 `content` の2件目以降を `SUM(COUNT(*) - 1)` で集計 | セッション多様性 | 派生 | mryfmo | 四半期 |
| セッション多様性 | 繰り返しプロンプト群に含まれる `COUNT(DISTINCT session_id)` | 繰り返しプロンプト頻度 | 接地 | mryfmo | 四半期 |
<!-- metric-schema:end -->

成功率は実行結果、訂正率は人間の訂正、実行件数とセッション数は実データ
件数を根拠にするため「接地」とした。平均、失敗率、繰り返しパターンは
集計から作るため「派生」である。派生指標を判断に使うときは、表の接地指標
が同じ期間・粒度で悪化していないかを先に見る。

## SQL views

migration `0003_metric_views` はテーブルを変えず、次の3 view だけを作る。

- `hx_v_skill_daily`: 成功率、訂正率、平均所要時間
- `hx_v_tool_daily`: 失敗率、失敗件数、実行件数
- `hx_v_prompt_repetition_daily`: 繰り返し件数、distinct session 数

Skill hook は `hx_tool_events` と `hx_skill_runs` を同じ transaction で記録
する。所要時間は `session_id` と `ts` が一致する行を対応づける。
`duration_ms` がない実行は平均から除外する。

## Daily operation

初回は migration を適用する。

```sh
db/migrate.sh up "$HOME/.agents/skills/agmsg/db/messages.db"
```

当日（UTC）を集計する場合:

```sh
ci/hx-metrics.sh "$HOME/.agents/skills/agmsg/db/messages.db"
```

日付を指定する場合:

```sh
ci/hx-metrics.sh "$HOME/.agents/skills/agmsg/db/messages.db" \
  --date 2026-07-18
```

標準出力には skill、tool、prompt の3区分が出る。実行後は
`hx_audit` に `event=metrics.daily`、`ref=<日付>` の summary を1件追記する。
夜間 schedule はここでは登録しない。F3 のジョブ基盤からこの CLI を
1日1回呼び出す。
