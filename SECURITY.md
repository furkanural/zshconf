# Security

## Threat model, honestly stated

A zsh config executes code at every shell start. What this one runs, and the posture for each:

- **Zinit (plugin manager):** bootstrap-cloned from `zdharma-continuum/zinit` and **pinned to a release tag** — first-run code execution on a fresh machine is deterministic. After that, `zinit self-update` moves it (trust-on-first-use).
- **Plugins and OMZ snippets:** a short, deliberately boring list (zsh-users, zdharma-continuum, Aloxaf/fzf-tab, oh-my-zsh snippets) that **floats at upstream HEAD**. This is the standard trade-off of the zsh plugin ecosystem, stated here rather than hidden: pinning a dozen fast-moving repos is maintenance nobody sustains. Review the list in `modules/plugins.zsh`; shrink it in your fork if your threat model demands it.
- **Cached tool inits:** `fzf --zsh` / `zoxide init zsh` output is cached and sourced from Zinit's directory. Anything writable under `$HOME` that gets sourced means `$HOME` compromise = shell compromise — true of every zsh setup; noted for completeness.
- **The installer** touches three things (stub, backup, overlay dir), is idempotent, and never deletes user data. The documented install path is clone-then-inspect-then-run; there is intentionally no `curl | bash`.
- **Secrets:** the core never requires any. Keep them out of both repos — use a `chmod 600` file sourced from an overlay drop-in, or a secret manager. `.gitignore` defensively excludes `*.env` and `secrets.*`.

## Reporting

Please report vulnerabilities via GitHub's private security advisories for this repository ("Report a vulnerability") rather than public issues.
