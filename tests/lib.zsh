# Shared test helpers. Test files source this, use t_* asserts, end with t_done.

# Ubuntu's /etc/zsh/zshrc runs a bare `compinit` before ~/.zshrc; on hosts
# with group/world-writable fpath dirs (e.g. GitHub runners) it aborts
# non-interactively and pollutes stderr, failing the stderr-empty asserts.
# The config owns completion setup (Tier 1 zicompinit) — skip the global one.
export skip_global_compinit=1

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

t_nomatch() {  # t_nomatch <desc> <haystack> <glob-pattern>
  if [[ "$2" != ${~3} ]]; then
    print -r -- "  ok: $1"
  else
    print -r -- "  FAIL: $1 — '$2' unexpectedly matches '$3'"
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
# paints + the no-TTY zle artifact, so never assert it is empty — only
# that it lacks a specific plugin complaint (t_nomatch on a substring).
# 45 cycles: piped, zinit loads roughly one turbo item per prompt, and
# Tier 3 (wait'1', six snippets) needs well over 30 to drain.
t_boot_tiers() {
  { for _ in {1..45}; do print 'sleep 0.3'; done
    print -r -- "$3"
    print 'exit'
  } | ZDOTDIR="$1" XDG_CONFIG_HOME="$2" zsh -i 2>"$TWORK/stderr-tiers"
}

# ── Completion harness: real Tab presses in a minimal pty shell (compinit +
# the repo's completions/ only — no fzf-tab or menu UI), so assertions are
# about the completers themselves. Reads are non-blocking with bounded
# waits: CI fails instead of hanging.
#   t_comp_setup [extra .zshrc lines]   once per test file
#   t_complete <input>                  type <input> + Tab; sets $screen
# Brew completion dirs, as in modules/path.zsh — tools' own completers (_rg)
# live here. Tests decide "is _rg installed?" from this same list.
T_BREW_FPATH=(
  /opt/homebrew/share/zsh/site-functions(N)
  /usr/local/share/zsh/site-functions(N)
  /home/linuxbrew/.linuxbrew/share/zsh/site-functions(N)
)

t_comp_setup() {
  mkdir -p "$TWORK/ptyzdot"
  print -r -- "PS1='READY> '
fpath=(\"$REPO/completions\" ${(q)T_BREW_FPATH[@]} \$fpath)
autoload -Uz compinit && compinit -u -d \"$TWORK/ptyzdot/.zcompdump\"
zstyle ':completion:*' list-separator '--'
setopt autolist nolistbeep
$1" > "$TWORK/ptyzdot/.zshrc"
  zmodload zsh/zpty
}

t_complete() {
  # env -u FPATH: an inherited FPATH (e.g. from the developer's own shell)
  # would leak completers in and make local runs disagree with CI.
  zpty tcomp "env -u FPATH ZDOTDIR='$TWORK/ptyzdot' TERM=dumb COLUMNS=200 zsh -i"
  screen=""
  local chunk
  integer i
  for (( i = 0; i < 100; i++ )); do
    zpty -rt tcomp chunk && screen+="$chunk"
    [[ "$screen" == *'READY> '* ]] && break
    sleep 0.1
  done
  screen=""
  zpty -n -w tcomp "$1"$'\t'
  for (( i = 0; i < 30; i++ )); do
    zpty -rt tcomp chunk && screen+="$chunk"
    sleep 0.1
  done
  zpty -d tcomp
  screen="${screen//$'\r'/}"
}
