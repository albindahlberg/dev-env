# Global agent instructions

- Use clear and concise language.
- Answer only what was asked, in the fewest sentences that answer it: a
  short paragraph or a few bullets, rarely more. Leave out edge cases,
  related mechanisms, history and future plans unless asked. I'll ask a
  follow-up if I want more.
- No explanatory comments in code, charts or config, `ponytail:` ones
  included, unless asked. Say the why in the reply, commit or PR instead.
- A question is not a request to act. Answer it directly with your opinion
  and the reason, in prose, then stop. No table or edits unless asked.
- Pass `-R owner/repo` on every `gh` command that writes (edit, comment,
  create, merge, label). Never `cd` to a variable without checking it is set;
  in this zsh, `cd ""` jumps to a zoxide match instead of failing.
