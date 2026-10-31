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

# ── Aliases: git  (gst/gco/gp/glog come from OMZP::git)
# noglob: with EXTENDED_GLOB, `git log HEAD^` / `git show @~2` die with "no
# matches found" before git runs. git expands pathspecs itself — note that
# makes `git add *.js` recursive (git's pathspec semantics), which is
# usually what you want. Alias expansion is recursive, so OMZ's gst/gco/…
# get it too. Bypass with `command git` or `\git`.
alias git='noglob git'
alias gadog='git log --all --decorate --oneline --graph'  # glog + all branches
