# a004 Learning Triage

- disposition: candidate-only
- promoted: false
- learning: 生成器を「source text から target text を返す純粋な render」と「filesystem write」に分けると、source hash・対象別 section・冪等性・手編集検出を標準ライブラリだけで小さく検証できる。
- evidence: 5 unit tests、staged manual-edit の exit 1、PR #3 の push/PR CI green。
- apply_to: deterministic generated-file checks
- ceiling: marker 種別や出力先が増えて設定化が必要になるまでは3 marker の固定辞書を維持する。
- promotion: task では禁止されているため未実施
