HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

setopt SHARE_HISTORY
setopt HIST_FCNTL_LOCK            # unsetopt in local.d on NFS/sshfs $HOME
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt HIST_NO_FUNCTIONS

# Skip pure-noise commands.
zshaddhistory() {
  local line="${1%%$'\n'}"
  local cmd="${line%% *}"
  case "$cmd" in
    (l|ls|ll|la|pwd|exit|clear|history|h|cd|z) return 1 ;;
  esac
  return 0
}

setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt PUSHD_TO_HOME

setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt AUTO_PARAM_SLASH
setopt AUTO_PARAM_KEYS
setopt LIST_PACKED

setopt EXTENDED_GLOB
setopt NUMERIC_GLOB_SORT

setopt NOCLOBBER                      # use >! to overwrite
setopt RM_STAR_WAIT
setopt PROMPT_SUBST

setopt MULTIOS
setopt INTERACTIVE_COMMENTS

setopt NO_BG_NICE
setopt NO_HUP
setopt NOTIFY
setopt LONG_LIST_JOBS
setopt AUTO_CONTINUE
setopt CHECK_JOBS

setopt NO_BEEP
setopt NO_FLOW_CONTROL                # frees Ctrl+S / Ctrl+Q
setopt COMBINING_CHARS
setopt PATH_DIRS
setopt MAGIC_EQUAL_SUBST
