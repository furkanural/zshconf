# ── bat — cat with highlighting (distinct names so real cat/less survive).
if (( $+commands[bat] )); then
  export BAT_THEME="TwoDark"
  export BAT_STYLE="numbers,changes,header,grid"
  # Highlighted man pages; col(1) isn't universal on Linux, so feature-detect.
  (( $+commands[col] )) && export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  # groff >= 1.23 emits SGR escapes by default, which col/bat render as
  # garbage; -c restores the legacy overstrike output (bat's README fix).
  export MANROFFOPT='-c'
  alias kat='bat --paging=never --style=plain'        # plain (no numbers/grid)
  alias ccat='bat --paging=never'                     # numbers + grid
fi
