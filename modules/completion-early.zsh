zmodload zsh/complist

# Rebind clap's dynamic completers (_clap_dynamic_completer_*) to the
# static _cmd files on fpath.
_repair_clap_dynamic_completions() {
  emulate -L zsh
  setopt extendedglob

  (( ${+_comps} && ${+functions[compdef]} )) || return 0

  local cmd fn stub dir
  for cmd fn in ${(kv)_comps}; do
    [[ "$fn" == _clap_dynamic_completer_* ]] || continue
    stub="_${cmd:t}"
    for dir in $fpath; do
      if [[ -r "$dir/$stub" ]]; then
        autoload -Uz "$stub"
        compdef "$stub" "$cmd"
        break
      fi
    done
  done
}

# Drop a poisoned or stale compdump before Tier 1's compinit -C trusts it.
() {
  emulate -L zsh
  setopt extendedglob

  local zdot="${ZDOTDIR:-$HOME}"
  local zcompdump="$zdot/.zcompdump"

  if [[ -r "$zcompdump" && "$(<$zcompdump)" == *_clap_dynamic_completer_* ]]; then
    rm -f "$zdot"/.zcompdump*(N)
    return 0
  fi

  local watched=(
    "$ZSHCONF"/init.zsh
    "$ZSHCONF"/modules/**/*.zsh(N)
    "$ZSHCONF"/completions/*(N)
    "$zdot/.zsh/completions"
    "$HOME/.local/share/zinit/completions"
    "$HOME/.cache/zinit/completions"
    /opt/homebrew/share/zsh/site-functions(N)
    /usr/local/share/zsh/site-functions(N)
    /home/[l]inuxbrew/.linuxbrew/share/zsh/site-functions(N)
  )

  local entry
  for entry in $watched; do
    if [[ -e "$entry" && ( ! -f "$zcompdump" || "$entry" -nt "$zcompdump" ) ]]; then
      rm -f "$zdot"/.zcompdump*(N)
      break
    fi
  done
}
