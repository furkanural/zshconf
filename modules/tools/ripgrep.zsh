if (( $+commands[rg] )); then
  alias rgi='rg --ignore-case'
  alias rgf='rg --files | rg'
  alias rgl='rg -l'
  alias rgc='rg -c'
  alias rga='rg --hidden --no-ignore'
fi
