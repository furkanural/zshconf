#!/usr/bin/env zsh
# Test runner: zsh tests/run.zsh
# CI runs exactly this; keep it runnable on a laptop with no arguments.
cd "${${(%):-%N}:A:h:h}"

# Scrub state leaked from a parent shell that runs this very config.
unset HEROKU_AC_ANALYTICS_DIR HEROKU_AC_COMMANDS_PATH STARSHIP_CONFIG STARSHIP_SESSION_KEY \
      ZSHCONF LS_COLORS EDITOR VISUAL BAT_THEME BAT_STYLE MANPAGER T_SENT \
      FZF_DEFAULT_OPTS FZF_DEFAULT_COMMAND FZF_CTRL_T_COMMAND FZF_ALT_C_COMMAND
export TERM="${TERM:-xterm-256color}"

# Cold start (CI): zinit + turbo plugins clone from the network on first
# boot, which would pollute the stderr-clean assertions. Warm up once.
if [[ ! -d "$HOME/.local/share/zinit/plugins/zsh-users---zsh-autosuggestions" ]]; then
  print "== warmup: first boot clones zinit + plugins (network) =="
  warm="$(mktemp -d)"
  print -r -- "export ZSHCONF=\"$PWD\"
source \"\$ZSHCONF/init.zsh\"" > "$warm/.zshrc"
  { for _ in {1..50}; do print 'sleep 0.3'; done; print 'exit' } | \
    ZDOTDIR="$warm" XDG_CONFIG_HOME="$warm/xdg" zsh -i >/dev/null 2>&1
  rm -rf "$warm"
fi

typeset -i fail=0 total=0
for t in tests/[0-9]*.zsh; do
  (( total++ ))
  print -r -- "== $t =="
  if zsh "$t"; then
    print -r -- "PASS $t"
  else
    print -r -- "FAIL $t"
    fail=1
  fi
done

if (( fail )); then
  print -r -- "==> FAILURES"
else
  print -r -- "==> ALL PASS ($total files)"
fi
exit $fail
