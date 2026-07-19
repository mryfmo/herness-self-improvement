# a014 Learning Triage

- disposition: reusable-audit-contract
- promoted: false
- learning: hash manifest が verifier・対象設定・保護対象と同じ変更権限内にある場合、hash-freeze は改変の可視化にはなるが、人間専有の trust root にはならない。
- learning: 自己改善 loop の監査は「何を改善するか」だけでなく、駆動指標の接地、loop 間調停、再帰階層ごとの変更権限を同時に検査する必要がある。
- learning: Accepted/Proposed ADR を追加しただけでは実行規律にならない。SPEC requirement、WORKPLAN task/verification、CI/path guard、monthly audit の各 contract へ反映して初めて閉じる。
- learning: 読取り禁止 file がある独立監査では repository-wide scanner も禁止対象を読む。検査は明示 allowlist path に限定し、scanner の traversal scope を事前確認する。
- apply_to: SPEC assumptions/NFR, WORKPLAN F2-T5/F3-T6/F4-T9/F5-T6/F6-T8/F8-T2/F8-T7, hash-freeze trust root
- evidence: a014 report A014-01〜10, a014 validation Independence
- promotion: a014 は監査だけのため、rule/skill への promotion と repository 修正は未実施
