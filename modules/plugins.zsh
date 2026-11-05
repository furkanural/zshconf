# Zinit + turbo tiers. Every zinit idiom lives in this file; other modules
# use only _zinit_evalcache.

# First install resets to this tag, then stays on the branch so
# `zinit self-update` works.
ZINIT_PIN="v3.17.1"

if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
  print -P "%F{33}Installing Zinit plugin manager (pinned to $ZINIT_PIN)...%f"
  command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
  if command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git"; then
    command git -C "$HOME/.local/share/zinit/zinit.git" reset --hard --quiet "$ZINIT_PIN" \
      || print -P "%F{160}Pin $ZINIT_PIN not found; staying on upstream HEAD.%f"
    print -P "%F{34}Zinit installation successful.%f"
  else
    print -P "%F{160}Zinit installation failed.%f"
  fi
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

_history_substring_search_setup() {
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  [[ -n ${terminfo[kcuu1]-} ]] && bindkey "${terminfo[kcuu1]}" history-substring-search-up
  [[ -n ${terminfo[kcud1]-} ]] && bindkey "${terminfo[kcud1]}" history-substring-search-down
  bindkey '^P'   history-substring-search-up
  bindkey '^N'   history-substring-search-down

  export HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1
  export HISTORY_SUBSTRING_SEARCH_FUZZY=1

  unset -f _history_substring_search_setup
}

# Autosuggestions rewrap every widget on every precmd by default (~20 ms
# with fsh loaded). Bind once after Tier 2, once after Tier 3 instead.
# The plugin checks the variable's existence: unset it to restore the
# default, =0 does nothing.
typeset -g ZSH_AUTOSUGGEST_MANUAL_REBIND=1
typeset -g ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=200

_autosuggest_setup() {
  _zsh_autosuggest_start
  bindkey '^ ' autosuggest-accept
  bindkey '^\' autosuggest-toggle
  unset -f _autosuggest_setup
}

_autosuggest_rebind() {
  (( $+functions[_zsh_autosuggest_bind_widgets] )) && _zsh_autosuggest_bind_widgets
  unset -f _autosuggest_rebind
}

# _zinit_evalcache <id> <generator-cmd> [wait]: cache a tool's init output
# as a null plugin (refreshed by sysup).
_zinit_evalcache() {
  zinit ice wait"${3:-0c}" lucid id-as"$1" \
    atclone"$2 > init.zsh" atpull'%atclone' src'init.zsh' nocompile'!'
  zinit light zdharma-continuum/null
}

# Read by OMZP::eza in Tier 3.
zstyle ':omz:plugins:eza' 'dirs-first'  yes
zstyle ':omz:plugins:eza' 'icons'       yes
zstyle ':omz:plugins:eza' 'git-status'  yes
zstyle ':omz:plugins:eza' 'header'      yes
zstyle ':omz:plugins:eza' 'hyperlink'   no
zstyle ':omz:plugins:eza' 'size-prefix' binary

# Tier 1: before the first Tab.
zinit wait'0a' lucid for \
  atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
  blockf \
    zsh-users/zsh-completions \
    Aloxaf/fzf-tab

# Tier 2: interactive UX. fsh before autosuggestions so the one bind wraps
# fsh's widgets.
zinit wait'0b' lucid for \
  OMZL::git.zsh \
  OMZP::git \
  atload'_history_substring_search_setup' \
    zsh-users/zsh-history-substring-search \
    zdharma-continuum/fast-syntax-highlighting \
  atload"!_autosuggest_setup" \
    zsh-users/zsh-autosuggestions

# Tier 3: the rest. The last atload carries the final autosuggest rebind;
# it runs even when eza is absent.
zinit wait'1' lucid for \
  OMZP::docker-compose \
  OMZP::command-not-found \
  OMZP::ruby \
  OMZP::rails \
  OMZP::extract \
  atload'_autosuggest_rebind' \
    OMZP::eza
