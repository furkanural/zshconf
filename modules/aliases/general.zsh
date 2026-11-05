alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias q='exit'
alias reload='exec zsh'

showpath()  { print -l $path }
showfpath() { print -l $fpath }

# ls/ll/la come from OMZP::eza when eza is present.
if ! (( $+commands[eza] )); then
  alias ll='ls -lAh'
  alias la='ls -A'
  alias l='ls -CF'
fi

# noglob: EXTENDED_GLOB would otherwise eat `git log HEAD^`. OMZ's gst/gco/…
# inherit it; bypass with `command git`.
alias git='noglob git'
alias gadog='git log --all --decorate --oneline --graph'
