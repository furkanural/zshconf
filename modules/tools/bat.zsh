# ── bat — cat with highlighting (distinct names so real cat/less survive).
if (( $+commands[bat] )); then
  export BAT_THEME="TwoDark"
  export BAT_STYLE="numbers,changes,header,grid"
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"   # highlighted man pages
  alias kat='bat --paging=never --style=plain'        # plain (no numbers/grid)
  alias ccat='bat --paging=never'                     # numbers + grid
fi
