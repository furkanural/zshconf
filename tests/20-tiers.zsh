#!/usr/bin/env zsh
# The turbo tiers actually fire: boot with prompt cycles, assert deferred
# side effects. These assertions have no optional-binary dependencies.
source "${0:A:h}/lib.zsh"

t_make_zdot "$TWORK/zdot"
mkdir -p "$TWORK/xdg"

out=$(t_boot_tiers "$TWORK/zdot" "$TWORK/xdg" '
print -r -- "AS precmd=${${precmd_functions[(Ie)_zsh_autosuggest_start]}:-0} fsh=${+functions[-fast-highlight-process]} selfins=$widgets[self-insert] rebindleft=${+functions[_autosuggest_rebind]}"
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

# Autosuggest binds once (not on every precmd), wrapping fsh — not vice versa.
as="$(grep '^AS ' <<< "$out")"
t_match "fast-syntax-highlighting loaded"     "$as" "*fsh=1*"
t_match "autosuggest not rebinding per prompt" "$as" "*precmd=0*"
t_match "autosuggest wraps outermost"         "$as" "*selfins=user:_zsh_autosuggest_bound_*"
t_match "final rebind ran after last tier"    "$as" "*rebindleft=0*"
t_done
