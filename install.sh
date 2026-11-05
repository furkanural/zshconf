#!/usr/bin/env zsh
# install.sh — wire ~/.zshrc to this repo via a 3-line stub, ~/.zprofile to
# the env overlay, and login bash to the same PATH. Idempotent.
#
# Does exactly five things:
#   1. Backs up any existing (non-stub) ~/.zshrc, then writes the stub
#   2. Appends (or refreshes) a marked env block in ~/.zprofile — append-only,
#      never rewritten wholesale, because ~/.zprofile holds user content
#      (e.g. `brew shellenv`)
#   3. Appends (or refreshes) a marked one-line stub in the login-bash profile
#      that sources $repo/bash-login.sh, so `bash -lc …` (how agent tools and
#      editors run hooks) sees Homebrew and mise instead of macOS's
#      path_helper order. Logic lives in the repo; the stub never changes.
#   4. Creates the local overlay directory and a commented ~/.config/zsh/env.zsh
#   5. Prints what it did
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
bash_marker="# zshconf bash-login (managed by install.sh)"
bash_version=2   # v1 inlined the logic; v2 is a stub sourcing bash-login.sh

# Login bash reads exactly one of these, first match wins. Target that one so
# the block is actually read; create ~/.bash_profile when none exists.
bash_profile="$HOME/.bash_profile"
for _f in "$HOME/.bash_profile" "$HOME/.bash_login" "$HOME/.profile"; do
  [[ -f "$_f" ]] && { bash_profile="$_f"; break }
done
unset _f

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

# Sourced by LOGIN bash — `bash -lc …` is how editors, agent tools (Orca,
# Claude Code, Codex) and the git hooks they run get a shell. The stub mirrors
# the ~/.zshrc one: a single line pointing at the repo, so the logic (in
# bash-login.sh — see its header for the path_helper story) updates with
# the repo and the user never re-runs the installer for it. POSIX sh: the
# stub may land in ~/.profile, which `sh -l` reads too.
bash_block="# >>> $bash_marker, v$bash_version >>>
[ -r \"$repo/bash-login.sh\" ] && . \"$repo/bash-login.sh\"
# <<< $bash_marker <<<"

# install_block <file> <marker> <block> <label>
# Append the marked block, refresh it if stale, else leave alone. Append-only:
# the file holds user content. Stale means the block on disk is not this
# one byte-for-byte: the version in its start line was bumped, or a path
# baked into it is wrong because the repo moved. Substring tests, not grep:
# some environments shadow grep with ugrep, which treats a leading '#' in
# the pattern as a comment — and ours starts with one.
install_block() {
  local file="$1" mk="$2" block="$3" label="$4"
  local content="" pretty="${file/#$HOME/~}"
  local -a before after kept
  local line
  integer in_block=0 seen_end=0
  [[ -f "$file" ]] && content="$(<$file)"
  if [[ "$content" == *"$mk"* ]]; then
    if [[ "$content" == *"$block"* ]]; then
      print -P "%F{green}==>%f $pretty $label block already in place; nothing to do."
    else
      # Stale block (version bumped, or repo moved): replace it in place,
      # keep everything before and after it.
      for line in "${(@f)content}"; do
        if [[ $seen_end -eq 1 ]]; then
          after+=("$line")
        elif [[ "$line" == "# >>> $mk, v"*">>>" ]]; then
          in_block=1
        elif [[ "$line" == "# <<< $mk <<<" ]]; then
          in_block=0 seen_end=1
        elif [[ $in_block -eq 0 ]]; then
          before+=("$line")
        fi
      done
      # Drop trailing blank lines from `before` so we don't accumulate gaps.
      while (( ${#before} )) && [[ -z "${before[-1]}" ]]; do before=("${before[1,-2]}"); done
      kept=("${before[@]}" "$block" "${after[@]}")
      print -r -- "${(F)kept}" > "$file"
      print -P "%F{green}==>%f Refreshed the $pretty $label block."
    fi
  elif [[ -e "$file" ]]; then
    print -r -- "$content

$block" > "$file"
    print -P "%F{green}==>%f Appended the $label block to existing $pretty."
  else
    print -r -- "$block" > "$file"
    print -P "%F{green}==>%f Wrote $pretty with the $label block."
  fi
}

install_block "$zprofile"     "$env_marker"  "$env_block"  "env"
install_block "$bash_profile" "$bash_marker" "$bash_block" "bash-login"

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
