# ── Aliases: system
alias ip='curl -s ifconfig.me'
alias localip='ipconfig getifaddr en0'
alias ports='lsof -PiTCP -sTCP:LISTEN'
alias sizeof='du -sh'
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -h'
alias free='top -l 1 -s 0 | grep PhysMem'        # macOS has no `free`
