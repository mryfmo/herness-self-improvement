# a009 Learning Triage

- disposition: candidate-only
- promoted: false
- learning: dependency禁止のMarkdown repositoryではYAML/Markdown parser全体を再実装せず、先頭top-level required scalarとrelative link targetの存在だけを標準ライブラリで検査すれば、frontmatter規約とbroken-link gateを小さくfail-closedにできる。legacy exemptionはfrontmatterだけに限定し、link検査を継続すると移行中の盲点を増やさない。
- evidence: 5 behavioral perspectives pass、現行10 docs pass、24 frozen files pass、一時branch CIがmissing frontmatterとbroken linkの両方でfailure。
- apply_to: dependency-free documentation repositories with staged frontmatter migration
- ceiling: full YAML semantics、nested-parenthesis link destinations、heading-anchor existenceが必要になった時だけ専用parser導入を検討する。
- promotion: taskでは許可されていないため未実施
