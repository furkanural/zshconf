#!/usr/bin/env zsh
# Tab completion for the other repo functions. The full config binds each
# function to its completer; real Tab presses offer the right candidates.
# lsof- and rg-dependent cases skip when the tool is missing (bare CI cell).
source "${0:A:h}/lib.zsh"

t_make_zdot "$TWORK/zdot"
mkdir -p "$TWORK/xdg"

out=$(t_boot_tiers "$TWORK/zdot" "$TWORK/xdg" '
print -r -- "COMPS ${_comps[gbclean]} ${_comps[zshconf-edit]} ${_comps[portkill]} ${_comps[portprocess]} ${_comps[killnamed]} ${_comps[rgg]} ${_comps[cdl]} ${_comps[mkcd]}"')
t_eq "config binds every completer" "$(grep '^COMPS ' <<< "$out")" \
  "COMPS _gbclean _zshconf-edit _portkill _portkill _killnamed _rgg _cdl _cdl"

# Fixture overlay with one drop-in; a dir + file to tell directories apart.
overlay="$TWORK/overlay"
mkdir -p "$overlay/local.d" "$TWORK/cwd/somedir"
: > "$overlay/local.d/work.zsh"
: > "$TWORK/cwd/somefile"
t_comp_setup "export ZSHCONF_LOCAL='$overlay'; cd '$TWORK/cwd'"

t_complete 'gbclean -'
t_match "gbclean offers --force" "$screen" "*--force*"
t_match "gbclean offers --help"  "$screen" "*--help*"

t_complete 'zshconf-edit '
t_match   "zshconf-edit offers pre"            "$screen" "*pre*"
t_match   "zshconf-edit offers env"            "$screen" "*env*"
t_match   "zshconf-edit offers local.d names"  "$screen" "*work*"
t_nomatch "zshconf-edit offers no files"       "$screen" "*somefile*"

t_complete 'cdl '
t_match   "cdl offers directories" "$screen" "*somedir*"
t_nomatch "cdl skips files"        "$screen" "*somefile*"

t_complete 'mkcd '
t_match   "mkcd offers directories" "$screen" "*somedir*"
t_nomatch "mkcd skips files"        "$screen" "*somefile*"

# A uniquely named process to find by name. `exec -a` renames sleep's argv[0]
# (copying the binary instead gets it killed by macOS code signing).
zsh -c 'exec -a zshconfprobe sleep 30' &
probe_pid=$!
t_complete 'killnamed zshconfpr'
t_match "killnamed completes process names" "$screen" "*killnamed zshconfprobe*"

if (( $+commands[lsof] && $+commands[python3] )); then
  # A listener on a free port, so there is a known port to complete.
  python3 -c '
import socket, time
s = socket.socket(); s.bind(("127.0.0.1", 0)); s.listen()
print(s.getsockname()[1], flush=True); time.sleep(30)' > "$TWORK/port" &
  listener_pid=$!
  for _ in {1..50}; do [[ -s "$TWORK/port" ]] && break; sleep 0.1; done
  port="$(<$TWORK/port)"
  t_complete "portkill ${port[1,-2]}"
  t_match "portkill completes listening ports" "$screen" "*portkill $port*"
  t_complete "portprocess ${port[1,-2]}"
  t_match "portprocess shares the completer"   "$screen" "*portprocess $port*"
  kill $listener_pid 2>/dev/null
else
  print -r -- "  skip: portkill (needs lsof + python3)"
fi
kill $probe_pid 2>/dev/null

if (( $+commands[rg] )) && [[ -n ${^fpath}/_rg(#qN) ]]; then
  t_complete 'rgg --hid'
  t_match "rgg reuses ripgrep options" "$screen" "*rgg --hidden*"
else
  t_complete 'rgg some'
  t_match "rgg falls back to files" "$screen" "*somefile*"
fi
t_done
