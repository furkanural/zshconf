# ── Linux-specific aliases  (the project's only OS dispatch is the manifest's
#    case on $OSTYPE — keep OS conditionals out of the generic modules)
# Note: no `ip` or `free` aliases here — both are real commands on Linux.
alias f='xdg-open .'
alias myip='curl -s ifconfig.me'                 # `ip` stays the iproute2 tool
alias localip='hostname -I | cut -d" " -f1'
