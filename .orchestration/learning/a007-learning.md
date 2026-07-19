# a007 Learning Triage

- disposition: candidate-only
- promoted: false
- learning: 並行write testでは「予定回数」ではなく、各writerがacknowledgeした件数を独立したDB row countと照合し、schedule shortfall、write loss、permanent BUSYを別指標にする。writer別raw latencyとmonotonic共通deadlineを使うと、percentileと欠損を依存なしで再現可能に集計できる。
- evidence: hx 479,999/479,999、mixed 480,000/480,000、6秒lock recovery 8,000/8,000、2本のintegrity_check `ok`。
- apply_to: SQLite concurrency tests and acknowledged-write integrity checks
- ceiling: 8 writers・約800 writes/sec・単一hostを超えるdeployment envelopeでは再測定が必要。
- promotion: taskでは禁止されているため未実施
