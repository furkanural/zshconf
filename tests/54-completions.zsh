#!/usr/bin/env zsh
# Tab completion for the repo functions; lsof/rg cases skip when absent.
source "${0:A:h}/lib.zsh"

t_make_zdot "$TWORK/zdot"
mkdir -p "$TWORK/xdg"

out=$(t_boot_tiers "$TWORK/zdot" "$TWORK/xdg" '
print -r -- "COMPS ${_comps[gbclean]} ${_comps[zshconf-edit]} ${_comps[portkill]} ${_comps[portprocess]} ${_comps[killnamed]} ${_comps[rgg]} ${_comps[cdl]} ${_comps[mkcd]}"')
t_eq "config binds every completer" "$(grep '^COMPS ' <<< "$out")" \
  "COMPS _gbclean _zshconf-edit _portkill _portkill _killnamed _rgg _cdl _cdl"

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

# exec -a renames argv[0]; copying the binary trips macOS code signing.
zsh -c 'exec -a zshconfprobe sleep 30' &
probe_pid=$!
t_complete 'killnamed zshconfpr'
t_match "killnamed completes process names" "$screen" "*killnamed zshconfprobe*"

if (( $+commands[lsof] && $+commands[python3] )); then
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

# Is _rg where the pty shell would find it? (array glob: a string test is always true)
rg_comp=(${^T_BREW_FPATH}/_rg(N) ${^${(f)"$(env -u FPATH zsh -fc 'print -l $fpath')"}}/_rg(N))
if (( $+commands[rg] && $#rg_comp )); then
  t_complete 'rgg --hid'
  t_match "rgg reuses ripgrep options" "$screen" "*rgg --hidden*"
else
  t_complete 'rgg some'
  t_match "rgg falls back to files" "$screen" "*somefile*"
fi
t_done
