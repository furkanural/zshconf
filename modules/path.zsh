export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export PNPM_HOME="${PNPM_HOME:-$HOME/Library/pnpm}"

# Ours first, inherited ($path) last; typeset -U keeps the first occurrence,
# so a parent's ordering never outranks ours.
# /home/[l]inuxbrew: a literal /home path stalls ~50 ms on macOS (autofs);
# the bracket glob does not.
path=(
  $ANDROID_HOME/emulator(N)
  $ANDROID_HOME/platform-tools(N)
  $HOME/.maestro/bin(N)
  $PNPM_HOME/bin(N)
  /opt/homebrew/bin(N)
  /opt/homebrew/sbin(N)
  /opt/homebrew/opt/curl/bin(N)
  /opt/homebrew/share/google-cloud-sdk/bin(N)
  /usr/local/bin(N)
  /usr/local/sbin(N)
  /home/[l]inuxbrew/.linuxbrew/bin(N)
  /home/[l]inuxbrew/.linuxbrew/sbin(N)
  /usr/bin
  /bin
  /usr/sbin
  /sbin
  $HOME/.local/bin(N)
  $HOME/bin(N)
  $path
)
typeset -U path
export PATH

fpath=(
  ${ZDOTDIR:-$HOME}/.zsh/completions(N)
  $ZSHCONF/completions(N)
  /opt/homebrew/share/zsh/site-functions(N)
  /usr/local/share/zsh/site-functions(N)
  /home/[l]inuxbrew/.linuxbrew/share/zsh/site-functions(N)
  $fpath
)
typeset -U fpath
