# Cheat Sheet

Every command, alias, function, and keybinding this config adds. Tools are feature-detected — anything whose tool isn't installed simply doesn't exist (install the full set with `brew bundle`).

## Navigation

| Command | What it does |
|---|---|
| `..` / `...` / `....` | Go up 1 / 2 / 3 directories |
| `q` | Exit the shell |
| `reload` | Restart zsh (`exec zsh`) |
| `cdl <dir>` | `cd` into a directory and list it |
| `mkcd <dir>` | Create a directory (with parents) and `cd` into it |
| `tmpcd` | Create a fresh temp directory and `cd` into it |
| `z <pattern>` | Jump to a frecent directory (zoxide) |
| `ls` / `ll` / `la` / `l` | eza with icons, git status, dirs-first (falls back to plain `ls` flags without eza) |
| `showpath` / `showfpath` | Print `$PATH` / `$FPATH`, one entry per line |

Bare directory names also work (`AUTO_CD`), and every `cd` pushes the dir stack (`dirs -v`, `popd`).

## Files & search

| Command | What it does |
|---|---|
| `bak <file>...` | Timestamped backup copy: `file.bak.YYYYMMDD_HHMMSS` |
| `sizeof <path>` | Disk usage, human-readable (`du -sh`) |
| `fdf` / `fdd` / `fda` / `fdx` | fd: files only / dirs only / include hidden / executables |
| `rgg <pattern> [path]` | ripgrep with hidden files, smart-case, line numbers, `.git` skipped |
| `rgi` / `rgf` / `rgl` / `rgc` / `rga` | rg: ignore case / match filenames / files-only / match counts / search everything |
| `kat <file>` | `bat` plain output, no paging or decorations |
| `ccat <file>` | `bat` with line numbers and grid, no paging |
| `x <archive>` | Extract any archive (OMZ `extract` plugin) |

## Git

Day-to-day aliases (`gst`, `gco`, `gp`, `gl`, …) come from the OMZ git plugin. On top of those:

| Command | What it does |
|---|---|
| `gbclean` | Delete local branches merged into HEAD (skips main/master/develop, current, worktree branches) |
| `gbclean --force` | Force-delete local branches, even unmerged ones |
| `ghopen [path\|issue\|-b branch]` | Open the repo / file / issue / branch in the browser (`gh browse`) |
| `ghpr` | Open the current branch's PR in the browser; creates a draft PR if none exists |

## System & processes

| Command | What it does |
|---|---|
| `ports` | All listening TCP ports (`lsof`) |
| `portprocess <port>` | Which process holds a port |
| `portkill <port>` | SIGTERM whoever holds a port |
| `killnamed <name>` | SIGTERM all processes matching a name (case-insensitive) |
| `df` / `du` / `grep` | Human-readable / colored defaults |

### macOS only

| Command | What it does |
|---|---|
| `f` | Open current directory in Finder |
| `ip` | Public IP address |
| `localip` | LAN IP (en0) |
| `free` | Memory summary via `top` |

### Linux only

| Command | What it does |
|---|---|
| `f` | Open current directory (`xdg-open`) |
| `myip` | Public IP address |
| `localip` | LAN IP |

## Homebrew

| Command | What it does |
|---|---|
| `brewclean` | `brew cleanup && brew autoremove` |
| `brewlist` | List installed formulae |
| `brewdeps` | Dependency tree of everything installed |

## Docker

| Command | What it does |
|---|---|
| `dps` / `dpsa` | Running / all containers |
| `di` | Images |
| `dlogs <c>` | Follow container logs |
| `dsh <c> <cmd>` | `docker exec -it` |
| `dprune` | `docker system prune -a` (still prompts) |
| `dstop` | Pick container(s) to stop via fzf (Tab = multi-select) |
| `drm` | Pick container(s) to remove via fzf |

## fzf

| Keybinding | What it does |
|---|---|
| `Ctrl+R` | Fuzzy history search |
| `Ctrl+T` | Insert a file path (fd-powered, respects `.gitignore`) |
| `Alt+C` | `cd` into a picked directory |
| `Ctrl+U` / `Ctrl+D` (inside fzf) | Scroll preview half-page up/down |

Tab completion opens an fzf menu with file previews (fzf-tab).

## Model presets

Switch Claude Code / Anthropic-API tools between endpoints and models. Presets are `chmod 600` env files in `~/.config/cliproxy-presets/`, outside any repo.

| Command | What it does |
|---|---|
| `modelpreset` | List presets |
| `modelpreset <name>` | Load a preset into the current shell |
| `modelpreset add <name>` | Create a preset (interactive; token input hidden) |
| `modelpreset edit <name>` | Open a preset in `$EDITOR` |
| `modelpreset remove <name>` | Delete a preset (asks first) |

## Maintenance

| Command | What it does |
|---|---|
| `zshconf-update` | Fast-forward-pull this repo + recompile bytecode (stops on local edits — those belong in `~/.config/zsh/local.d/`) |
| `zshconf-edit [pre\|<name>]` | List overlay files, or open `local.d/<name>.zsh` / `pre.zsh` in `$VISUAL`/`$EDITOR` (created with a guidance header if missing) |
| `sysup` | Update everything: this repo, Homebrew, Zinit plugins, completion dump — then `exec zsh` |
| `just test` | Full test suite (what CI runs) |
| `just parse` | Quick syntax gate only |
| `just test-bare` | CI's toughest cell locally: bare Linux in Docker |
| `just install-hooks` | Opt into the pre-commit hook |

## Keybindings

Emacs mode, plus:

| Keys | What it does |
|---|---|
| `Alt+←` / `Alt+→` | Move by word |
| `↑` / `↓` (or `Ctrl+P` / `Ctrl+N`) | History-substring search — type a prefix, then scroll matches |
| `Ctrl+Space` | Accept autosuggestion |
| `Alt+H` / `Alt+U` | `cd ~` / `cd ..` |
| `Ctrl+U` / `Ctrl+K` | Kill to line start / end |
| `Ctrl+W` / `Ctrl+Y` | Kill word backward / yank |
| `Ctrl+L` | Clear screen |

## History & safety

- 50k shared history with timestamps; duplicates and noise (`ls`, `cd`, `pwd`, …) filtered out; a leading space keeps a command out of history.
- `noclobber`: `>` won't overwrite files — use `>!` to force.
- `rm *` waits 10 seconds before executing.
- `!!` expansions are shown for confirmation before running.
