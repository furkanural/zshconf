# ── bat — cat with highlighting (distinct names so real cat/less survive).
if (( $+commands[bat] )); then
  export BAT_THEME="TwoDark"
  export BAT_STYLE="numbers,changes,header,grid"
  # Highlighted man pages; col(1) isn't universal on Linux, so feature-detect.
  (( $+commands[col] )) && export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  alias kat='bat --paging=never --style=plain'        # plain (no numbers/grid)
  alias ccat='bat --paging=never'                     # numbers + grid
fi
