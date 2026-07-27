# ZSH — macOS Apple Silicon · Rails(Docker)/Python/Docker Compose/Heroku/Claude Code

# ── Locale
export LANG="en_US.UTF-8"
export LC_CTYPE="$LANG"
export TIME_STYLE="long-iso"

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

# ── PATH  (brew AS → brew Intel → system → user-local; (N) skips missing dirs)
path=(
  /opt/homebrew/bin(N)
  /opt/homebrew/sbin(N)
  /opt/homebrew/opt/curl/bin(N)
  /usr/local/bin(N)
  /usr/local/sbin(N)
  /usr/bin
  /bin
  /usr/sbin
  /sbin
  $HOME/.local/bin(N)
  $HOME/bin(N)
)
typeset -U path
export PATH

# ── FPATH  (user → brew → system; must precede zicompinit; blockf blocks plugin edits)
fpath=(
  ${ZDOTDIR:-$HOME}/.zsh/completions(N)
  /opt/homebrew/share/zsh/site-functions(N)
  /usr/local/share/zsh/site-functions(N)
  $fpath
)
typeset -U fpath

# ── Default programs
export EDITOR="nano"           # git commit / rebase todo
export VISUAL="zed --wait"     # mergetool / gh pr edit
export PAGER="less"

# ── Environment
export GPG_TTY=$TTY
export HOMEBREW_NO_ANALYTICS=1

# LS_COLORS feeds eza fallbacks + completion list-colors; macOS ships none.
if (( $+commands[vivid] )); then
  export LS_COLORS="$(vivid generate ansi 2>/dev/null)"
else
  export LS_COLORS="di=1;34:ln=1;36:so=1;35:pi=1;33:ex=1;32:bd=1;33:cd=1;33:su=0;41:sg=0;46:tw=0;42:ow=0;43:mi=0;41"
fi

# ── Version managers
(( $+commands[mise] )) && eval "$(mise activate zsh)"

# ── Starship prompt  (after PATH + version managers)
(( $+commands[starship] )) && eval "$(starship init zsh)"

# ── Completion module  (menu-select widget; must load before compinit)
zmodload zsh/complist

# ── Zinit plugin manager
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
  print -P "%F{33}Installing Zinit plugin manager...%f"
  command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
  command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
    print -P "%F{34}Zinit installation successful.%f" || \
    print -P "%F{160}Zinit installation failed.%f"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Bound to history-substring-search via Tier 2 atload; self-deletes.
_history_substring_search_setup() {
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  bindkey '^P'   history-substring-search-up
  bindkey '^N'   history-substring-search-down

  export HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1
  export HISTORY_SUBSTRING_SEARCH_FUZZY=1

  unset -f _history_substring_search_setup
}

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

# ── eza styles  (set before OMZP::eza in Tier 3)
zstyle ':omz:plugins:eza' 'dirs-first'  yes
zstyle ':omz:plugins:eza' 'icons'       yes
zstyle ':omz:plugins:eza' 'git-status'  yes
zstyle ':omz:plugins:eza' 'header'      yes
zstyle ':omz:plugins:eza' 'hyperlink'   no
zstyle ':omz:plugins:eza' 'size-prefix' binary    # KiB/MiB

# ── Zinit turbo tiers  (staggered after prompt: compinit → completions → fzf-tab → suggestions → highlight)

# Repair clap dynamic completers (_clap_dynamic_completer_*) back to stable _cmd stubs.
_repair_clap_dynamic_completions() {
  emulate -L zsh
  setopt extendedglob

  (( ${+_comps} && ${+functions[compdef]} )) || return 0

  local cmd fn stub dir
  for cmd fn in ${(kv)_comps}; do
    [[ "$fn" == _clap_dynamic_completer_* ]] || continue

    stub="_${cmd:t}"
    for dir in $fpath; do
      if [[ -r "$dir/$stub" ]]; then
        autoload -Uz "$stub"
        compdef "$stub" "$cmd"
        break
      fi
    done
  done
}

# Drop stale/poisoned completion dumps before zicompinit (compinit -C skips rescan).
() {
  emulate -L zsh
  setopt extendedglob

  local zdot="${ZDOTDIR:-$HOME}"
  local zcompdump="$zdot/.zcompdump"

  if [[ -r "$zcompdump" ]] && command grep -q "_clap_dynamic_completer_" "$zcompdump" 2>/dev/null; then
    rm -f "$zdot"/.zcompdump*(N)
    return 0
  fi

  local watched=(
    "$zdot/.zshrc"
    "$HOME/.local/share/zinit/completions"
    "$HOME/.cache/zinit/completions"
    "/opt/homebrew/share/zsh/site-functions"
  )

  local entry
  for entry in $watched; do
    if [[ -e "$entry" && ( ! -f "$zcompdump" || "$entry" -nt "$zcompdump" ) ]]; then
      rm -f "$zdot"/.zcompdump*(N)
      break
    fi
  done
}

# Tier 1 (0a): must run before the first Tab press.
zinit wait'0a' lucid for \
  atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
  blockf \
    zsh-users/zsh-completions \
    Aloxaf/fzf-tab

# Tier 2 (0b): interactive UX; git aliases (gst, gco, gp) land here.
zinit wait'0b' lucid for \
  OMZL::git.zsh \
  OMZP::git \
  atload'_history_substring_search_setup' \
    zsh-users/zsh-history-substring-search \
  atload"!_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions \
    zdharma-continuum/fast-syntax-highlighting

# Tier 3 (1): rarely needed in first second. (git-auto-fetch removed — noisy on flaky nets.)
zinit wait'1' lucid for \
  OMZP::docker-compose \
  OMZP::command-not-found \
  OMZP::ruby \
  OMZP::rails \
  OMZP::extract \
  OMZP::eza

# ── fzf-tab styles
zstyle ':completion:*:git-checkout:*' sort false

# Preview panes
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:(cat|bat|less|vim|nvim|code|zed):*' \
  fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath 2>/dev/null || eza -1 --color=always $realpath'

zstyle ':fzf-tab:*' fzf-min-height 20            # no preview when list is small
zstyle ':fzf-tab:*' switch-group ',' '.'         # move between groups
zstyle ':fzf-tab:*' continuous-trigger '/'       # drill deeper via /
zstyle ':fzf-tab:*' fzf-flags '--color=fg:-1,bg:-1,hl:#5fff87,fg+:#ffff87,bg+:#3a3a3a,hl+:#ffaf5f'

# ── Completion system  (debug a press: Ctrl+X h)

# Background-compile the dump for the next startup.
{
  if [[ -s "${ZDOTDIR:-$HOME}/.zcompdump" && (! -s "${ZDOTDIR:-$HOME}/.zcompdump.zwc" || "${ZDOTDIR:-$HOME}/.zcompdump" -nt "${ZDOTDIR:-$HOME}/.zcompdump.zwc") ]]; then
    zcompile "${ZDOTDIR:-$HOME}/.zcompdump"
  fi
} &!

[[ -d "${ZDOTDIR:-$HOME}/.zsh/cache" ]] || mkdir -p "${ZDOTDIR:-$HOME}/.zsh/cache"

# Completer chain: _complete, _extensions (*.ext), _ignored (rescues just/rails
# positional file args), _approximate (typo correction, gated below).
zstyle ':completion:*' completer _complete _extensions _ignored _approximate

# Matcher: exact → case-insensitive → partial-word → substring.
zstyle ':completion:*' matcher-list \
  '' \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=*' \
  'l:|=* r:|=*'

# _approximate: 1 error per 4 chars, inputs ≥ 6 chars only.
zstyle -e ':completion:*:approximate:*' max-errors \
  'reply=( $(( ($#PREFIX+$#SUFFIX) >= 6 ? ($#PREFIX+$#SUFFIX)/4 : 0 )) numeric )'
zstyle ':completion:*:match:*' original only

# fzf-tab needs `menu no`; kill/killall opt back in below.
zstyle ':completion:*' menu no

# Group output by tag.
zstyle ':completion:*' group-name ''
zstyle ':completion:*' group-order \
  builtins functions commands aliases \
  globbed-files files directories

# Formatting ([%d] is what fzf-tab parses).
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:messages'     format '%F{purple}-- %d --%f'
zstyle ':completion:*:warnings'     format '%F{red}-- no matches found --%f'
zstyle ':completion:*:corrections'  format ''

zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

zstyle ':completion:*'         verbose yes
zstyle ':completion:*:options' verbose no           # bare flags like cp -<TAB>

# File / dir
zstyle ':completion:*' file-sort modification        # most-recent first
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' special-dirs true             # complete . and ..

# cd / pushd  (no `menu select` here — it would suppress fzf-tab + its preview)
zstyle ':completion:*:cd:*'   ignore-parents parent pwd
zstyle ':completion:*:cd:*'   tag-order local-directories directory-stack path-directories

# kill / killall — standard menu
zstyle ':completion:*:*:kill:*'    menu yes select
zstyle ':completion:*:*:killall:*' menu yes select
zstyle ':completion:*:kill:*'      force-list always
zstyle ':completion:*:killall:*'   force-list always
zstyle ':completion:*:*:kill:*:processes' list-colors \
  '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:kill:*' insert-ids single

# Misc
zstyle ':completion:*' rehash true                       # pick up new $PATH binaries
zstyle ':completion:*' accept-exact false                # always show menu
zstyle ':completion:*:functions' ignored-patterns '_*'   # hide internal fns

# Man pages
zstyle ':completion:*:manuals'        separate-sections true
zstyle ':completion:*:manuals.(^1*)'  insert-sections   true

# Caching
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${ZDOTDIR:-$HOME}/.zsh/cache"

# Accept an existing dir component verbatim (speeds up deep paths).
zstyle ':completion:*' accept-exact-dirs true

# Menu prompts
zstyle ':completion:*' list-prompt   '%SAt %p: Hit TAB for more, or the character to insert%s'
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'

# Fallback file completion for just/rails/rake/bundle (%p = prior patterns).
zstyle ':completion:*:complete:(just|rails|rake|bundle|bin/rails|bin/rake):*' \
  file-patterns '%p:globbed-files *(-/):directories'

# ── eval-cache helper: cache a tool's init output via a null plugin (refresh via sysup)
#   _zinit_evalcache <id> <generator-cmd> [wait]
_zinit_evalcache() {
  zinit ice wait"${3:-0c}" lucid id-as"$1" \
    atclone"$2 > init.zsh" atpull'%atclone' src'init.zsh' nocompile'!'
  zinit light zdharma-continuum/null
}

# ── fzf
if (( $+commands[fzf] )); then
  export FZF_DEFAULT_OPTS='
    --height 40%
    --layout=reverse
    --border
    --inline-info
    --color=fg:-1,bg:-1,hl:#5fff87,fg+:#ffff87,bg+:#3a3a3a,hl+:#ffaf5f
    --color=info:#af87ff,prompt:#5fff87,pointer:#ff87d7,marker:#ff87d7,spinner:#ff87d7
    --bind ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down
  '

  # fd as source — faster, respects .gitignore.
  if (( $+commands[fd] )); then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi

  _zinit_evalcache fzf-init 'fzf --zsh'
fi

# ── zoxide
if (( $+commands[zoxide] )); then
  _zinit_evalcache zoxide-init 'zoxide init zsh'
fi

# ── Heroku autocomplete  (keep AC env vars + commands_setters; refresh: heroku autocomplete --refresh-cache)
if (( $+commands[heroku] )); then
  export HEROKU_AC_ANALYTICS_DIR="$HOME/Library/Caches/heroku/autocomplete/completion_analytics"
  export HEROKU_AC_COMMANDS_PATH="$HOME/Library/Caches/heroku/autocomplete/commands"

  # Defer the 116KB commands_setters source to ~1s after the prompt.
  zinit ice wait'1' lucid id-as'heroku-autocomplete' \
    atload'[[ -f $HOME/Library/Caches/heroku/autocomplete/commands_setters ]] && source $HOME/Library/Caches/heroku/autocomplete/commands_setters'
  zinit light zdharma-continuum/null
fi

# ── Internal helpers  (resolved at call time)
# _need <cmd>: require a command, else complain naming the caller.  _need fzf || return
_need() { (( $+commands[$1] )) || { echo "$1 is required for ${funcstack[2]}" >&2; return 1; } }
# _usage <text>: print usage to stderr, return 1.
_usage() { echo "Usage: $1" >&2; return 1; }

# ── Aliases: general
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias f='open -a Finder ./'
alias q='exit'
alias reload='exec zsh'

# path/fpath are special ZSH array names → use functions.
showpath()  { print -l $path }
showfpath() { print -l $fpath }

# ── Aliases: file listing  (ls/ll/la/… come from OMZP::eza; fallbacks only if eza absent)
if ! (( $+commands[eza] )); then
  alias ll='ls -lAh'
  alias la='ls -A'
  alias l='ls -CF'
fi

# ── Aliases: git  (most come from OMZP::git)

# Delete local branches merged into HEAD. Skips main/master/develop + current.
gbclean() {
  local force=0

  case "$1" in
    -f|--force)
      force=1
      shift
      ;;
    -h|--help)
      echo "Usage: gbclean [-f|--force]"
      echo "  gbclean          Delete branches merged into HEAD"
      echo "  gbclean --force  Force-delete local branches, even if unmerged"
      return 0
      ;;
  esac

  local delete_flag="-d"
  (( force )) && delete_flag="-D"

  # Force mode lists all local branches; default lists only merged ones.
  local -a merged_flag
  (( force )) || merged_flag=(--merged)

  local branches
  branches=$(git branch $merged_flag \
    | grep -Ev '^\*|^[[:space:]]+(main|master|develop)$')

  [[ -z "$branches" ]] && {
    echo "No branches to delete."
    return 0
  }

  xargs -n 1 git branch "$delete_flag" <<< "$branches"
}

# ── Aliases: homebrew
alias brewclean='brew cleanup && brew autoremove'
alias brewlist='brew list --formula'
alias brewdeps='brew deps --tree --installed'

# Update everything: brew + zinit + zcompdump. Each lane is independent.
sysup() {
  emulate -L zsh
  setopt extendedglob

  print -P "%F{cyan}==> Homebrew packages...%f"
  brew update &&
  brew upgrade --greedy &&
  brew cleanup &&
  brew autoremove

  brew doctor || print -P "%F{yellow}(brew doctor reported issues — review above)%f"

  print -P "\n%F{cyan}==> Zinit plugins...%f"
  zinit self-update
  zinit update --all

  print -P "\n%F{cyan}==> Completion dump...%f"
  rm -f "${ZDOTDIR:-$HOME}"/.zcompdump*(N)

  _repair_clap_dynamic_completions

  rehash

  print -P "\n%F{green}==> Done.%f Run %F{yellow}exec zsh%f to refresh completions."
}

# ── Aliases: system
alias ip='curl -s ifconfig.me'
alias localip='ipconfig getifaddr en0'
alias ports='lsof -PiTCP -sTCP:LISTEN'
alias sizeof='du -sh'
alias grep='grep --color=auto'
alias df='df -h'
alias du='du -h'
alias free='top -l 1 -s 0 | grep PhysMem'        # macOS has no `free`

# ── Aliases: docker
if (( $+commands[docker] )); then
  alias dps='docker ps'
  alias dpsa='docker ps -a'
  alias di='docker images'
  alias dprune='docker system prune -a'           # prompt preserved (no -f)
  alias dlogs='docker logs -f'
  alias dsh='docker exec -it'

  # Pick container(s) to stop via fzf (Tab = multi-select).
  dstop() {
    _need fzf || return

    local cids
    cids=$(docker ps --format '{{.ID}}\t{{.Names}}\t{{.Image}}' \
      | fzf --multi --header='Tab: select • Enter: stop selected' --with-nth=2,3) \
      || return 0
    [[ -n "$cids" ]] && awk '{print $1}' <<< "$cids" | xargs docker stop
  }

  # Pick container(s) to remove via fzf (Tab = multi-select).
  drm() {
    _need fzf || return

    local cids
    cids=$(docker ps -a --format '{{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Image}}' \
      | fzf --multi --header='Tab: select • Enter: remove selected' --with-nth=2,3,4) \
      || return 0
    [[ -n "$cids" ]] && awk '{print $1}' <<< "$cids" | xargs docker rm
  }
fi

# ── Aliases: modern CLI tools

# bat — cat with highlighting (distinct names so real cat/less survive).
if (( $+commands[bat] )); then
  export BAT_THEME="TwoDark"
  export BAT_STYLE="numbers,changes,header,grid"
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"   # highlighted man pages
  alias kat='bat --paging=never --style=plain'        # plain (no numbers/grid)
  alias ccat='bat --paging=never'                     # numbers + grid
fi

# fd — faster find.
if (( $+commands[fd] )); then
  alias fdf='fd --type f'
  alias fdd='fd --type d'
  alias fda='fd --hidden'
  alias fdx='fd --type x'
fi

# ripgrep — faster grep.
if (( $+commands[rg] )); then
  alias rgi='rg --ignore-case'
  alias rgf='rg --files | rg'                         # match filenames
  alias rgl='rg -l'                                   # file list only
  alias rgc='rg -c'                                   # match counts
  alias rga='rg --hidden --no-ignore'                 # search everything
fi

# ── Functions: general  (`extract <file>` comes from OMZP::extract)

# mkdir + cd into it.
mkcd() {
  [[ -n "$1" ]] || { _usage "mkcd <dir>"; return; }
  mkdir -p "$1" && cd "$1"
}

# cd into a dir and list it.
cdl() {
  [[ -n "$1" ]] || { _usage "cdl <dir>"; return; }
  cd "$1" && ls
}

# Process holding <port>.
portprocess() {
  [[ -n "$1" ]] || { _usage "portprocess <port_number>"; return; }
  lsof -i :"$1"
}

# SIGTERM whoever holds <port> (use kill -9 <pid> for SIGKILL).
portkill() {
  [[ -n "$1" ]] || { _usage "portkill <port_number>"; return; }
  local pids=$(lsof -ti :"$1")
  if [[ -n "$pids" ]]; then
    xargs kill 2>/dev/null <<< "$pids"
    echo "Sent SIGTERM to process(es) on port $1"
  else
    echo "No process found on port $1"
  fi
}

# Timestamped backup copy(ies). Trailing slash stripped so `bak dir/` → sibling.
bak() {
  [[ -n "$1" ]] || { _usage "bak <file>..."; return; }
  local file
  for file in "$@"; do
    file="${file%/}"
    cp -r "$file" "$file.bak.$(date +%Y%m%d_%H%M%S)"
  done
}

# SIGTERM all processes whose name (case-insensitive) matches.
killnamed() {
  [[ -n "$1" ]] || { _usage "killnamed <process_name>"; return; }
  pkill -i "$1"; (( $? == 1 )) && echo "No matching process found: $1"
}

# Fresh tempdir + cd into it.
tmpcd() {
  local tmp
  tmp=$(mktemp -d) || { echo "mktemp failed"; return 1; }
  cd "$tmp" && echo "Created temporary directory: $tmp"
}

# ripgrep with hidden files, .git skipped.
rgg() {
  [[ -n "$1" ]] || { _usage "rgg <pattern> [path]"; return; }
  _need rg || return
  rg --hidden --glob '!.git' --smart-case --line-number "$@"
}

# ── Functions: model presets
# Source $XDG_CONFIG_HOME/cliproxy-presets/<name>.env (ANTHROPIC_BASE_URL / _AUTH_TOKEN / _DEFAULT_*_MODEL).
#   modelpreset          list presets
#   modelpreset hybrid   load hybrid.env into the current shell
modelpreset() {
  local dir="${XDG_CONFIG_HOME:-$HOME/.config}/cliproxy-presets"
  [[ -d "$dir" ]] || { echo "Preset directory not found: $dir" >&2; return 1; }

  local -a presets
  presets=("$dir"/*.env(.N:t:r))

  # With an arg: validate + load. Hard error → non-zero; unknown name → print list.
  if [[ -n "$1" ]]; then
    if [[ "$1" == */* ]]; then
      echo "Invalid preset name: $1" >&2
      return 1
    fi
    local file="$dir/$1.env"
    if [[ -f "$file" ]]; then
      if source "$file"; then
        echo "Loaded preset: $1"
        return 0
      fi
      echo "Failed to load preset: $1 (syntax error in $file)" >&2
      return 1
    fi
    echo "Preset not found: $1" >&2
  fi

  # Reached with no arg (listing) or unknown preset (hint after error).
  echo "Available presets:"
  (( ${#presets} )) && print -l "${presets[@]}" || echo "  (none)"
  [[ -z "$1" ]]   # 0 for plain listing, 1 when arrived via "not found"
}

# Tab-complete preset names.
_modelpreset() {
  local dir="${XDG_CONFIG_HOME:-$HOME/.config}/cliproxy-presets"
  [[ -d "$dir" ]] || return 1
  local -a presets
  presets=("$dir"/*.env(.N:t:r))
  (( ${#presets} )) && _describe 'preset' presets
}
# compdef exists only after Tier 1 zicompinit; zicompdef queues it for zicdreplay.
if (( ${+functions[compdef]} )); then
  compdef _modelpreset modelpreset
elif (( ${+functions[zicompdef]} )); then
  zicompdef _modelpreset modelpreset
fi

# ── Functions: git (gh-powered)

# Open repo/path/issue/PR/branch in the browser.
#   ghopen · ghopen README.md · ghopen 1234 · ghopen -b feat-x
ghopen() {
  _need gh || return
  gh browse "$@"
}

# Open the current branch's PR (existing, else new-PR draft).
ghpr() {
  _need gh || return

  gh pr view --web 2>/dev/null && return
  gh pr create --web "$@"
}

# ── Auto-compile  (rebuild .zshrc.zwc in background when .zshrc changes)
if [[ ! -f ~/.zshrc.zwc || ~/.zshrc -nt ~/.zshrc.zwc ]]; then
  { zcompile ~/.zshrc 2>/dev/null } &!
fi
