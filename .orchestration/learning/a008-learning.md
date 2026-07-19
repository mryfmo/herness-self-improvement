# a008 Learning Triage

- disposition: required-handoff
- promoted: false
- learning: **A-5 は再実装で充足、SPEC 改訂時に修正要。** AIDD Platformには想定された再利用可能なevidence store / closed gate / data guardの3 packageがなく、近縁TypeScript sourceはNode/pnpm前提でSHA-256 gateも提供しない。依存ゼロrepositoryでは既存append-only tableとshell/Python標準ライブラリによる独立した最小実装が適合した。
- evidence: PR #7でevidence round-trip、21-file SHA-256 verify、secret scan clean、全CI passを確認した。AIDD sourceは読み取り参照のみでcopy/modifyなし。
- apply_to: future SPEC A-5 revision and any plan that assumes cross-repository component reuse
- correction: SPEC本文はa008の禁止範囲なので未変更。次回SPEC改訂で「typed codeとして再利用可能」という前提を削除し、P1-F1-T6の独立実装を実態として記録する。
- promotion: taskでは禁止されているため未実施
