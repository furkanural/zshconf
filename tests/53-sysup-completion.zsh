#!/usr/bin/env zsh
# sysup Tab completion: the full config binds `sysup` to the repo's _sysup
# completer, and a real Tab press offers exactly the supported options.
source "${0:A:h}/lib.zsh"

t_make_zdot "$TWORK/zdot"
mkdir -p "$TWORK/xdg"

out=$(t_boot_tiers "$TWORK/zdot" "$TWORK/xdg" 'print -r -- "SYSUP comp=$_comps[sysup]"')
t_eq "config binds sysup to _sysup" "$(grep '^SYSUP comp=' <<< "$out")" "SYSUP comp=_sysup"

# Real Tab press in a minimal pty shell: only compinit + the repo's completer,
# so the assertion is about _sysup, not fzf-tab or the menu UI.
mkdir -p "$TWORK/ptyzdot"
print -r -- "PS1='READY> '
fpath=(\"$REPO/completions\" \$fpath)
autoload -Uz compinit && compinit -u -d \"$TWORK/ptyzdot/.zcompdump\"
zstyle ':completion:*' list-separator '--'
setopt autolist nolistbeep" > "$TWORK/ptyzdot/.zshrc"

zmodload zsh/zpty

# _complete_line <input>: type <input> + Tab into a fresh pty shell; set $screen.
_complete_line() {
  zpty sysupcomp "ZDOTDIR='$TWORK/ptyzdot' TERM=dumb zsh -i"
  screen=""
  local chunk
  integer i
  # Wait for the prompt without blocking forever (CI must fail, not hang).
  for (( i = 0; i < 100; i++ )); do
    zpty -rt sysupcomp chunk && screen+="$chunk"
    [[ "$screen" == *'READY> '* ]] && break
    sleep 0.1
  done
  screen=""
  zpty -n -w sysupcomp "$1"$'\t'
  for (( i = 0; i < 30; i++ )); do
    zpty -rt sysupcomp chunk && screen+="$chunk"   # -rt: non-blocking read
    sleep 0.1
  done
  zpty -d sysupcomp
  screen="${screen//$'\r'/}"
}

_complete_line 'sysup --'
t_match   "Tab offers --native"   "$screen" "*--native*"
t_match   "Tab offers --topgrade" "$screen" "*--topgrade*"
t_match   "Tab offers --help"     "$screen" "*--help*"
t_nomatch "no file completion"    "$screen" "*README*"

_complete_line 'sysup --native --'
t_nomatch "--native excludes --topgrade" "$screen" "*--topgrade*"

_complete_line 'sysup --t'
t_match "--t completes to --topgrade" "$screen" "*sysup --topgrade*"
t_done
