#!/usr/bin/env zsh
# The turbo tiers actually fire: boot with prompt cycles, assert deferred
# side effects. These assertions have no optional-binary dependencies.
source "${0:A:h}/lib.zsh"

t_make_zdot "$TWORK/zdot"
mkdir -p "$TWORK/xdg"

out=$(t_boot_tiers "$TWORK/zdot" "$TWORK/xdg" '
print -r -- "TIERS compinit=${+functions[compdef]} fzftab=${+functions[fzf-tab-complete]} autosuggest=${+functions[_zsh_autosuggest_start]} gst=${+aliases[gst]} hss=$(bindkey "^[[A") dump=$([[ -f $ZDOTDIR/.zcompdump ]]; echo $(( ! $? )))"
')
line="$(grep '^TIERS ' <<< "$out")"

t_match "tier 1: compinit ran"                "$line" "*compinit=1*"
t_match "tier 1: fzf-tab loaded"              "$line" "*fzftab=1*"
t_match "tier 2: autosuggestions loaded"      "$line" "*autosuggest=1*"
t_match "tier 2: OMZ git aliases landed"      "$line" "*gst=1*"
t_match "tier 2: history-substring-search bound" "$line" "*history-substring-search-up*"
t_match "compdump created"                    "$line" "*dump=1*"
t_done
