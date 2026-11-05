zstyle ':completion:*:git-checkout:*' sort false

# fzf-tab previews
zstyle ':fzf-tab:complete:(cd|z|__zoxide_z):*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:(cat|bat|less|vim|nvim|code|zed):*' \
  fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath 2>/dev/null || eza -1 --color=always $realpath'
zstyle ':fzf-tab:*' fzf-min-height 20
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' continuous-trigger '/'
zstyle ':fzf-tab:*' fzf-flags '--color=fg:-1,bg:-1,hl:#5fff87,fg+:#ffff87,bg+:#3a3a3a,hl+:#ffaf5f'

[[ -d "${ZDOTDIR:-$HOME}/.zsh/cache" ]] || mkdir -p "${ZDOTDIR:-$HOME}/.zsh/cache"

zstyle ':completion:*' completer _complete _extensions _ignored _approximate

# exact → case-insensitive → partial-word → substring
zstyle ':completion:*' matcher-list \
  '' \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=*' \
  'l:|=* r:|=*'

# _approximate: 1 error per 4 chars, inputs >= 6 chars only
zstyle -e ':completion:*:approximate:*' max-errors \
  'reply=( $(( ($#PREFIX+$#SUFFIX) >= 6 ? ($#PREFIX+$#SUFFIX)/4 : 0 )) numeric )'
zstyle ':completion:*:match:*' original only

zstyle ':completion:*' menu no                   # fzf-tab needs this; kill opts back in

zstyle ':completion:*' group-name ''
zstyle ':completion:*' group-order \
  builtins functions commands aliases \
  globbed-files files directories

zstyle ':completion:*:descriptions' format '[%d]'  # fzf-tab parses this
zstyle ':completion:*:messages'     format '%F{purple}-- %d --%f'
zstyle ':completion:*:warnings'     format '%F{red}-- no matches found --%f'
zstyle ':completion:*:corrections'  format ''

zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

zstyle ':completion:*'         verbose yes
zstyle ':completion:*:options' verbose no

zstyle ':completion:*' file-sort modification
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' special-dirs true

zstyle ':completion:*:cd:*'   ignore-parents parent pwd
zstyle ':completion:*:cd:*'   tag-order local-directories directory-stack path-directories

zstyle ':completion:*:*:kill:*'    menu yes select
zstyle ':completion:*:*:killall:*' menu yes select
zstyle ':completion:*:kill:*'      force-list always
zstyle ':completion:*:killall:*'   force-list always
zstyle ':completion:*:*:kill:*:processes' list-colors \
  '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:kill:*' insert-ids single

zstyle ':completion:*' rehash true
zstyle ':completion:*' accept-exact false
zstyle ':completion:*:functions' ignored-patterns '_*'

zstyle ':completion:*:manuals'        separate-sections true
zstyle ':completion:*:manuals.(^1*)'  insert-sections   true

zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${ZDOTDIR:-$HOME}/.zsh/cache"

zstyle ':completion:*' accept-exact-dirs true

zstyle ':completion:*' list-prompt   '%SAt %p: Hit TAB for more, or the character to insert%s'
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'

# File fallback for task runners without their own completer.
zstyle ':completion:*:complete:(just|rails|rake|bundle|bin/rails|bin/rake):*' \
  file-patterns '%p:globbed-files *(-/):directories'
