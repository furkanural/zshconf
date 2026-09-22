#!/usr/bin/env zsh
# install.sh — wire ~/.zshrc to this repo via a 3-line stub, and ~/.zprofile
# to the env overlay. Idempotent.
#
# Does exactly four things:
#   1. Backs up any existing (non-stub) ~/.zshrc, then writes the stub
#   2. Appends (or refreshes) a marked env block in ~/.zprofile — append-only,
#      never rewritten wholesale, because ~/.zprofile holds user content
#      (e.g. `brew shellenv`)
#   3. Creates the local overlay directory and a commented ~/.config/zsh/env.zsh
#   4. Prints what it did
#
# Deliberate non-goals: installing Homebrew or tools (the config degrades
# gracefully without them), installing Zinit (the config bootstraps it on
# first run), migrating an existing config (your old file is backed up —
# move what you need into the overlay directory).

emulate -L zsh
setopt err_exit nounset pipefail

repo="${0:A:h}"
zshrc="$HOME/.zshrc"
zprofile="$HOME/.zprofile"
overlay="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
marker="# Managed by the zshconf installer"
env_marker="# zshconf env (managed by install.sh)"
env_version=1

stub="$marker — personal config goes in $overlay/local.d, not here.
export ZSHCONF=\"$repo\"
[[ -r \"\$ZSHCONF/init.zsh\" ]] && source \"\$ZSHCONF/init.zsh\""

# Sourced by login shells (incl. the login shell GUI apps like Zed spawn to
# read your environment). Guarded so a login+interactive shell that already
# got it via init.zsh doesn't run it twice.
env_block="# >>> $env_marker, v$env_version >>>
if [[ -z \${ZSHCONF_ENV_SOURCED:-} && -r \"\${XDG_CONFIG_HOME:-\$HOME/.config}/zsh/env.zsh\" ]]; then
  ZSHCONF_ENV_SOURCED=1
  source \"\${XDG_CONFIG_HOME:-\$HOME/.config}/zsh/env.zsh\"
fi
# <<< $env_marker <<<"

if [[ -f "$zshrc" && "$(<$zshrc)" == *"$marker"* ]]; then
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

# ── ~/.zprofile: append the env block, refresh it if stale, else leave alone.
# Staleness is judged by the versioned start line. Substring tests, not grep:
# some environments shadow grep with ugrep, which treats a leading '#' in the
# pattern as a comment — and ours starts with one.
_zshconf_zprof=""
if [[ -f "$zprofile" ]]; then
  _zshconf_zprof="$(<$zprofile)"
fi
if [[ "$_zshconf_zprof" == *"$env_marker"* ]]; then
  if [[ "$_zshconf_zprof" == *"$env_marker, v$env_version"* ]]; then
    print -P "%F{green}==>%f ~/.zprofile env block already in place; nothing to do."
  else
    # Stale block (installer version changed): replace it in place, keep
    # everything before and after it.
    before=() after=()
    integer in_block=0 seen_end=0
    for line in "${(@f)$(<$zprofile)}"; do
      if [[ $seen_end -eq 1 ]]; then
        after+=("$line")
      elif [[ "$line" == "# >>> $env_marker, v"*">>>" ]]; then
        in_block=1
      elif [[ "$line" == "# <<< $env_marker <<<" ]]; then
        in_block=0 seen_end=1
      elif [[ $in_block -eq 0 ]]; then
        before+=("$line")
      fi
    done
    # Drop trailing blank lines from `before` so we don't accumulate gaps.
    while (( ${#before} )) && [[ -z "${before[-1]}" ]]; do before=("${before[1,-2]}"); done
    kept=("${before[@]}" "$env_block" "${after[@]}")
    print -r -- "${(F)kept}" > "$zprofile"
    print -P "%F{green}==>%f Refreshed the ~/.zprofile env block."
  fi
elif [[ -e "$zprofile" ]]; then
  print -r -- "$(<$zprofile)

$env_block" > "$zprofile"
  print -P "%F{green}==>%f Appended the env block to existing ~/.zprofile."
else
  print -r -- "$env_block" > "$zprofile"
  print -P "%F{green}==>%f Wrote ~/.zprofile with the env block."
fi
unset _zshconf_zprof

if [[ -d "$overlay/local.d" ]]; then
  print -P "%F{green}==>%f Overlay directory exists: ${overlay/#$HOME/~}/local.d"
else
  mkdir -p "$overlay/local.d"
  print -P "%F{green}==>%f Created overlay directory: ${overlay/#$HOME/~}/local.d (your personal *.zsh drop-ins go here)"
fi

if [[ -f "$overlay/env.zsh" ]]; then
  print -P "%F{green}==>%f Env file exists: ${overlay/#$HOME/~}/env.zsh"
else
  print -r -- "# Env overlay — sourced by LOGIN shells (from ~/.zprofile) and by
# non-login interactive shells (from init.zsh). This is where exports that
# GUI apps must see belong (Zed, VS Code read a login shell's environment);
# local.d only ever runs inside ~/.zshrc. Keep this file env-only — no
# aliases, prompts, or interactive code: non-interactive shells source it.
#
# Example (Keychain-backed secrets):
#   export MY_API_KEY=\"\$(security find-generic-password -a \"\$USER\" -s 'my-key' -w)\"" > "$overlay/env.zsh"
  print -P "%F{green}==>%f Created ${overlay/#$HOME/~}/env.zsh — put exports GUI apps need here (it is sourced by login shells)."
fi

print -P "\nNext: run %F{yellow}exec zsh%f (first start clones Zinit + plugins; later starts are fast)."
print -P "GUI apps (Zed, VS Code): fully quit and reopen them to pick up env.zsh."
