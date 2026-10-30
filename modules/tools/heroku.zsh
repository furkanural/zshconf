# ── Heroku autocomplete  (keep AC env vars + commands_setters; refresh: heroku autocomplete --refresh-cache)
if (( $+commands[heroku] )); then
  # Cache dir: macOS ~/Library/Caches, elsewhere XDG — first that exists.
  typeset -g _heroku_ac="$HOME/Library/Caches/heroku/autocomplete"
  [[ -d "$_heroku_ac" ]] || _heroku_ac="${XDG_CACHE_HOME:-$HOME/.cache}/heroku/autocomplete"
  export HEROKU_AC_ANALYTICS_DIR="$_heroku_ac/completion_analytics"
  export HEROKU_AC_COMMANDS_PATH="$_heroku_ac/commands"

  # Defer the 116KB commands_setters source to ~1s after the prompt.
  zinit ice wait'1' lucid id-as'heroku-autocomplete' \
    atload'[[ -f $_heroku_ac/commands_setters ]] && source $_heroku_ac/commands_setters; unset _heroku_ac'
  zinit light zdharma-continuum/null
fi
