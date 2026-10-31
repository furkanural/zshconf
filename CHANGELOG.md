# Changelog

Notable, user-visible changes only. `main` is rolling; update with `zshconf-update`.

## Unreleased

- Fix: `zsh-syntax-highlighting: unhandled ZLE widget 'autosuggest-accept'` printed on every start since the Tier 2 reorder — `Ctrl+Space` was bound before the widget existed; it is now bound alongside `Ctrl+\` once autosuggestions load. The tier test asserts a clean stderr from plugins.
- **Faster startup on macOS (~190 → ~135 ms):** Linuxbrew candidate paths no longer trigger the `/home` autofs automounter (~50 ms per shell).
- **Faster prompts (~20 ms less per prompt):** zsh-autosuggestions no longer re-wraps every widget on each prompt (`ZSH_AUTOSUGGEST_MANUAL_REBIND`, bound once after each relevant tier). Suggestion lookups stop once the line exceeds 200 chars (pasted text).
- PATH entries inherited from the parent process (Ghostty, nix, editor terminals) are kept, after this config's own entries. Previously they were dropped.
- `git log HEAD^` and friends work: `git` is aliased to `noglob git` (`EXTENDED_GLOB` made `^` a glob).
- Home / End / Delete keys bound for every common terminal encoding (previously garbage under ssh/tmux/some `$TERM`s); `↑`/`↓` history-substring search also in application cursor mode.
- `Ctrl+X Ctrl+E` edits the command line in your editor. Word motion/deletion (`Ctrl+W`, `Alt+←`) stops at `/` and `=`.
- Options: `HIST_FCNTL_LOCK`, `HIST_EXPIRE_DUPS_FIRST`, `NO_FLOW_CONTROL` (`Ctrl+S`/`Ctrl+Q` no longer freeze the terminal), `COMBINING_CHARS`.
- `docker` Tab completion, generated in the background when missing or stale.
- Linux: Linuxbrew's zsh completions are on `fpath`. Heroku autocomplete cache found under XDG too.
- bat man pages: `MANROFFOPT=-c` fixes garbled output with groff ≥ 1.23.
- fzf-tab: directory preview for `z` too. Zinit bootstrap pin bumped to v3.17.1.

- Tab completion for `sysup` (`--native`, `--topgrade`, `--help`), from a new `completions/` directory on `fpath`.
- Tab completion for more functions: `portkill`/`portprocess` (listening ports with their process), `zshconf-edit` (`pre`, `env`, existing drop-ins), `killnamed` (process names), `rgg` (ripgrep's options), `cdl`/`mkcd` (directories only), `gbclean` (`--force`, `--help`).
- `zshconf-update` now refuses to pull when the repo has uncommitted edits (previously `--ff-only` only caught local commits, so edits to files upstream didn't touch survived silently).
- `sysup` now skips missing Homebrew/Zinit cleanly, prints a per-lane summary, and returns nonzero on failures.
- `sysup --topgrade` (or `SYSUP_BACKEND=topgrade`) runs plain `topgrade` with its own defaults, configured via `~/.config/topgrade.toml`. Topgrade added to the `Brewfile`.
- `zshconf-edit` — list overlay files and open `local.d` drop-ins / `pre.zsh` in `$VISUAL`/`$EDITOR`, creating them with a guidance header.
- Keybindings: `Ctrl+←`/`Ctrl+→` word jump, `Ctrl+\` toggles autosuggestions, `Ctrl+F` fzf file picker without hidden files.
- fzf: bat preview on `Ctrl+T`.
- `gadog` alias — `git log --all --decorate --oneline --graph`.
- History raised to 100k entries.

Initial public structure:

- Manifest + modules split of the original single-file config, with the load-order constraints documented in `init.zsh`.
- Local overlay: `~/.config/zsh/pre.zsh` + `~/.config/zsh/local.d/*.zsh`.
- `install.sh` (stub + backup + overlay dir) and `zshconf-update`.
- Starship config in-repo (whitelist `format`), with user-config precedence and a fallback prompt.
- Linux support: linuxbrew paths, `modules/os/` split, feature-detected `MANPAGER`; fixed `ip`/`free` alias shadowing on Linux.
- Zinit bootstrap pinned to a release tag (TOFU).
- Test suite + 2×2 CI matrix + report-only zsh-bench job.
- Android SDK + Maestro on PATH: `ANDROID_HOME` export (pre-set value respected, e.g. from `pre.zsh`) with `(N)`-guarded `emulator`/`platform-tools`/`~/.maestro/bin` entries.
