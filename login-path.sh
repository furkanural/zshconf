# login-path.sh — PATH for LOGIN shells that never reach ~/.zshrc.
#
# Sourced by the one-line stubs install.sh writes to ~/.zprofile and the
# login-bash profile (~/.bash_profile, else ~/.bash_login, else ~/.profile).
# Like init.zsh, this file is the repo's: the stubs never change, so updates
# arrive with `zshconf-update`.
#
# Why it exists. Two kinds of shell read a login profile but not ~/.zshrc:
#   - `bash -lc …` / `sh -lc …`: how agent tools (Orca, Claude Code, Codex),
#     editors and the git hooks they spawn run commands.
#   - `zsh -lc …`: how GUI apps (Zed, VS Code) read your environment.
# On macOS /etc/profile and /etc/zprofile run path_helper, which re-prepends
# /usr/bin (system Ruby, Python…) to the PATH those shells inherited — so
# mise and Homebrew lose even though the parent interactive zsh had them
# first. This puts them back in front.
#
# Rules:
#   - POSIX sh only: ~/.profile is read by `sh -l`, and zsh sources this
#     before any option is set, so nothing zsh- or bash-specific.
#   - No PATH list of our own: modules/path.zsh stays the single authority
#     for ordering; this file only sets what the two tools' own shellenv
#     would.
#   - Cheap: no forks. `brew shellenv` costs ~40 ms (a Ruby-free but still
#     bash-wrapped script) for output that is a pure function of the prefix,
#     so its exports are written out here instead. Only `mise activate` is
#     run, and it is a ~10 ms native binary.
#   - Idempotent: a guard makes a login+interactive shell (which also runs
#     path.zsh + dev-tools.zsh) skip the second pass.

if [ -z "${ZSHCONF_LOGIN_PATH_SOURCED:-}" ]; then
  ZSHCONF_LOGIN_PATH_SOURCED=1

  # Homebrew. Candidates in path.zsh order; linuxbrew last and only probed
  # when the others are missing (a literal /home lookup costs ~50 ms on macOS
  # via autofs). The exports mirror `brew shellenv` for sh/bash/zsh — if
  # Homebrew changes that output, update this block (verified by a test).
  for _zshconf_brew in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew; do
    if [ -x "$_zshconf_brew/bin/brew" ]; then
      export HOMEBREW_PREFIX="$_zshconf_brew"
      export HOMEBREW_CELLAR="$_zshconf_brew/Cellar"
      if [ -d "$_zshconf_brew/Homebrew" ]; then
        export HOMEBREW_REPOSITORY="$_zshconf_brew/Homebrew"   # Intel macOS, Linux
      else
        export HOMEBREW_REPOSITORY="$_zshconf_brew"            # Apple silicon
      fi
      export PATH="$_zshconf_brew/bin:$_zshconf_brew/sbin${PATH+:$PATH}"
      export INFOPATH="$_zshconf_brew/share/info:${INFOPATH:-}"
      # A trailing/leading ':' keeps the system man dirs: brew shellenv does
      # the same normalisation.
      [ -z "${MANPATH-}" ] || { MANPATH="${MANPATH%"${MANPATH##*[!:]}"}"; export MANPATH=":${MANPATH#"${MANPATH%%[!:]*}"}"; }
      break
    fi
  done
  unset _zshconf_brew

  # mise, in shim mode: a non-interactive shell never reaches the prompt hook
  # the full activation relies on, so shims are the only thing that works
  # here. `activate bash --shims` emits a plain `export PATH=…`, valid in sh
  # and zsh too. An interactive zsh later runs the full `mise activate zsh`
  # (dev-tools.zsh), which puts the real tool dirs ahead of the shims.
  # ~/.local/bin/mise first: the install script (mise.run) puts it there and
  # mise's docs recommend that over package managers; a leftover package
  # copy on PATH must not shadow it.
  for _zshconf_mise in "$HOME/.local/bin/mise" "$(command -v mise 2>/dev/null)"; do
    if [ -n "$_zshconf_mise" ] && [ -x "$_zshconf_mise" ]; then
      eval "$("$_zshconf_mise" activate bash --shims)"
      break
    fi
  done
  unset _zshconf_mise
fi
