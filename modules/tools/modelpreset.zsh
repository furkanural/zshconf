# Switch Claude Code (or any Anthropic-API tool) between endpoints/models.
# Presets: $XDG_CONFIG_HOME/cliproxy-presets/<name>.env (mode 600).
#   modelpreset                 list
#   modelpreset <name>          load into the current shell
#   modelpreset add|edit|remove <name>
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

  [[ -d "$dir" ]] || { echo "Preset directory not found: $dir (try: modelpreset add <name>)" >&2; return 1; }

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

  echo "Available presets:"
  (( ${#presets} )) && print -l "${presets[@]}" || echo "  (none)"
  [[ -z "$action" ]]   # 1 when reached via "not found"
}

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
# compdef exists only after Tier 1; zicompdef queues it until then.
if (( ${+functions[compdef]} )); then
  compdef _modelpreset modelpreset
elif (( ${+functions[zicompdef]} )); then
  zicompdef _modelpreset modelpreset
fi
