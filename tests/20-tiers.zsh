#!/usr/bin/env zsh
# The turbo tiers actually fire: boot with prompt cycles, assert deferred
# side effects. These assertions have no optional-binary dependencies.
source "${0:A:h}/lib.zsh"

t_make_zdot "$TWORK/zdot"
mkdir -p "$TWORK/xdg"

out=$(t_boot_tiers "$TWORK/zdot" "$TWORK/xdg" '
print -r -- "TIERS compinit=${+functions[compdef]} fzftab=${+functions[fzf-tab-complete]} autosuggest=${+functions[_zsh_autosuggest_start]} gst=${+aliases[gst]} hss=$(bindkey "^[[A") ctrlbs=$(bindkey "^\\") ctrlright=$(bindkey "^[[1;5C") ctrlf=$(bindkey "^F" 2>/dev/null) hasfzf=${+commands[fzf]} dump=$([[ -f $ZDOTDIR/.zcompdump ]]; echo $(( ! $? )))"
')
line="$(grep '^TIERS ' <<< "$out")"

t_match "tier 1: compinit ran"                "$line" "*compinit=1*"
t_match "tier 1: fzf-tab loaded"              "$line" "*fzftab=1*"
t_match "tier 2: autosuggestions loaded"      "$line" "*autosuggest=1*"
t_match "tier 2: OMZ git aliases landed"      "$line" "*gst=1*"
t_match "tier 2: history-substring-search bound" "$line" "*history-substring-search-up*"
t_match "tier 2: autosuggest-toggle bound (Ctrl+\\)" "$line" "*ctrlbs=*autosuggest-toggle*"
t_match "Ctrl+Right word jump bound"          "$line" "*ctrlright=*forward-word*"
if [[ "$line" == *hasfzf=1* ]]; then
  t_match "Ctrl+F no-hidden picker bound"     "$line" "*ctrlf=*_fzf_file_no_hidden*"
fi
t_match "compdump created"                    "$line" "*dump=1*"
t_done
