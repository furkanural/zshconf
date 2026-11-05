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
#     for ordering; this file only re-runs the two tools' own shellenv.
#   - Idempotent and cheap: a guard makes a login+interactive shell (which
#     also runs path.zsh + dev-tools.zsh) skip the second pass.

if [ -z "${ZSHCONF_LOGIN_PATH_SOURCED:-}" ]; then
  ZSHCONF_LOGIN_PATH_SOURCED=1

  # Homebrew. Candidates in path.zsh order; linuxbrew last and only probed
  # when the others are missing (a literal /home lookup costs ~50 ms on macOS
  # via autofs).
  for _zshconf_brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [ -x "$_zshconf_brew" ]; then
      eval "$("$_zshconf_brew" shellenv)"
      break
    fi
  done
  unset _zshconf_brew

  # mise, in shim mode: a non-interactive shell never reaches the prompt hook
  # the full activation relies on, so shims are the only thing that works
  # here. `activate bash --shims` emits a plain `export PATH=…`, valid in sh
  # and zsh too. An interactive zsh later runs the full `mise activate zsh`
  # (dev-tools.zsh), which puts the real tool dirs ahead of the shims.
  for _zshconf_mise in "$(command -v mise 2>/dev/null)" "$HOME/.local/bin/mise"; do
    if [ -n "$_zshconf_mise" ] && [ -x "$_zshconf_mise" ]; then
      eval "$("$_zshconf_mise" activate bash --shims)"
      break
    fi
  done
  unset _zshconf_mise
fi
