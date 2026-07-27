# ── PATH  (brew AS → brew Intel → brew Linux → system → user-local; (N) skips missing dirs)
path=(
  /opt/homebrew/bin(N)
  /opt/homebrew/sbin(N)
  /opt/homebrew/opt/curl/bin(N)
  /usr/local/bin(N)
  /usr/local/sbin(N)
  /home/linuxbrew/.linuxbrew/bin(N)
  /home/linuxbrew/.linuxbrew/sbin(N)
  /usr/bin
  /bin
  /usr/sbin
  /sbin
  $HOME/.local/bin(N)
  $HOME/bin(N)
)
typeset -U path
export PATH

# ── FPATH  (user → brew → system; must precede zicompinit; blockf blocks plugin edits)
fpath=(
  ${ZDOTDIR:-$HOME}/.zsh/completions(N)
  /opt/homebrew/share/zsh/site-functions(N)
  /usr/local/share/zsh/site-functions(N)
  $fpath
)
typeset -U fpath
