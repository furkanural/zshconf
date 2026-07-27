# Contributing

Thanks for looking! A few things to know before opening a PR.

## Scope policy (please read this one)

This project is an **opinionated config, not a framework**. That means:

- **Welcome:** bug fixes, portability fixes (especially Linux), performance improvements, better degradation when a tool is missing, test coverage, doc corrections.
- **Not accepted:** configuration knobs ("add an option to disable X"), personal-preference changes to the shipped defaults, plugin additions that serve one stack. That's what the overlay is for — anything you'd ask a knob for can live in your `~/.config/zsh/local.d/` (see the README).

If you're unsure which side of the line an idea falls on, open an issue first — it's a friendly conversation, not a gate.

## Ground rules for changes

- Read `docs/ARCHITECTURE.md` first — load order in `init.zsh` is load-bearing, and each constraint is commented where it's enforced.
- Feature detection over OS detection. `$OSTYPE` appears in exactly one place (the manifest's dispatch); OS conditionals inside generic modules will be asked to move to `modules/os/`.
- Zinit idioms stay in `modules/plugins.zsh` (containment rule).
- New user-facing functions: one file in `functions/`, autoload style (bare body, no wrapper).

## Tests

```sh
just test        # full suite — must pass
just test-bare   # bare-Linux cell in Docker; run it if you touched guards
```

CI runs the suite on ubuntu/macos × bare/full. If you add behavior, add an assertion; if you fix a bug, add the assertion that would have caught it.
