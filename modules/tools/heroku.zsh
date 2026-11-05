if (( $+commands[heroku] )); then
  typeset -g _heroku_ac="$HOME/Library/Caches/heroku/autocomplete"
  [[ -d "$_heroku_ac" ]] || _heroku_ac="${XDG_CACHE_HOME:-$HOME/.cache}/heroku/autocomplete"
  export HEROKU_AC_ANALYTICS_DIR="$_heroku_ac/completion_analytics"
  export HEROKU_AC_COMMANDS_PATH="$_heroku_ac/commands"

  # commands_setters is 116KB; defer it.
  zinit ice wait'1' lucid id-as'heroku-autocomplete' \
    atload'[[ -f $_heroku_ac/commands_setters ]] && source $_heroku_ac/commands_setters; unset _heroku_ac'
  zinit light zdharma-continuum/null
fi
