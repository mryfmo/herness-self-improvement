---
owner: mryfmo
last-verified: 2026-07-19
freshness: 180d
---

# ADR-0008: 再帰的自己改善の階層と限界を定める

- Status: Accepted
- Accepted: 2026-07-19 mryfmo 指示(ADR-0007/0008 の取り込み・RSI 追加・三軸統合と根本修正の指示)による。
- Context: [WORKPLAN v1.1](../plans/WORKPLAN-HARNESS-SELF-IMPROVEMENT-v1.1.md) の P1-F3-T6 は、採択目標を下回ったときに Reflector/Curator のプロンプトを改訂する。P1-F6 は optimizer の出力を統計的に再評価する。これらは改善機構を改善する二次ループだが、再帰の階層と限界は未定義である。無制限の再帰的自己改善には、optimizer の誤りを複製して増幅する危険、自己参照的な検証、承認条件を自ら緩める gate erosion がある。関連する根拠は、ローカルの REPORT に収録された Agentic Harness Engineering（arXiv:2604.25850）と self-evolving agent survey（arXiv:2508.07407）、重み更新を不採用とした [ADR-0002](ADR-0002-two-layer-memory.md)、fail-closed を定めた [ADR-0004](ADR-0004-fail-closed-pr-pipeline.md)、接地を求める [ADR-0007](ADR-0007-loop-graph-anchoring.md) である。本提案は、ADR-0007 にこの観点を加えるというユーザー指示（2026-07-19）に基づく。
- Decision:
  1. **再帰階層 L0〜L3 と変更権限を定める。**
     - `L0` は業務対象であり、通常の作業を行う。
     - `L1` はハーネス artefact（SKILLS、Wiki、Workflows、SubAgents 定義）である。自動提案を認めるが、ADR-0004 の 6 段 gate を必須とする。
     - `L2` は改善機構自体（pattern-miner のスコア規則、Reflector/Curator/Verifier のプロンプト、eval 基準、種別判定規則）である。機構の出力に接地したメタ指標、すなわち採択率、修正率、誤起票率、ロールバック率に基づく場合だけ変更できる。変更には常に mryfmo の人間承認を要する。
     - `L3` は統治機構（gate、CI 定義、Hooks、kill switch、ADR、凍結マニフェスト、本階層）である。人間だけが変更でき、[ADR-0006](ADR-0006-skill-supply-chain-governance.md) と [hash-freeze](../reference/evidence-and-gates.md) が機械的に強制する。
  2. **メタ指標を必須にする。** すべての optimizer ループに、出力へ接地したメタ指標を設ける。P1-F3-T6 の採択率 60% 以上を先行例とし、L2 の PR 本文には測定値を記載する。
  3. **自己加速を認めない。** 提案上限、diff 閾値、承認要件、timeout、昇格閾値は L3 が所有し、自動変更の対象から除外する。自動提案による緩和も認めない。
  4. **増幅を封じ込める。** L2 の変更はカナリア（canary）で導入する。次周期のメタ指標が悪化した場合は、P1-F6-T5 を使って自動ロールバックを提案する。1 つのループにつき、1 周期に変更できる L2 は最大 1 件とする。
  5. **不動点を人間の判断に置く。** 本システムを「gate 付き再帰的改善」と位置づけ、再帰は mryfmo の判断で終了する。統治、承認者、目的関数を自動変更する無制限の再帰的自己改善は、明示的に対象外とする。
- Consequences: (+) 既存の二次ループを安全な階層に置き、誤りの増幅を制限できる。NFR-01 と ADR-0006 に整合し、追加実装はメタ指標の記録とカナリアの接続に限られる。(−) optimizer 自体の改善にも人間 gate が入るため速度は落ち、メタ指標の記録コストが増える。これは意図した制約である。
- 根拠: Agentic Harness Engineering（arXiv:2604.25850）と self-evolving agent survey（arXiv:2508.07407）が扱うハーネスおよび self-evolving agent の知見に、ADR-0002、ADR-0004、ADR-0007 の既存判断を合わせた。P1-F3-T6 の採択率基準を、メタ指標による統治の先行例とする。
