# Contributing

## Scope

An opinionated config, not a framework.

- **Welcome:** bug fixes, portability (especially Linux), performance, degradation when a tool is missing, tests, doc fixes.
- **Not accepted:** configuration knobs, personal-preference changes to the defaults, plugins that serve one stack. That is what the overlay (`~/.config/zsh/local.d/`) is for.

Unsure? Open an issue first.

## Rules

- Read `docs/ARCHITECTURE.md`; load order in `init.zsh` is load-bearing.
- Feature detection over OS detection. `$OSTYPE` appears once, in the manifest; OS conditionals go in `modules/os/`.
- Zinit idioms stay in `modules/plugins.zsh`.
- New functions: one autoload-style file in `functions/`, with a `#compdef` completer in `completions/` if it takes options.
- Comments explain what the code cannot: a non-obvious constraint or trap. No history, no restating the code.

## Tests

```sh
just test        # full suite, must pass
just test-bare   # bare Linux in Docker; run it if you touched guards
```

New behavior gets an assertion; a bug fix gets the assertion that would have caught it.

`just install-hooks` adds a fast pre-commit check (syntax, filenames, size, secrets).
