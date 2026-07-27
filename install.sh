#!/usr/bin/env zsh
# install.sh — wire ~/.zshrc to this repo via a 3-line stub. Idempotent.
#
# Does exactly three things:
#   1. Backs up any existing (non-stub) ~/.zshrc, then writes the stub
#   2. Creates the local overlay directory (${XDG_CONFIG_HOME:-~/.config}/zsh/local.d)
#   3. Prints what it did
#
# Deliberate non-goals: installing Homebrew or tools (the config degrades
# gracefully without them), installing Zinit (the config bootstraps it on
# first run), migrating an existing config (your old file is backed up —
# move what you need into the overlay directory).

emulate -L zsh
setopt err_exit nounset pipefail

repo="${0:A:h}"
zshrc="$HOME/.zshrc"
overlay="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/local.d"
marker="# Managed by the zsh-config installer"

stub="$marker — personal config goes in $overlay, not here.
export ZSHCONF=\"$repo\"
[[ -r \"\$ZSHCONF/init.zsh\" ]] && source \"\$ZSHCONF/init.zsh\""

if [[ -f "$zshrc" ]] && grep -qF "$marker" "$zshrc"; then
  if [[ "$(<$zshrc)" == "$stub" ]]; then
    print -P "%F{green}==>%f ~/.zshrc stub already in place; nothing to do."
  else
    # Our stub, but stale (repo moved, or stub format changed): rewrite.
    print -r -- "$stub" > "$zshrc"
    print -P "%F{green}==>%f Refreshed the ~/.zshrc stub (now points at $repo)."
  fi
elif [[ -e "$zshrc" ]]; then
  backup="$HOME/.zshrc.pre-zshconf"
  [[ -e "$backup" ]] && backup="$backup.$(date +%Y%m%d-%H%M%S)"
  mv "$zshrc" "$backup"
  # Stale bytecode of the replaced file would only confuse; drop it.
  [[ -f "$zshrc.zwc" ]] && rm -f "$zshrc.zwc"
  print -r -- "$stub" > "$zshrc"
  print -P "%F{green}==>%f Backed up existing ~/.zshrc to ${backup/#$HOME/~}"
  print -P "%F{green}==>%f Wrote the ~/.zshrc stub (sources $repo/init.zsh)."
else
  print -r -- "$stub" > "$zshrc"
  print -P "%F{green}==>%f Wrote the ~/.zshrc stub (sources $repo/init.zsh)."
fi

if [[ -d "$overlay" ]]; then
  print -P "%F{green}==>%f Overlay directory exists: ${overlay/#$HOME/~}"
else
  mkdir -p "$overlay"
  print -P "%F{green}==>%f Created overlay directory: ${overlay/#$HOME/~} (your personal *.zsh drop-ins go here)"
fi

print -P "\nNext: run %F{yellow}exec zsh%f (first start clones Zinit + plugins; later starts are fast)."
