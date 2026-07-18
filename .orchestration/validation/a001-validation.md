# a001 Validation

## 1. タスク ID 完全性

```sh
grep -o 'P1-F[0-9]*-T[0-9]*' /tmp/WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.0.before-a001.md | sort -u > /tmp/ids-v10.txt
grep -o 'P1-F[0-9]*-T[0-9]*' WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.1.md | sort -u > /tmp/ids-v11.txt
diff /tmp/ids-v10.txt /tmp/ids-v11.txt
```

出力（`diff` の exit 1 は差分 1 件があるためで、期待値）:

```text
0a1
> P1-F1-T0
```

補助確認:

```text
v1.0 declarations=78
v1.1 declarations=79
phase headings/tests/done/open=9/9/9/9/
```

判定: PASS。欠落・重複なし、追加は P1-F1-T0 のみ。

## 2. 残存 TBD(HUMAN)

```sh
grep -n 'TBD(HUMAN)' WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.1.md
```

```text
127:**F1 Open Questions**: agmsg DB の同居 or 分離 DB（負荷試験結果で判断、TBD(HUMAN)）/ marketplace リポジトリの分離時期。
173:**F2 Open Questions**: 訂正検知ヒューリスティックの精度目標値 / 保持期間・匿名化ポリシー TBD(HUMAN)。
224:**F3 Open Questions**: 採択率目標の恒久値（TBD(HUMAN)）/ lessons の粒度規約の追加要否。
280:**F4 Open Questions**: 採択率の恒久目標（TBD(HUMAN)）/ サロゲートタスクの自動抽出精度向上策。
377:**F6 Open Questions**: 失敗率閾値・未使用日数の恒久値 TBD(HUMAN)。
394:- 作業: skill_runs 統計から昇格閾値（利用回数 ≥ N、成功率 ≥ M%。初期値 N=10, M=80 で開始、恒久値 TBD(HUMAN)）超過スキルを検出。
414:- 作業: 本基盤を実プロジェクト 2 件（選定 TBD(HUMAN)。mryfmo の既存プロジェクトから F7 着手前に選定）へ導入し、スコープ運用を通し試験。
423:**F7 Open Questions**: 昇格閾値の恒久値 / パイロット選定 TBD(HUMAN)。
479:**F8 Open Questions**: レッドチーム試験の定期実施周期 TBD(HUMAN)。
542:| 4 | agmsg DB 同居 or 分離（負荷試験結果次第） | F1 OQ | F1 末 | TBD(HUMAN) |
543:| 5 | テレメトリ保持期間・匿名化ポリシー・監査サンプル数 | F2 | F2 末 | TBD(HUMAN) |
544:| 7 | 生成 PR 採択率・還流採択率の恒久目標 | F3/F4 OQ | F9-T4 | TBD(HUMAN) |
545:| 8 | 失敗率閾値・未使用日数・昇格閾値（N, M%）などの恒久値 | F6/F7 OQ | F9-T4 | TBD(HUMAN) |
546:| 10 | レッドチーム定期周期 | F8 OQ | F9-T4 | TBD(HUMAN) |
547:| 11 | タスクタイムアウト等プロトコル既定値の本値 | SPEC 5.3 | F9-T4 | TBD(HUMAN) |
548:| パイロット選定 | パイロット 2 プロジェクト | F7-T7 | F7 着手前 | TBD(HUMAN) |
```

判定: PASS。残存項目は #4/#5/#7/#8/#10/#11 とパイロット選定に対応する。本文中の出現は各残存項目の初出・Open Questions と一覧表の再掲。

## 3. v1.0 の限定変更

変更前に以下でバックアップを作成した。

```sh
cp WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.0.md /tmp/WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.0.before-a001.md
diff -u /tmp/WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.0.before-a001.md WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.0.md
```

```diff
--- /tmp/WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.0.before-a001.md
+++ WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.0.md
@@ -3,6 +3,7 @@
 
 ## Status
 
+- Superseded by WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.1.md
 - 状態: Draft（人間レビュー待ち）
 - 作成日: 2026-07-18
 - 実行体制: Claude Code（orchestrator, Fable-5 effort=high）+ Codex（worker, gpt-5.6-sol effort=high）+ agmsg
```

判定: PASS。Status への 1 行追加のみ。

## 4. 参照・構造の補助検証

WORKPLAN の FR/NFR 参照を SPEC の定義から差し引き、未定義参照がないことを確認した。

```text
absent FR=
absent NFR=
unpaired new ADR refs=
```

新 ADR 参照は ADR-0001〜0006 と旧呼称 H001〜H006 の併記、または採番規則の説明として記載されている。

判定: PASS。

