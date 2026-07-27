# Changelog

Notable, user-visible changes only. `main` is rolling; update with
`zshconf-update`.

## Unreleased

Initial public structure:

- Manifest + modules split of the original single-file config, with the
  load-order constraints documented in `init.zsh`.
- Local overlay: `~/.config/zsh/pre.zsh` + `~/.config/zsh/local.d/*.zsh`.
- `install.sh` (stub + backup + overlay dir) and `zshconf-update`.
- Starship config in-repo (whitelist `format`), with user-config
  precedence and a fallback prompt.
- Linux support: linuxbrew paths, `modules/os/` split, feature-detected
  `MANPAGER`; fixed `ip`/`free` alias shadowing on Linux.
- Zinit bootstrap pinned to a release tag (TOFU).
- Test suite + 2×2 CI matrix + report-only zsh-bench job.
