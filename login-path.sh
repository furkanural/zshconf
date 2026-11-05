# PATH for login shells that never reach ~/.zshrc: `zsh -lc` (GUI apps),
# `bash -lc` / `sh -lc` (agent tools, editors, git hooks). macOS path_helper
# puts /usr/bin ahead of the inherited PATH; this puts Homebrew and mise
# back in front. Sourced from the stubs install.sh writes.
#
# POSIX sh. No forks except mise: `brew shellenv` costs ~40 ms for output
# that depends only on the prefix, so its exports are written here (a test
# keeps them identical).

if [ -z "${ZSHCONF_LOGIN_PATH_SOURCED:-}" ]; then
  ZSHCONF_LOGIN_PATH_SOURCED=1

  # Linuxbrew last: a /home lookup stalls ~50 ms on macOS (autofs).
  for _zshconf_brew in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew; do
    if [ -x "$_zshconf_brew/bin/brew" ]; then
      export HOMEBREW_PREFIX="$_zshconf_brew"
      export HOMEBREW_CELLAR="$_zshconf_brew/Cellar"
      if [ -d "$_zshconf_brew/Homebrew" ]; then
        export HOMEBREW_REPOSITORY="$_zshconf_brew/Homebrew"
      else
        export HOMEBREW_REPOSITORY="$_zshconf_brew"
      fi
      export PATH="$_zshconf_brew/bin:$_zshconf_brew/sbin${PATH+:$PATH}"
      export INFOPATH="$_zshconf_brew/share/info:${INFOPATH:-}"
      [ -z "${MANPATH-}" ] || { MANPATH="${MANPATH%"${MANPATH##*[!:]}"}"; export MANPATH=":${MANPATH#"${MANPATH%%[!:]*}"}"; }
      break
    fi
  done
  unset _zshconf_brew

  # Shim mode: a non-interactive shell has no prompt hook. An interactive
  # zsh runs the full activation later and puts tool dirs ahead of shims.
  # ~/.local/bin first: that is where mise.run installs.
  for _zshconf_mise in "$HOME/.local/bin/mise" "$(command -v mise 2>/dev/null)"; do
    if [ -n "$_zshconf_mise" ] && [ -x "$_zshconf_mise" ]; then
      eval "$("$_zshconf_mise" activate bash --shims)"
      break
    fi
  done
  unset _zshconf_mise
fi
