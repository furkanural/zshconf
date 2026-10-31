export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export PNPM_HOME="${PNPM_HOME:-$HOME/Library/pnpm}"

# ── PATH  (Android/Maestro/pnpm → brew AS (+gcloud SDK) → brew Intel → brew Linux → system → user-local → inherited; (N) skips missing dirs)
# Linuxbrew paths are written /home/[l]inuxbrew on purpose: on macOS /home is
# an autofs mount (auto_home), and a LITERAL path lookup under it blocks on
# directory services for ~50 ms every startup. A bracket glob readdir()s
# instead and returns instantly. Never "simplify" it back to a literal.
# Inherited entries ($path, last) survive — e.g. the dirs a terminal (Ghostty)
# or an editor's integrated terminal appended — but never outrank ours;
# typeset -U keeps the first occurrence. Consequence: a tool env that
# PREPENDED to PATH before spawning this shell (nix-shell --run zsh, a venv
# subshell) keeps its dir on PATH but loses precedence to Homebrew's binary.
# Deliberate: honouring arbitrary parent order would let macOS's path_helper
# or a stray /usr/local/bin jump ahead of /opt/homebrew/bin.
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

# ── FPATH  (user → repo → brew → system; must precede zicompinit; blockf blocks plugin edits)
fpath=(
  ${ZDOTDIR:-$HOME}/.zsh/completions(N)
  $ZSHCONF/completions(N)                 # completers for this repo's functions (_sysup, …)
  /opt/homebrew/share/zsh/site-functions(N)
  /usr/local/share/zsh/site-functions(N)
  /home/[l]inuxbrew/.linuxbrew/share/zsh/site-functions(N)   # [l]: see autofs note above
  $fpath
)
typeset -U fpath
