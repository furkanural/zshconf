# Optional tools this config integrates with. Everything degrades gracefully
# when absent — install all with `brew bundle`, or cherry-pick.
#
# mise is deliberately NOT here: its docs recommend the install script over
# package managers (official binary, faster build, self-update works):
#   curl -fsSL https://mise.run | sh        # installs ~/.local/bin/mise
# Keep one copy per machine — a Homebrew mise alongside it shadows nothing
# (login-path.sh prefers ~/.local/bin) but wastes 230 MB and `mise doctor`
# will warn. `brew uninstall mise && mise reshim` after switching.
brew "bat"        # cat with highlighting (kat/ccat, man pages)
brew "eza"        # ls replacement (via OMZP::eza)
brew "fd"         # find replacement; also feeds fzf
brew "fzf"        # fuzzy finder (Ctrl+R/T, fzf-tab previews, dstop/drm)
brew "gh"         # GitHub CLI (ghopen, ghpr)
brew "ripgrep"    # grep replacement (rgg, rgi, ...)
brew "starship"   # prompt
brew "topgrade"   # update orchestrator (sysup --topgrade)
brew "vivid"      # LS_COLORS generator
brew "zoxide"     # smarter cd (z)
