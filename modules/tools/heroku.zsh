# ── Heroku autocomplete  (keep AC env vars + commands_setters; refresh: heroku autocomplete --refresh-cache)
if (( $+commands[heroku] )); then
  export HEROKU_AC_ANALYTICS_DIR="$HOME/Library/Caches/heroku/autocomplete/completion_analytics"
  export HEROKU_AC_COMMANDS_PATH="$HOME/Library/Caches/heroku/autocomplete/commands"

  # Defer the 116KB commands_setters source to ~1s after the prompt.
  zinit ice wait'1' lucid id-as'heroku-autocomplete' \
    atload'[[ -f $HOME/Library/Caches/heroku/autocomplete/commands_setters ]] && source $HOME/Library/Caches/heroku/autocomplete/commands_setters'
  zinit light zdharma-continuum/null
fi
