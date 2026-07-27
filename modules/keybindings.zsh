# ── Key bindings
bindkey -e                              # emacs

bindkey '^[[1;3D' backward-word         # Alt+Left
bindkey '^[[1;3C' forward-word          # Alt+Right
bindkey '^[^[[D'  backward-word         # Alt+Left  (alt seq)
bindkey '^[^[[C'  forward-word          # Alt+Right (alt seq)

bindkey '^U' backward-kill-line         # Ctrl+U
bindkey '^K' kill-line                  # Ctrl+K
bindkey '^W' backward-kill-word         # Ctrl+W
bindkey '^Y' yank                       # Ctrl+Y
bindkey '^L' clear-screen               # Ctrl+L

bindkey -s '^[h' '^Ucd ~\n'             # Alt+H → cd ~
bindkey -s '^[u' '^Ucd ..\n'            # Alt+U → cd ..

bindkey '^ '   autosuggest-accept       # Ctrl+Space (Shift+Tab left to back-tab)
