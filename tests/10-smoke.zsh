#!/usr/bin/env zsh
# Layer 2: the config boots cleanly in a bare fixture (no overlay) and the
# eager post-conditions hold. stderr must be EMPTY — almost every real
# regression announces itself there.
source "${0:A:h}/lib.zsh"

t_make_zdot "$TWORK/zdot"
mkdir -p "$TWORK/xdg"

out=$(PATH="$PATH:/zshconf-test/inherited" t_boot "$TWORK/zdot" "$TWORK/xdg" '
print -r -- "fns=${+functions[mkcd]}${+functions[sysup]}${+functions[zshconf-update]}${+functions[gbclean]}"
print -r -- "hooks=${+functions[zshaddhistory]}${+functions[_zinit_evalcache]}${+functions[_need]}"
print -r -- "aliases=${+aliases[q]}${+aliases[ports]}${+aliases[reload]}"
print -r -- "opts=$options[autocd]/$options[extendedglob]/$options[noclobber]"
print -r -- "hist=$HISTSIZE"
print -r -- "path_dupes=$(( ${#path} - ${#${(@u)path}} ))"
print -r -- "prompt=$(( ${+STARSHIP_SESSION_KEY} || ${PS1[(I)❯]} > 0 ))"
print -r -- "ls_colors_set=${+LS_COLORS}"
print -r -- "keys=$(bindkey "^[[H")|$(bindkey "^[[F")|$(bindkey "^[[1~")|$(bindkey "^[[3~")|$(bindkey "^X^E")"
print -r -- "opts2=$options[flowcontrol]/$options[histfcntllock]"
print -r -- "inherited=${path[(I)/zshconf-test/inherited]}"
print -r -- "gitalias=$aliases[git]"
print -r -- "asmanual=${+ZSH_AUTOSUGGEST_MANUAL_REBIND}"
')
rc=$?

t_eq "boot exits 0"            "$rc" "0"
t_eq "stderr is empty"         "$(cat -- "$TWORK/stderr")" ""
t_eq "user functions autoload" "${${(f)out}[1]}" "fns=1111"
t_eq "hooks + helpers defined" "${${(f)out}[2]}" "hooks=111"
t_eq "core aliases defined"    "${${(f)out}[3]}" "aliases=111"
t_eq "key options set"         "${${(f)out}[4]}" "opts=on/on/on"
t_eq "history sized"           "${${(f)out}[5]}" "hist=100000"
t_eq "path has no duplicates"  "${${(f)out}[6]}" "path_dupes=0"
t_eq "prompt is starship or fallback" "${${(f)out}[7]}" "prompt=1"
t_eq "LS_COLORS exported"      "${${(f)out}[8]}" "ls_colors_set=1"
t_eq "Home/End/Delete/Ctrl+X Ctrl+E bound" "${${(f)out}[9]}" \
  'keys="^[[H" beginning-of-line|"^[[F" end-of-line|"^[[1~" beginning-of-line|"^[[3~" delete-char|"^X^E" edit-command-line'
t_eq "flow control off, fcntl history lock" "${${(f)out}[10]}" "opts2=off/on"
t_match "inherited PATH entries survive"    "${${(f)out}[11]}" "inherited=<1->"
t_eq "git is noglob (git log HEAD^ works)"   "${${(f)out}[12]}" "gitalias=noglob git"
t_eq "autosuggest manual rebind on"          "${${(f)out}[13]}" "asmanual=1"
t_done
