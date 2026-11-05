bindkey -e

# Word motion stops at / and = (zsh's default includes both).
WORDCHARS='*?_-.[]~&;!#$%^(){}<>'

bindkey '^[[1;3D' backward-word         # Alt+Left
bindkey '^[[1;3C' forward-word          # Alt+Right
bindkey '^[^[[D'  backward-word
bindkey '^[^[[C'  forward-word
bindkey '^[[1;5D' backward-word         # Ctrl+Left
bindkey '^[[1;5C' forward-word          # Ctrl+Right

# Home / End / Delete in every common encoding plus terminfo's.
bindkey '^[[H'  beginning-of-line
bindkey '^[OH'  beginning-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[F'  end-of-line
bindkey '^[OF'  end-of-line
bindkey '^[[4~' end-of-line
bindkey '^[[3~' delete-char
[[ -n ${terminfo[khome]-} ]] && bindkey "${terminfo[khome]}" beginning-of-line
[[ -n ${terminfo[kend]-}  ]] && bindkey "${terminfo[kend]}"  end-of-line
[[ -n ${terminfo[kdch1]-} ]] && bindkey "${terminfo[kdch1]}" delete-char

bindkey '^U' backward-kill-line
bindkey '^K' kill-line
bindkey '^W' backward-kill-word
bindkey '^Y' yank
bindkey '^L' clear-screen

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

bindkey -s '^[h' '^Ucd ~\n'             # Alt+H
bindkey -s '^[u' '^Ucd ..\n'            # Alt+U

# Ctrl+Space / Ctrl+\ (autosuggest) are bound in plugins.zsh once the
# widgets exist; binding earlier makes fsh complain on every start.
