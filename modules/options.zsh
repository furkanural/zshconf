# ── History
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt SHARE_HISTORY              # implies INC_APPEND_HISTORY
setopt EXTENDED_HISTORY           # timestamp + duration
setopt HIST_IGNORE_ALL_DUPS       # drops all older dups
setopt HIST_SAVE_NO_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE          # leading space = not recorded
setopt HIST_VERIFY                # show expanded !! before running
setopt HIST_NO_FUNCTIONS

# Drop pure-noise commands (short aliases like gp/gs/ip kept for Ctrl+R).
zshaddhistory() {
  local line="${1%%$'\n'}"
  local cmd="${line%% *}"

  case "$cmd" in
    (l|ls|ll|la|pwd|exit|clear|history|h|cd|z)
      return 1
      ;;
  esac

  return 0
}

# ── Zsh options

# Directory navigation
setopt AUTO_CD                        # bare dir name = cd
setopt AUTO_PUSHD                     # cd pushes dir stack (dirs -v / popd)
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt PUSHD_TO_HOME                  # bare pushd → $HOME

# Completion
setopt COMPLETE_IN_WORD               # complete mid-word
setopt ALWAYS_TO_END                  # cursor to end after completion
setopt AUTO_PARAM_SLASH               # append / to completed dirs
setopt AUTO_PARAM_KEYS
setopt LIST_PACKED                    # compact columns

# Globbing
setopt EXTENDED_GLOB                  # ^ ~ # globs and **/*
setopt NUMERIC_GLOB_SORT              # file2 before file10

# Safety
setopt NOCLOBBER                      # > won't overwrite; use >!
setopt RM_STAR_WAIT                   # 10s pause before rm *
setopt PROMPT_SUBST                   # Starship needs this

# I/O
setopt MULTIOS                        # implicit tee/cat on multiple redirs
setopt INTERACTIVE_COMMENTS           # # comments at the prompt

# Jobs
setopt NO_BG_NICE
setopt NO_HUP
setopt NOTIFY
setopt LONG_LIST_JOBS
setopt AUTO_CONTINUE
setopt CHECK_JOBS

# Quality of life
setopt NO_BEEP
setopt PATH_DIRS                      # path search for commands containing /
setopt MAGIC_EQUAL_SUBST              # --prefix=<TAB> completes paths
