# ── fd — faster find.
if (( $+commands[fd] )); then
  alias fdf='fd --type f'
  alias fdd='fd --type d'
  alias fda='fd --hidden'
  alias fdx='fd --type x'
fi
