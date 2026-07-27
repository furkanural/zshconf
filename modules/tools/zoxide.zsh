# ── zoxide
if (( $+commands[zoxide] )); then
  _zinit_evalcache zoxide-init 'zoxide init zsh'
fi
