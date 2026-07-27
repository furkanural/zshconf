#!/usr/bin/env zsh
# Layer 2: the config boots cleanly in a bare fixture (no overlay) and the
# eager post-conditions hold. stderr must be EMPTY — almost every real
# regression announces itself there.
source "${0:A:h}/lib.zsh"

t_make_zdot "$TWORK/zdot"
mkdir -p "$TWORK/xdg"

out=$(t_boot "$TWORK/zdot" "$TWORK/xdg" '
print -r -- "fns=${+functions[mkcd]}${+functions[sysup]}${+functions[zshconf-update]}${+functions[gbclean]}"
print -r -- "hooks=${+functions[zshaddhistory]}${+functions[_zinit_evalcache]}${+functions[_need]}"
print -r -- "aliases=${+aliases[q]}${+aliases[ports]}${+aliases[reload]}"
print -r -- "opts=$options[autocd]/$options[extendedglob]/$options[noclobber]"
print -r -- "hist=$HISTSIZE"
print -r -- "path_dupes=$(( ${#path} - ${#${(@u)path}} ))"
print -r -- "prompt=$(( ${+STARSHIP_SESSION_KEY} || ${PS1[(I)❯]} > 0 ))"
print -r -- "ls_colors_set=${+LS_COLORS}"
')
rc=$?

t_eq "boot exits 0"            "$rc" "0"
t_eq "stderr is empty"         "$(cat -- "$TWORK/stderr")" ""
t_eq "user functions autoload" "${${(f)out}[1]}" "fns=1111"
t_eq "hooks + helpers defined" "${${(f)out}[2]}" "hooks=111"
t_eq "core aliases defined"    "${${(f)out}[3]}" "aliases=111"
t_eq "key options set"         "${${(f)out}[4]}" "opts=on/on/on"
t_eq "history sized"           "${${(f)out}[5]}" "hist=50000"
t_eq "path has no duplicates"  "${${(f)out}[6]}" "path_dupes=0"
t_eq "prompt is starship or fallback" "${${(f)out}[7]}" "prompt=1"
t_eq "LS_COLORS exported"      "${${(f)out}[8]}" "ls_colors_set=1"
t_done
