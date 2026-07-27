# ── Aliases: general
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias q='exit'
alias reload='exec zsh'

# path/fpath are special ZSH array names → use functions.
showpath()  { print -l $path }
showfpath() { print -l $fpath }

# ── Aliases: file listing  (ls/ll/la/… come from OMZP::eza; fallbacks only if eza absent)
if ! (( $+commands[eza] )); then
  alias ll='ls -lAh'
  alias la='ls -A'
  alias l='ls -CF'
fi
