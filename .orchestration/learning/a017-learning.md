# a017 Learning Triage

- disposition: reusable-versioned-document-rule
- promoted: false
- preservation rule: 基準文書の版上げでは、章見出し列、既存要件の定義番号、旧版の限定差分を別々に機械検査すると、構造保持と意味改訂を両立しやすい。
- pending decisions: 未決の統治判断は、代償統制と恒久形態を分け、決裁 ID と切替時点を本文に残す。文書改訂だけで解決済みにしない。
- protocol mapping: 新旧プロトコルの移行は、メッセージ名だけでなく台帳操作と終端条件まで対応表にすると二重定義を発見しやすい。
- frozen boundary: 個別ファイル凍結では、同じディレクトリの別ファイルまで凍結対象とは限らない。configured path の完全一致と hash verify を両方確認する。
- apply_to: a018 WORKPLAN v1.2、将来の SPEC / WORKPLAN / REPORT 版上げ
- evidence: SPEC v1.1、v1.0 限定 diff、PR #15
- promotion: task は rule promotion を許可していないため未実施
