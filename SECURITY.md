# Security

A zsh config executes code at every shell start. What this one runs:

- **Zinit:** cloned from `zdharma-continuum/zinit` and reset to a pinned tag on first run; `zinit self-update` moves it afterwards.
- **Plugins and OMZ snippets:** a short list (zsh-users, zdharma-continuum, Aloxaf/fzf-tab, oh-my-zsh) floating at upstream HEAD. Review it in `modules/plugins.zsh`.
- **Cached tool inits:** `fzf --zsh` / `zoxide init zsh` output is cached under `$HOME` and sourced, like every zsh setup.
- **The installer** writes stubs and marked blocks, backs up `~/.zshrc`, and never deletes user data. There is no `curl | bash`.
- **Secrets:** none required. `.gitignore` excludes `*.env` and `secrets.*`.

## Reporting

Use GitHub's private security advisories for this repository, not public issues.
