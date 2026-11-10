# Architecture

A sourced core plus an overlay for everything personal. Updates are always a fast-forward pull because user changes never touch tracked files.

```
~/.zshrc (stub)                 ~/.zprofile (block)          ~/.bash_profile | ~/.profile (stub)
  └── init.zsh                    ├── login-path.sh            └── login-path.sh
        ├── ~/.config/zsh/pre.zsh └── ~/.config/zsh/env.zsh
        ├── ~/.config/zsh/env.zsh
        ├── modules/*.zsh
        ├── modules/tools/*.zsh
        ├── modules/aliases/*.zsh
        ├── modules/os/{darwin,linux}.zsh
        ├── functions/*   (autoloaded)
        ├── completions/_*
        └── ~/.config/zsh/local.d/*.zsh   (last)
```

## Load order

`init.zsh` is an explicit manifest; each constraint is commented where it is enforced:

1. `path` before any `$+commands[...]` guard.
2. Zinit before `mise` activation (Zinit prepends its `polaris/bin` and `polaris/sbin` directories to PATH), then Starship.
3. `LS_COLORS` before `completion-styles.zsh` — the `list-colors` zstyle expands it at definition time. This is why `pre.zsh` exists.
4. Compdump hygiene and `zmodload zsh/complist` before Tier 1's compinit.
5. `local.d` last.

Modules are sourced at top level, never inside a function, so `typeset -U path` acts on globals.

## Turbo tiers

All plugins load via Zinit turbo after the first prompt:

- **Tier 1** (`wait'0a'`): compinit (`-C`), completions, fzf-tab.
- **Tier 2** (`wait'0b'`): OMZ git, history-substring-search, fast-syntax-highlighting, then autosuggestions.
- **Tier 3** (`wait'1'`): docker-compose, ruby, rails, extract, eza, command-not-found.

Autosuggestions bind widgets twice (after Tier 2 and after Tier 3) instead of on every prompt (`ZSH_AUTOSUGGEST_MANUAL_REBIND`). An overlay plugin with `wait'1'` or later that defines widgets needs `atload'_zsh_autosuggest_bind_widgets'`.

Every zinit idiom lives in `modules/plugins.zsh`; other modules use only `_zinit_evalcache`.

Zinit is cloned on first run and reset to a pinned tag, then floats with `zinit self-update`. Plugins float at HEAD.

## Precedence

- **Starship config:** `$STARSHIP_CONFIG` → `~/.config/starship.toml` → repo default. Without starship, a minimal `PS1`.
- **Overlay:** `pre.zsh` → core → `local.d/*.zsh` in name order.
- **env.zsh:** sourced from `~/.zprofile` (login zsh, incl. GUI apps) and `init.zsh`, once per shell.
- **login-path.sh:** sourced from `~/.zprofile` and the bash/sh profile. Restores Homebrew and mise shims ahead of macOS `path_helper`'s `/usr/bin` for login shells that never reach `~/.zshrc` (`zsh -lc`, `bash -lc`). POSIX sh, no forks beyond mise, guarded. `path.zsh` remains the authority in interactive zsh.

## Bytecode

`init.zsh` background-compiles stale `.zwc` files; `source` ignores a `.zwc` older than its source. `zshconf-update` compiles eagerly. `*.zwc` is gitignored.

## OS support

macOS first-class, Linux CI-tested, WSL expected to behave like Linux, BSD out of scope. Feature detection over OS detection: `(N)` globs, `$+commands`, one `$OSTYPE` dispatch in the manifest selecting `modules/os/`.

A literal `/home/linuxbrew` path stalls ~50 ms on macOS (autofs); startup files use `/home/[l]inuxbrew`, and the parse test enforces it.

PATH is ours first, inherited second: `path.zsh` appends the parent's `$path`, and `typeset -U` keeps our order for anything both define.

## Testing

`tests/run.zsh`: parse gate, stderr-clean smoke boot in a fixture `ZDOTDIR`, tier convergence with prompt cycles, overlay contract, installer scenarios in a sandbox `HOME`, function tests against git fixtures, Tab-completion tests in a pty. CI runs ubuntu/macos × bare/full plus a report-only benchmark.
