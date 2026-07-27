# ── macOS-specific aliases  (the project's only OS dispatch is the manifest's
#    case on $OSTYPE — keep OS conditionals out of the generic modules)
alias f='open -a Finder ./'
alias ip='curl -s ifconfig.me'                   # safe here: macOS has no ip(8)
alias localip='ipconfig getifaddr en0'
alias free='top -l 1 -s 0 | grep PhysMem'        # macOS has no `free`
