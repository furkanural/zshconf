# ── Completion module  (menu-select widget; must load before compinit)
zmodload zsh/complist

# Repair clap dynamic completers (_clap_dynamic_completer_*) back to stable _cmd stubs.
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

# Drop stale/poisoned completion dumps before zicompinit (compinit -C skips rescan).
() {
  emulate -L zsh
  setopt extendedglob

  local zdot="${ZDOTDIR:-$HOME}"
  local zcompdump="$zdot/.zcompdump"

  if [[ -r "$zcompdump" ]] && command grep -q "_clap_dynamic_completer_" "$zcompdump" 2>/dev/null; then
    rm -f "$zdot"/.zcompdump*(N)
    return 0
  fi

  local watched=(
    "$ZSHCONF"/init.zsh
    "$ZSHCONF"/modules/**/*.zsh(N)
    "$HOME/.local/share/zinit/completions"
    "$HOME/.cache/zinit/completions"
    "/opt/homebrew/share/zsh/site-functions"
  )

  local entry
  for entry in $watched; do
    if [[ -e "$entry" && ( ! -f "$zcompdump" || "$entry" -nt "$zcompdump" ) ]]; then
      rm -f "$zdot"/.zcompdump*(N)
      break
    fi
  done
}
