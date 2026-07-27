# Architecture

The design in one sentence: **a layered core that is sourced, never edited, with an overlay seam for everything personal** — updates are always a fast-forward pull because user changes never touch tracked files.

```
~/.zshrc (3-line stub, user-owned)
  └── $ZSHCONF/init.zsh (the manifest)
        ├── ~/.config/zsh/pre.zsh          (overlay pre-hook, optional)
        ├── modules/*.zsh                  (lifecycle phases, strict order)
        ├── modules/tools/*.zsh            (feature-detected integrations)
        ├── modules/aliases/*.zsh          (by domain)
        ├── modules/os/{darwin,linux}.zsh  (the ONLY $OSTYPE dispatch)
        ├── functions/* → autoloaded       (one file per function)
        └── ~/.config/zsh/local.d/*.zsh    (overlay drop-ins, sourced LAST)
```

## Load order is load-bearing

`init.zsh` is an explicit manifest — not a numbered glob — so every ordering constraint is documented at the line that enforces it. The hard constraints:

1. `path` before any `$+commands[...]` guard (which is nearly everything).
2. `mise` before Starship, so the prompt sees shimmed tools.
3. `LS_COLORS` before `completion-styles.zsh` — the `list-colors` zstyle expands `${(s.:.)LS_COLORS}` **at definition time**, not at completion time. This is also why `LS_COLORS` is the one value the overlay must set in `pre.zsh` rather than `local.d`.
4. zcompdump hygiene (stale-dump deletion) before `zicompinit` fires.
5. `zmodload zsh/complist` before compinit runs.
6. Helper functions defined before the code that references them (`_zinit_evalcache` before `tools/fzf.zsh`, etc.).
7. eza zstyles before Tier 3 loads `OMZP::eza`.
8. The overlay's `local.d` last, so it can override anything.

Modules are sourced at **top level**, never inside a function — `typeset -U path` and friends inside a function would create function-locals instead of acting on the shell's globals.

## The turbo tiers

All plugins load via Zinit's turbo mode, _after_ the first prompt paints:

- **Tier 0a** — anything needed before the first Tab press: compinit (`-C`, trusting the compdump the hygiene pass validated), completions, fzf-tab.
- **Tier 0b** — interactive UX: OMZ git lib/aliases, history-substring search, autosuggestions, syntax highlighting.
- **Tier 1** — everything that can wait a second: docker-compose, ruby, rails, extract, eza, command-not-found.

Deferred loading has a subtle consequence the overlay exploits: overlay zstyles set at source time still land _before_ Tier 2/3 plugins read them.

**Containment rule:** every zinit-specific idiom (ices, snippets, the null-plugin evalcache trick) lives in `modules/plugins.zsh`. Other modules interact with zinit only through `_zinit_evalcache`. If the project ever migrates plugin managers, the blast radius is one file.

**Bootstrap pin (TOFU):** a fresh machine clones Zinit and resets to a pinned release tag — first-run code execution is deterministic. The reset stays on the default branch so `zinit self-update` keeps working; after first install the pin is trust-on-first-use, and plugins float at HEAD (documented trade-off — a short, well-known plugin list in exchange for not maintaining a dozen version pins).

## Precedence chains

- **Starship config:** explicit `$STARSHIP_CONFIG` → user's `~/.config/starship.toml` → repo default. No starship → minimal fallback `PS1`.
- **Overlay:** `pre.zsh` (before core; startup-consumed values only) → core → `local.d/*.zsh` in name order (winner takes all). Only values the core reads during startup need `pre.zsh`; everything else overrides fine from `local.d` because it's read at call time.

## Bytecode

`init.zsh` ends by background-compiling any module whose `.zwc` is stale. This is safe because `source` uses a `.zwc` only when it is at least as new as its source — stale bytecode is silently ignored, never wrongly used. `zshconf-update` recompiles eagerly after a pull. `*.zwc` is gitignored.

## OS support

Tiered: macOS is first-class (daily-driven); Linux is supported and CI-tested; WSL should behave like Linux (untested); BSD is out of scope. The mechanism: **feature detection over OS detection** — candidate paths with `(N)` glob qualifiers, `$+commands` guards, `col(1)` detection — and a single `$OSTYPE` dispatch in the manifest selecting one leaf module (`modules/os/`). OS conditionals inside generic modules are a review reject.

## Testing

`tests/run.zsh` (CI parity via `just test`): a parse gate over every file; an stderr-clean smoke boot in a fixture `ZDOTDIR` (an empty stderr catches most real regressions); a tier-convergence test that feeds prompt cycles to an interactive shell so turbo actually fires; overlay-contract tests; installer scenarios against a sandbox `HOME`; function tests against git fixtures. CI runs a 2×2 matrix — ubuntu/macos × bare/full — where the bare cells exercise every degradation guard, plus a report-only zsh-bench job.
