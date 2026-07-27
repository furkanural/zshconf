# ── Model presets — switch Claude Code (or any Anthropic-API tool) between
# endpoints/models. Presets are env files in
# $XDG_CONFIG_HOME/cliproxy-presets/<name>.env holding ANTHROPIC_BASE_URL /
# ANTHROPIC_AUTH_TOKEN / ANTHROPIC_DEFAULT_*_MODEL. The files may contain
# tokens — they are created mode 600 and live outside any repo.
#   modelpreset                 list presets
#   modelpreset <name>          load a preset into the current shell
#   modelpreset add <name>      create a preset (interactive prompts)
#   modelpreset edit <name>     open a preset in $EDITOR
#   modelpreset remove <name>   delete a preset (asks first)
modelpreset() {
  emulate -L zsh
  local dir="${XDG_CONFIG_HOME:-$HOME/.config}/cliproxy-presets"
  local -a presets
  presets=("$dir"/*.env(.N:t:r))

  local action="$1" name file
  case "$action" in
    add|edit|remove)
      name="$2"
      if [[ -z "$name" || "$name" == */* ]]; then
        echo "Usage: modelpreset $action <name>" >&2
        return 1
      fi
      file="$dir/$name.env"

      case "$action" in
        add)
          if [[ -f "$file" ]]; then
            echo "Preset already exists: $name (try: modelpreset edit $name)" >&2
            return 1
          fi
          command mkdir -p "$dir"

          local key value
          local -a lines
          for key in ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN \
                     ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL \
                     ANTHROPIC_DEFAULT_HAIKU_MODEL; do
            # Hide token input on a real terminal; plain read when piped.
            if [[ "$key" == *AUTH_TOKEN* && -t 0 ]]; then
              read -rs "value?$key (empty to skip): " || return 1
              print
            else
              read -r "value?$key (empty to skip): " || return 1
            fi
            [[ -n "$value" ]] && lines+=("export $key=${(qq)value}")
          done

          if (( ! ${#lines} )); then
            echo "All values empty; preset not created." >&2
            return 1
          fi
          (umask 077; print -rl -- "${lines[@]}" > "$file") || return 1
          echo "Created preset: $name (${file/#$HOME/~}, mode 600)"
          ;;
        edit)
          [[ -f "$file" ]] || { echo "Preset not found: $name (try: modelpreset add $name)" >&2; return 1 }
          "${EDITOR:-nano}" "$file"
          ;;
        remove)
          [[ -f "$file" ]] || { echo "Preset not found: $name" >&2; return 1 }
          local reply
          read -r "reply?Delete ${file/#$HOME/~}? [y/N] "
          if [[ "$reply" != ([yY]|yes|YES) ]]; then
            echo "Aborted."
            return 1
          fi
          rm -f -- "$file" && echo "Removed preset: $name"
          ;;
      esac
      return
      ;;
  esac

  # No subcommand: list, or load <name>.
  [[ -d "$dir" ]] || { echo "Preset directory not found: $dir (try: modelpreset add <name>)" >&2; return 1; }

  # With an arg: validate + load. Hard error → non-zero; unknown name → print list.
  if [[ -n "$action" ]]; then
    if [[ "$action" == */* ]]; then
      echo "Invalid preset name: $action" >&2
      return 1
    fi
    file="$dir/$action.env"
    if [[ -f "$file" ]]; then
      if source "$file"; then
        echo "Loaded preset: $action"
        return 0
      fi
      echo "Failed to load preset: $action (syntax error in $file)" >&2
      return 1
    fi
    echo "Preset not found: $action" >&2
  fi

  # Reached with no arg (listing) or unknown preset (hint after error).
  echo "Available presets:"
  (( ${#presets} )) && print -l "${presets[@]}" || echo "  (none)"
  [[ -z "$action" ]]   # 0 for plain listing, 1 when arrived via "not found"
}

# Tab-complete subcommands + preset names.
_modelpreset() {
  local dir="${XDG_CONFIG_HOME:-$HOME/.config}/cliproxy-presets"
  local -a presets
  presets=("$dir"/*.env(.N:t:r))

  if (( CURRENT == 2 )); then
    local -a subcmds=(
      'add:create a preset'
      'edit:open a preset in $EDITOR'
      'remove:delete a preset'
    )
    _describe -t subcommands 'subcommand' subcmds
    (( ${#presets} )) && _describe -t presets 'preset' presets
  elif (( CURRENT == 3 )); then
    case "$words[2]" in
      edit|remove)
        (( ${#presets} )) && _describe 'preset' presets
        ;;
    esac
  fi
}
# compdef exists only after Tier 1 zicompinit; zicompdef queues it for zicdreplay.
if (( ${+functions[compdef]} )); then
  compdef _modelpreset modelpreset
elif (( ${+functions[zicompdef]} )); then
  zicompdef _modelpreset modelpreset
fi
