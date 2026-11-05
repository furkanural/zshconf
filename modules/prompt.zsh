if (( $+commands[starship] )); then
  # $STARSHIP_CONFIG, then the user's ~/.config/starship.toml, then ours.
  if [[ -z "${STARSHIP_CONFIG:-}" && ! -f "${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml" ]]; then
    export STARSHIP_CONFIG="$ZSHCONF/config/starship.toml"
  fi
  eval "$(starship init zsh)"
else
  PS1='%F{cyan}%~%f %(?.%F{green}.%F{red})❯%f '
fi
