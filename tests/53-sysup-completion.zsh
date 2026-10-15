#!/usr/bin/env zsh
# sysup Tab completion: the full config binds `sysup` to the repo's _sysup
# completer, and a real Tab press offers exactly the supported options.
source "${0:A:h}/lib.zsh"

t_make_zdot "$TWORK/zdot"
mkdir -p "$TWORK/xdg"

out=$(t_boot_tiers "$TWORK/zdot" "$TWORK/xdg" 'print -r -- "SYSUP comp=$_comps[sysup]"')
t_eq "config binds sysup to _sysup" "$(grep '^SYSUP comp=' <<< "$out")" "SYSUP comp=_sysup"

t_comp_setup

t_complete 'sysup --'
t_match   "Tab offers --native"   "$screen" "*--native*"
t_match   "Tab offers --topgrade" "$screen" "*--topgrade*"
t_match   "Tab offers --help"     "$screen" "*--help*"
t_nomatch "no file completion"    "$screen" "*README*"

t_complete 'sysup --native --'
t_nomatch "--native excludes --topgrade" "$screen" "*--topgrade*"

t_complete 'sysup --t'
t_match "--t completes to --topgrade" "$screen" "*sysup --topgrade*"
t_done
