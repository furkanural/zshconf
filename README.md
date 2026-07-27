# zshconf

An opinionated zsh configuration — a tuned completion system, staggered
(turbo) plugin loading via [Zinit], and a [Starship] prompt — structured so
you can **use it and keep pulling updates without forking**. The repo is
sourced, never edited; everything personal or machine-specific lives in a
local overlay outside the repo.

This is not a framework. There are no settings files and no option matrix —
you get one coherent, fast setup, plus a clean seam to layer your own
config on top.

## What you get

- **Completion, done properly** — fuzzy matching (case-insensitive →
  partial-word → substring), typo correction, [fzf-tab] menus with file
  previews, most-recent-first file sorting, per-command styling.
- **Fast startup** — plugins load in three deferred tiers *after* the first
  prompt paints; tool inits (`fzf`, `zoxide`) are cached; everything is
  byte-compiled in the background.
- **Sane defaults** — 50k shared history with noise filtering, safe
  redirects (`noclobber`), `AUTO_PUSHD`, and a curated set of aliases and
  functions (`mkcd`, `portkill`, `gbclean`, `sysup`, …).
- **Graceful degradation** — every optional tool (eza, fzf, bat, fd,
  ripgrep, zoxide, starship, vivid, mise) is feature-detected. Nothing
  breaks when one is missing; there's even a fallback prompt.
- **macOS first-class, Linux supported** — macOS is where it's daily-driven;
  Linux is CI-tested on every push.

## Requirements

`zsh` (5.8+), `git`, and `curl` — that's it. Everything else is optional;
install the full toolset with `brew bundle` if you like.

## Install

```sh
git clone https://github.com/OWNER/zshconf ~/.local/share/zshconf
cd ~/.local/share/zshconf
./install.sh        # read it first — it's short
exec zsh
```

The installer does three things, idempotently: backs up any existing
`~/.zshrc` (to `~/.zshrc.pre-zshconf`), writes a 3-line stub that sources
this repo, and creates the overlay directory. It does **not** install tools,
touch your existing prompt config, or migrate anything. First startup clones
Zinit (pinned to a release tag) and the plugins; later startups are fast.

Optional extras:

```sh
brew bundle         # the tools the config integrates with
```

## Update

```sh
zshconf-update      # git pull --ff-only + recompile, then: exec zsh
```

`--ff-only` is deliberate: if you've edited repo files, update stops instead
of merging. That's the contract — the core is sourced, never edited. (The
`sysup` function runs this automatically as one of its lanes.)

## Make it yours (the overlay)

All personal and machine-specific config lives in
`${XDG_CONFIG_HOME:-~/.config}/zsh/`, outside this repo:

- **`local.d/*.zsh`** — drop-in files, sourced *after* everything in the
  repo, in name order. Override anything: re-export variables, re-alias,
  redefine functions, re-set zstyles, add your own `zinit` plugins. One
  concern per file (`editor.zsh`, `work.zsh`, …).
- **`pre.zsh`** — sourced *before* the core. Only needed for values the
  core consumes during startup (e.g. `LS_COLORS`). When in doubt, use
  `local.d`.

Examples:

```zsh
# ~/.config/zsh/local.d/editor.zsh
export EDITOR=vim

# ~/.config/zsh/local.d/work.zsh — only on work machines
[[ "$HOST" == work-* ]] || return 0
export SOME_INTERNAL_URL=...
```

Patterns worth knowing: the overlay directory can itself be a **private git
repo** (public core + private personal layer, synced across machines);
secrets belong in a `chmod 600` file sourced from a drop-in, or better, a
secret manager — never in either repo.

Your own Starship config? If `~/.config/starship.toml` exists (or
`STARSHIP_CONFIG` is set), it wins; otherwise the repo's config is used.

## Uninstall

```sh
rm ~/.zshrc                             # the stub
mv ~/.zshrc.pre-zshconf ~/.zshrc        # restore your old config (if any)
rm -rf ~/.local/share/zshconf        # the clone
```

Your overlay (`~/.config/zsh/`) is yours; keep or delete it.

## Development

```sh
just test        # full suite (what CI runs)
just test-bare   # CI's toughest cell locally: bare Linux in Docker
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for how the pieces fit —
notably the load-order constraints in `init.zsh` — and
[CONTRIBUTING.md](CONTRIBUTING.md) for the scope policy before opening a PR.

## License

[MIT](LICENSE).

[Zinit]: https://github.com/zdharma-continuum/zinit
[Starship]: https://starship.rs
[fzf-tab]: https://github.com/Aloxaf/fzf-tab
