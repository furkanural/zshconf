# ── Model presets
# Source $XDG_CONFIG_HOME/cliproxy-presets/<name>.env (ANTHROPIC_BASE_URL / _AUTH_TOKEN / _DEFAULT_*_MODEL).
#   modelpreset          list presets
#   modelpreset hybrid   load hybrid.env into the current shell
modelpreset() {
  local dir="${XDG_CONFIG_HOME:-$HOME/.config}/cliproxy-presets"
  [[ -d "$dir" ]] || { echo "Preset directory not found: $dir" >&2; return 1; }

  local -a presets
  presets=("$dir"/*.env(.N:t:r))

  # With an arg: validate + load. Hard error → non-zero; unknown name → print list.
  if [[ -n "$1" ]]; then
    if [[ "$1" == */* ]]; then
      echo "Invalid preset name: $1" >&2
      return 1
    fi
    local file="$dir/$1.env"
    if [[ -f "$file" ]]; then
      if source "$file"; then
        echo "Loaded preset: $1"
        return 0
      fi
      echo "Failed to load preset: $1 (syntax error in $file)" >&2
      return 1
    fi
    echo "Preset not found: $1" >&2
  fi

  # Reached with no arg (listing) or unknown preset (hint after error).
  echo "Available presets:"
  (( ${#presets} )) && print -l "${presets[@]}" || echo "  (none)"
  [[ -z "$1" ]]   # 0 for plain listing, 1 when arrived via "not found"
}

# Tab-complete preset names.
_modelpreset() {
  local dir="${XDG_CONFIG_HOME:-$HOME/.config}/cliproxy-presets"
  [[ -d "$dir" ]] || return 1
  local -a presets
  presets=("$dir"/*.env(.N:t:r))
  (( ${#presets} )) && _describe 'preset' presets
}
# compdef exists only after Tier 1 zicompinit; zicompdef queues it for zicdreplay.
if (( ${+functions[compdef]} )); then
  compdef _modelpreset modelpreset
elif (( ${+functions[zicompdef]} )); then
  zicompdef _modelpreset modelpreset
fi
