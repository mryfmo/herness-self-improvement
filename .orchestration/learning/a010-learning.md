# a010 Learning Triage

- disposition: candidate-only
- promoted: false
- learning: 文書分割の忠実性は目視でなく、追加metadataを除去し許可されたStatus/番号変更だけを逆変換したうえで、元節とのline diffと同一SHA-256を証跡にする。原文bundle自体は許可lineを除くbyte比較も行うと、転記とsource保存を独立に検証できる。
- evidence: normalized 6 sectionsとbundle sectionsの`diff -u`はoutputなし・exit 0、双方SHA-256は`28ccbb3afaa06b4adef289df6dfa6d04c383f14af5982b3039a4915fab62b0f3`、bundle_status_line_only=PASS。
- apply_to: document splits, migrations, and format-only transformations that must preserve source wording
- ceiling: 意味的なrewriteやfield再構成を許可するmigrationではline equalityを使わず、明示mappingとfield-level oracleを別途定義する。
- promotion: taskでは許可されていないため未実施
