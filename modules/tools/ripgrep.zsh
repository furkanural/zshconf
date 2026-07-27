# ── ripgrep — faster grep.
if (( $+commands[rg] )); then
  alias rgi='rg --ignore-case'
  alias rgf='rg --files | rg'                         # match filenames
  alias rgl='rg -l'                                   # file list only
  alias rgc='rg -c'                                   # match counts
  alias rga='rg --hidden --no-ignore'                 # search everything
fi
