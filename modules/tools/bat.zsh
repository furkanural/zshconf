if (( $+commands[bat] )); then
  export BAT_THEME="TwoDark"
  export BAT_STYLE="numbers,changes,header,grid"
  (( $+commands[col] )) && export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  export MANROFFOPT='-c'                  # groff >= 1.23 otherwise garbles man pages
  alias kat='bat --paging=never --style=plain'
  alias ccat='bat --paging=never'
fi
