# bash-login.sh — PATH for LOGIN bash. Sourced by the one-line stub install.sh
# writes to ~/.bash_profile (or ~/.bash_login / ~/.profile). Like init.zsh,
# this file is the repo's; the stub never changes, so updates arrive with
# `zshconf-update`.
#
# Why it exists: agent tools (Orca, Claude Code, Codex), editors and the git
# hooks they run get a shell via `bash -lc …`. On macOS that login bash reads
# /etc/profile, whose path_helper re-prepends /usr/bin (system Ruby, Python…)
# to the PATH it inherited from zsh — so mise and Homebrew lose. This puts
# them back in front. zsh is untouched: modules/path.zsh stays the authority.
#
# POSIX sh only (the stub may land in ~/.profile, which `sh -l` reads too).
# No PATH list of our own: a second authority would drift from path.zsh.

# Homebrew. Candidates in path.zsh order; linuxbrew last and only probed when
# the others are missing (a literal /home lookup costs ~50 ms via autofs).
for _zshconf_brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  if [ -x "$_zshconf_brew" ]; then
    eval "$("$_zshconf_brew" shellenv)"
    break
  fi
done
unset _zshconf_brew

# mise, in shim mode: a non-interactive shell never reaches the prompt hook
# the full activation relies on, so shims are the only thing that works here.
for _zshconf_mise in "$(command -v mise 2>/dev/null)" "$HOME/.local/bin/mise"; do
  if [ -n "$_zshconf_mise" ] && [ -x "$_zshconf_mise" ]; then
    eval "$("$_zshconf_mise" activate bash --shims)"
    break
  fi
done
unset _zshconf_mise
