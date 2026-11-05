# _need <cmd>: require a command, naming the caller on failure.
_need() { (( $+commands[$1] )) || { echo "$1 is required for ${funcstack[2]}" >&2; return 1; } }
# _usage <text>: print usage to stderr, return 1.
_usage() { echo "Usage: $1" >&2; return 1; }
