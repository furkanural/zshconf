# ── Key bindings
bindkey -e                              # emacs

# Word motion/deletion stops at / and = (path segments, --flag=value):
# Ctrl+W on ~/a/b/c deletes "c", not the whole path. zsh's default includes both.
WORDCHARS='*?_-.[]~&;!#$%^(){}<>'

bindkey '^[[1;3D' backward-word         # Alt+Left
bindkey '^[[1;3C' forward-word          # Alt+Right
bindkey '^[^[[D'  backward-word         # Alt+Left  (alt seq)
bindkey '^[^[[C'  forward-word          # Alt+Right (alt seq)

bindkey '^[[1;5D' backward-word         # Ctrl+Left
bindkey '^[[1;5C' forward-word          # Ctrl+Right

# Home / End / Delete: every common encoding, plus whatever terminfo reports.
# Without these, Home prints garbage whenever $TERM's sequence differs from
# what the system zshrc happened to bind (ssh, tmux, Linux consoles).
bindkey '^[[H'  beginning-of-line       # xterm (normal mode)
bindkey '^[OH'  beginning-of-line       # xterm (application mode)
bindkey '^[[1~' beginning-of-line       # vt/tmux/screen
bindkey '^[[F'  end-of-line
bindkey '^[OF'  end-of-line
bindkey '^[[4~' end-of-line
bindkey '^[[3~' delete-char             # Delete
[[ -n ${terminfo[khome]-} ]] && bindkey "${terminfo[khome]}" beginning-of-line
[[ -n ${terminfo[kend]-}  ]] && bindkey "${terminfo[kend]}"  end-of-line
[[ -n ${terminfo[kdch1]-} ]] && bindkey "${terminfo[kdch1]}" delete-char

bindkey '^U' backward-kill-line         # Ctrl+U
bindkey '^K' kill-line                  # Ctrl+K
bindkey '^W' backward-kill-word         # Ctrl+W
bindkey '^Y' yank                       # Ctrl+Y
bindkey '^L' clear-screen               # Ctrl+L

# Ctrl+X Ctrl+E: edit the current command line in $VISUAL/$EDITOR.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

bindkey -s '^[h' '^Ucd ~\n'             # Alt+H → cd ~
bindkey -s '^[u' '^Ucd ..\n'            # Alt+U → cd ..

bindkey '^ '   autosuggest-accept       # Ctrl+Space (Shift+Tab left to back-tab)
