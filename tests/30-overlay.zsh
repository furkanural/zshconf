#!/usr/bin/env zsh
# The overlay contract: pre.zsh values consumed at startup are respected;
# local.d drop-ins load in name order and override the core.
source "${0:A:h}/lib.zsh"

t_make_zdot "$TWORK/zdot"
xdg="$TWORK/xdg"
mkdir -p "$xdg/zsh/local.d"
print -r -- 'export LS_COLORS="di=0;35"'            > "$xdg/zsh/pre.zsh"
printf 'export EDITOR=testvim\nT_SENT="a"\n'        > "$xdg/zsh/local.d/10-a.zsh"
printf 'T_SENT="$T_SENT,b"\nalias q="exit 42"\n'    > "$xdg/zsh/local.d/20-b.zsh"

out=$(t_boot "$TWORK/zdot" "$xdg" '
print -r -- "ls=$LS_COLORS"
print -r -- "ed=$EDITOR"
print -r -- "sent=$T_SENT"
print -r -- "q=${aliases[q]}"
print -r -- "zstyle=$(zstyle -L ":completion:*:default")"
')

t_eq    "pre.zsh LS_COLORS respected"      "${${(f)out}[1]}" "ls=di=0;35"
t_eq    "local.d overrides EDITOR"         "${${(f)out}[2]}" "ed=testvim"
t_eq    "local.d loads in name order"      "${${(f)out}[3]}" "sent=a,b"
t_eq    "local.d overrides core alias"     "${${(f)out}[4]}" "q=exit 42"
t_match "startup consumer saw pre.zsh value" "${${(f)out}[5]}" "*di=0;35*"
t_eq    "stderr is empty"                  "$(cat -- "$TWORK/stderr")" ""
t_done
