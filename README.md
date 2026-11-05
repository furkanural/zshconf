# zshconf

[![CI](https://github.com/furkanural/zshconf/actions/workflows/ci.yml/badge.svg)](https://github.com/furkanural/zshconf/actions/workflows/ci.yml)

An opinionated zsh configuration — a tuned completion system, staggered (turbo) plugin loading via [Zinit], and a [Starship] prompt — structured so you can **use it and keep pulling updates without forking**. The repo is sourced, never edited; everything personal or machine-specific lives in a local overlay outside the repo.

This is not a framework. There are no settings files and no option matrix — you get one coherent, fast setup, plus a clean seam to layer your own config on top.

## What you get

- **Completion, done properly** — fuzzy matching (case-insensitive → partial-word → substring), typo correction, [fzf-tab] menus with file previews, most-recent-first file sorting, per-command styling.
- **Fast startup** — plugins load in three deferred tiers _after_ the first prompt paints; tool inits (`fzf`, `zoxide`) are cached; everything is byte-compiled in the background.
- **Sane defaults** — 100k shared history with noise filtering, safe redirects (`noclobber`), `AUTO_PUSHD`, and a curated set of aliases and functions (`mkcd`, `portkill`, `gbclean`, `sysup`, …).
- **Graceful degradation** — every optional tool (eza, fzf, bat, fd, ripgrep, zoxide, starship, vivid, mise) is feature-detected. Nothing breaks when one is missing; there's even a fallback prompt.
- **macOS first-class, Linux supported** — macOS is where it's daily-driven; Linux is CI-tested on every push.

## Requirements

`zsh` (5.8+), `git`, and `curl` — that's it. Everything else is optional; install the full toolset with `brew bundle --file "$ZSHCONF/Brewfile"` if you like.

## Install

```sh
git clone --depth 1 https://github.com/furkanural/zshconf ~/.local/share/zshconf
cd ~/.local/share/zshconf
./install.sh        # read it first — it's short
exec zsh
```

The installer is idempotent and never deletes your content. It backs up an existing `~/.zshrc` (to `~/.zshrc.pre-zshconf`) and writes a 3-line stub; appends a marked block to `~/.zprofile` and a marked one-line stub to `~/.bash_profile` (or `~/.profile`), both sourcing the repo's `login-path.sh`; and creates the overlay directory. It does not install tools or migrate anything. First startup clones Zinit (pinned) and the plugins.

Optional extras:

```sh
brew bundle --file "$ZSHCONF/Brewfile"   # the tools the config integrates with (works from any directory)
curl -fsSL https://mise.run | sh         # mise, the way its docs recommend (not via Homebrew)
```

mise comes from [its install script](https://mise.jdx.dev/installing-mise.html), as its docs recommend; it lands in `~/.local/bin`. Switching from a Homebrew mise: `brew uninstall mise && mise reshim`.

## Update

```sh
zshconf-update      # git pull --ff-only + recompile, then: exec zsh
```

It refuses to pull over local edits or commits: the core is sourced, never edited. `sysup` runs it as one of its lanes.

`sysup` also updates Homebrew and Zinit, refreshes completions, prints a per-lane summary, and returns nonzero if any update fails.

Want *everything* updated — mise runtimes, rustup, npm globals, editor extensions, macOS updates, and more? Install [Topgrade] (it's in the `Brewfile`) and run `sysup --topgrade`: it updates this repo, runs plain `topgrade` (which also covers Homebrew and Zinit), then refreshes completions. To make it your default:

```zsh
# ~/.config/zsh/local.d/updates.zsh
export SYSUP_BACKEND=topgrade
```

The repo passes no Topgrade config — tool defaults apply, and you tune it in your own `~/.config/topgrade.toml` (created by Topgrade on first run), e.g. `disable = ["containers"]` under `[misc]`. Topgrade asks before risky steps such as macOS system updates. `sysup --native` always runs the original lanes.

## Make it yours (the overlay)

All personal and machine-specific config lives in `${XDG_CONFIG_HOME:-~/.config}/zsh/`, outside this repo:

- **`local.d/*.zsh`** — drop-ins sourced after the repo, in name order. Override anything; one concern per file. A plugin you add with `wait'1'` or later that defines widgets needs `atload'_zsh_autosuggest_bind_widgets'` (see [Architecture](docs/ARCHITECTURE.md#turbo-tiers)).
- **`env.zsh`** — exports GUI apps must see. Zed, VS Code and friends read a login zsh's environment, which never runs `~/.zshrc`; `env.zsh` is sourced from `~/.zprofile` and from `init.zsh`, once. Env only, zsh syntax.
- **`pre.zsh`** — sourced before the core, for values it reads at startup (e.g. `LS_COLORS`). Rarely needed.

Why the login profiles? `zsh -lc` (GUI apps) and `bash -lc` (agent tools, editors, git hooks) never reach `~/.zshrc`, and macOS `path_helper` puts `/usr/bin` — system Ruby, Python — ahead of the PATH they inherited. The stubs source `login-path.sh`, which restores Homebrew and mise for those shells only.

The `zshconf-edit` helper opens overlay files in your `$VISUAL`/`$EDITOR` — no need to remember the paths:

```sh
zshconf-edit          # list your overlay files
zshconf-edit work     # create/edit ~/.config/zsh/local.d/work.zsh
zshconf-edit env      # edit env.zsh (exports GUI apps must see)
zshconf-edit pre      # edit pre.zsh
```

Examples:

```zsh
# ~/.config/zsh/local.d/editor.zsh
export EDITOR=vim

# ~/.config/zsh/local.d/work.zsh — only on work machines
[[ "$HOST" == work-* ]] || return 0
export SOME_INTERNAL_URL=...
```

The overlay can be its own private git repo. Secrets belong in `env.zsh` (`chmod 600`) or a secret manager, never in either repo.

Your own Starship config? If `~/.config/starship.toml` exists (or `STARSHIP_CONFIG` is set), it wins; otherwise the repo's config is used.

## Uninstall

```sh
rm ~/.zshrc
mv ~/.zshrc.pre-zshconf ~/.zshrc        # if it exists
# remove the marked zshconf blocks from ~/.zprofile and ~/.bash_profile (or ~/.profile)
rm -rf ~/.local/share/zshconf
```

Your overlay (`~/.config/zsh/`) is yours; keep or delete it.

## Development

```sh
just test        # full suite (what CI runs)
just test-bare   # CI's toughest cell locally: bare Linux in Docker
```

See [docs/CHEATSHEET.md](docs/CHEATSHEET.md) for every command and keybinding, [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for how the pieces fit, and [CONTRIBUTING.md](CONTRIBUTING.md) for the scope policy.

## License

[MIT](LICENSE).

[Zinit]: https://github.com/zdharma-continuum/zinit
[Starship]: https://starship.rs
[Topgrade]: https://github.com/topgrade-rs/topgrade
[fzf-tab]: https://github.com/Aloxaf/fzf-tab
