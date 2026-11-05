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

  # Substring test, not grep: no fork (~3 ms per startup), and immune to
  # environments that shadow grep (install.sh has the same rule).
  if [[ -r "$zcompdump" && "$(<$zcompdump)" == *_clap_dynamic_completer_* ]]; then
    rm -f "$zdot"/.zcompdump*(N)
    return 0
  fi

  # The brew site-functions candidates mirror path.zsh's fpath list — a
  # formula that ships a completer must invalidate the dump on every prefix.
  # (N) on them: a missing dir is skipped without an -e test, and the
  # [l]inuxbrew bracket glob avoids the autofs stall (see path.zsh).
  local watched=(
    "$ZSHCONF"/init.zsh
    "$ZSHCONF"/modules/**/*.zsh(N)
    "$ZSHCONF"/completions/*(N)
    "$zdot/.zsh/completions"                    # user/generated completers (e.g. _docker)
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
