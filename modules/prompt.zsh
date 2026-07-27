# ── Starship prompt  (after PATH + version managers)
if (( $+commands[starship] )); then
  # Config precedence: an explicit $STARSHIP_CONFIG (e.g. from pre.zsh) wins;
  # then a user's own ~/.config/starship.toml; only otherwise the repo default.
  if [[ -z "${STARSHIP_CONFIG:-}" && ! -f "${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml" ]]; then
    export STARSHIP_CONFIG="$ZSHCONF/config/starship.toml"
  fi
  eval "$(starship init zsh)"
else
  # No starship: a deliberate minimal fallback, not zsh's bare default.
  PS1='%F{cyan}%~%f %(?.%F{green}.%F{red})❯%f '
fi
