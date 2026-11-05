#!/usr/bin/env zsh
# Wires the dotfiles to this repo. Idempotent; never deletes user content.
#   ~/.zshrc                       3-line stub (existing file backed up)
#   ~/.zprofile                    marked block: login-path.sh, then env.zsh
#   ~/.bash_profile | ~/.profile   marked 1-line stub: login-path.sh
#   ~/.config/zsh/                 overlay dir + commented env.zsh
# Does not install tools or Zinit, or migrate an old config.

emulate -L zsh
setopt err_exit nounset pipefail

repo="${0:A:h}"
zshrc="$HOME/.zshrc"
zprofile="$HOME/.zprofile"
overlay="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
marker="# Managed by the zshconf installer"
env_marker="# zshconf env (managed by install.sh)"
env_version=2
bash_marker="# zshconf bash-login (managed by install.sh)"
bash_version=3

# Login bash reads the first of these that exists.
bash_profile="$HOME/.bash_profile"
for _f in "$HOME/.bash_profile" "$HOME/.bash_login" "$HOME/.profile"; do
  [[ -f "$_f" ]] && { bash_profile="$_f"; break }
done
unset _f
# `sh -l` reads only ~/.profile; cover it when it exists separately.
sh_profile=""
[[ "$bash_profile" != "$HOME/.profile" && -f "$HOME/.profile" ]] && sh_profile="$HOME/.profile"

stub="$marker — personal config goes in $overlay/local.d, not here.
export ZSHCONF=\"$repo\"
[[ -r \"\$ZSHCONF/init.zsh\" ]] && source \"\$ZSHCONF/init.zsh\""

# login-path.sh first so env.zsh can call tools from brew/mise.
env_block="# >>> $env_marker, v$env_version >>>
[ -r \"$repo/login-path.sh\" ] && . \"$repo/login-path.sh\"
if [[ -z \${ZSHCONF_ENV_SOURCED:-} && -r \"\${XDG_CONFIG_HOME:-\$HOME/.config}/zsh/env.zsh\" ]]; then
  ZSHCONF_ENV_SOURCED=1
  source \"\${XDG_CONFIG_HOME:-\$HOME/.config}/zsh/env.zsh\"
fi
# <<< $env_marker <<<"

if [[ -f "$zshrc" && "$(<$zshrc)" == *"$marker"* ]]; then
  if [[ "$(<$zshrc)" == "$stub" ]]; then
    print -P "%F{green}==>%f ~/.zshrc stub already in place; nothing to do."
  else
    print -r -- "$stub" > "$zshrc"
    print -P "%F{green}==>%f Refreshed the ~/.zshrc stub (now points at $repo)."
  fi
elif [[ -e "$zshrc" ]]; then
  backup="$HOME/.zshrc.pre-zshconf"
  [[ -e "$backup" ]] && backup="$backup.$(date +%Y%m%d-%H%M%S)"
  mv "$zshrc" "$backup"
  [[ -f "$zshrc.zwc" ]] && rm -f "$zshrc.zwc"
  print -r -- "$stub" > "$zshrc"
  print -P "%F{green}==>%f Backed up existing ~/.zshrc to ${backup/#$HOME/~}"
  print -P "%F{green}==>%f Wrote the ~/.zshrc stub (sources $repo/init.zsh)."
else
  print -r -- "$stub" > "$zshrc"
  print -P "%F{green}==>%f Wrote the ~/.zshrc stub (sources $repo/init.zsh)."
fi

bash_block="# >>> $bash_marker, v$bash_version >>>
[ -r \"$repo/login-path.sh\" ] && . \"$repo/login-path.sh\"
# <<< $bash_marker <<<"

# install_block <file> <marker> <block> <label>: append the block, replace
# it in place when it differs (version bump or moved repo), else no-op.
# Substring tests, not grep: ugrep treats a leading '#' pattern as a comment.
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
[[ -n "$sh_profile" ]] && install_block "$sh_profile" "$bash_marker" "$bash_block" "bash-login"

if [[ -d "$overlay/local.d" ]]; then
  print -P "%F{green}==>%f Overlay directory exists: ${overlay/#$HOME/~}/local.d"
else
  mkdir -p "$overlay/local.d"
  print -P "%F{green}==>%f Created overlay directory: ${overlay/#$HOME/~}/local.d (your personal *.zsh drop-ins go here)"
fi

if [[ -f "$overlay/env.zsh" ]]; then
  print -P "%F{green}==>%f Env file exists: ${overlay/#$HOME/~}/env.zsh"
else
  print -r -- "# Exports GUI apps must see (sourced by login zsh and by ~/.zshrc).
# Env only: no aliases, prompts or interactive code.
# Example:
#   export MY_API_KEY=\"\$(security find-generic-password -a \"\$USER\" -s 'my-key' -w)\"" > "$overlay/env.zsh"
  print -P "%F{green}==>%f Created ${overlay/#$HOME/~}/env.zsh — put exports GUI apps need here (it is sourced by login shells)."
fi

print -P "\nNext: run %F{yellow}exec zsh%f (first start clones Zinit + plugins; later starts are fast)."
print -P "GUI apps (Zed, VS Code): fully quit and reopen them to pick up env.zsh."
