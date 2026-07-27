# Shared test helpers. Test files source this, use t_* asserts, end with t_done.
REPO="${${(%):-%N}:A:h:h}"
TWORK="$(mktemp -d)"
trap 'rm -rf "$TWORK"' EXIT
typeset -g T_FAIL=0

t_eq() {  # t_eq <desc> <actual> <expected>
  if [[ "$2" == "$3" ]]; then
    print -r -- "  ok: $1"
  else
    print -r -- "  FAIL: $1 — got '$2', want '$3'"
    T_FAIL=1
  fi
}

t_match() {  # t_match <desc> <haystack> <glob-pattern>
  if [[ "$2" == ${~3} ]]; then
    print -r -- "  ok: $1"
  else
    print -r -- "  FAIL: $1 — '$2' does not match '$3'"
    T_FAIL=1
  fi
}

t_done() { exit $T_FAIL }

# t_make_zdot <dir>: fixture ZDOTDIR whose .zshrc is the installer's stub.
t_make_zdot() {
  mkdir -p "$1"
  print -r -- "export ZSHCONF=\"$REPO\"
source \"\$ZSHCONF/init.zsh\"" > "$1/.zshrc"
}

# t_boot <zdot> <xdg> <code>: eager interactive boot (no prompt cycles —
# turbo tiers stay queued). stdout returned; stderr in $TWORK/stderr.
t_boot() {
  ZDOTDIR="$1" XDG_CONFIG_HOME="$2" zsh -i -c "$3" 2>"$TWORK/stderr"
}

# t_boot_tiers <zdot> <xdg> <probe>: interactive boot fed prompt cycles so
# zinit's turbo tiers fire, then runs the probe. stderr contains prompt
# paints + the no-TTY zle artifact; don't assert on it here.
t_boot_tiers() {
  { for _ in {1..30}; do print 'sleep 0.3'; done
    print -r -- "$3"
    print 'exit'
  } | ZDOTDIR="$1" XDG_CONFIG_HOME="$2" zsh -i 2>"$TWORK/stderr-tiers"
}
