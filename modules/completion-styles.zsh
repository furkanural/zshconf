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
