# Shared test helpers: t_* asserts, fixtures, boot and completion harnesses.

# Ubuntu's global zshrc runs compinit and pollutes stderr on CI runners.
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

# t_make_zdot <dir>: fixture ZDOTDIR with the installer's stub.
t_make_zdot() {
  mkdir -p "$1"
  print -r -- "export ZSHCONF=\"$REPO\"
source \"\$ZSHCONF/init.zsh\"" > "$1/.zshrc"
}

# t_boot <zdot> <xdg> <code>: eager boot, tiers still queued. stderr → $TWORK/stderr.
t_boot() {
  ZDOTDIR="$1" XDG_CONFIG_HOME="$2" zsh -i -c "$3" 2>"$TWORK/stderr"
}

# t_boot_tiers <zdot> <xdg> <probe>: boot and feed prompt cycles until the
# last Tier 3 atload has run (_autosuggest_rebind unsets itself), then run
# the probe. Bounded at 60 s. stderr has prompt noise; assert absence of a
# substring, never emptiness.
t_boot_tiers() {
  { for _ in {1..200}; do
      print '(( ${+functions[_autosuggest_rebind]} )) && sleep 0.3'
    done
    print -r -- "$3"
    print 'exit'
  } | ZDOTDIR="$1" XDG_CONFIG_HOME="$2" zsh -i 2>"$TWORK/stderr-tiers"
}

# Completion harness: real Tab presses in a minimal pty shell (compinit +
# this repo's completions, no fzf-tab). Reads are bounded so CI cannot hang.
#   t_comp_setup [extra .zshrc lines]   once per file
#   t_complete <input>                  types <input> + Tab, sets $screen
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
  # env -u FPATH: don't inherit the developer's completers.
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
