---
owner: harness-operators
last-verified: 2026-07-21
freshness: 90d
---

# 自作 skill 移行台帳

dotfiles にある8件を、標準 frontmatter を付けた統治済みの写しとして
`.claude/skills/` へ移した。F7 で marketplace 化するまでは、dotfiles が個人層の
正本、このリポジトリが検査済みの写しである。

SHA-256 は、移行元と移行先の `SKILL.md` から先頭 frontmatter を外し、改行を
LF に正規化した本文に対する値。8件すべて一致している。

| skill | dotfiles 内の移行元 | 本文 SHA-256 | scope | eval |
| --- | --- | --- | --- | --- |
| `agmsg` | `home/dot_agents/skills/agmsg/` | `19acaa43e33d81b67bc59ec081b69543c38dbf392e93daf7a9bdbd0301d97b48` | `org` | debt: P1-F4-T5 |
| `agmsg-orchestration` | `home/dot_agents/skills/agmsg-orchestration/` | `fb62cae385a8e620199da3a16ba21d40d08101923cd0e6df989f08aea3099342` | `org` | debt: P1-F4-T5 |
| `convert-to-transformers` | `home/dot_agents/skills/convert-to-transformers/` | `2613f2d3c2df7d654fcedb37b9f51df58a7e8a672f4bed8dde67a382c3f4b681` | `personal` | debt: P1-F4-T5 |
| `gh-comment-attach-files` | `home/dot_agents/skills/gh-comment-attach-files/` | `736f32c6c198fb4926cea73548ad6cce30684a1342460716f7064f6f94a0e833` | `personal` | debt: P1-F4-T5 |
| `gh-first-workflow` | `home/dot_agents/skills/gh-first-workflow/` | `b97d93d3e1d3e0ef0beb140a4277dfc515bcf252d82a1bad2bab470a69779e8f` | `personal` | debt: P1-F4-T5 |
| `humanizer-ja` | `home/dot_agents/skills/humanizer-ja/` | `cb92544ed847b80c5105c3844aced42baf8cf0118e222688a65180be74fa0fe3` | `personal` | debt: P1-F4-T5 |
| `python-uv-workflow` | `home/dot_agents/skills/python-uv-workflow/` | `f4296bac846d2e4ee2cdcb538790d7c4de6c1d77c91d5afcff0e60f44124e678` | `personal` | debt: P1-F4-T5 |
| `shdoc-shell-docs` | `home/dot_agents/skills/shdoc-shell-docs/` | `e297d66597b9195927a56f6837c20f3c1dabebed64e85c4182b2f83cf4999214` | `personal` | debt: P1-F4-T5 |

7件の provenance は `repo=mryfmo/dotfiles; license=MIT`。`convert-to-transformers`
も dotfiles 自体は MIT だが、原著者は未確認のため D4 扱いとし、再配布を禁じる。
frontmatter の `original-authorship`、`decision`、`redistribution` に残した。

各 `eval/NOTES.md` には最低1件の検証観点がある。実行可能 eval は P1-F4-T5 で
追加し、それまでは eval-debt として扱う。
