# a030 Learning Triage

- reusable learning: tracked vendor import は filesystem copy 後に source と destination の
  bytes、symlink target、mode を比較する。nested `.gitignore` が upstream tracked file を
  隠すため、staging 後にも path set / Git tree を再照合する。
- reusable learning: secret scanner を vendor 単位で除外せず、match context を全件実見し、
  検証できた完全一致値だけを理由コメント付きで許可する。証跡には生値でなく hash prefix
  を置く。
- reusable learning: GitHub repository redirect は requested URL と canonical URL の双方を
  provenance に残す。license metadata null は暗黙の許諾と解釈しない。
- reusable learning: 無改変 vendor の `AGENTS.md` / `CLAUDE.md` は path-scoped instruction
  discovery の対象になり得る。vendor を workdir にせず、実利用前の再パッケージで除外する。
- plan update: 次回 vendor import の design / tests に source tree hash、staged tree hash、
  exact allowlist consistency、agent instruction inventory を含める。
- promotion: task Allowed files に `.agents/worklog/codex/learn` がないため今回は昇格せず、
  a030 artifact と registry の運用境界へ反映した。
