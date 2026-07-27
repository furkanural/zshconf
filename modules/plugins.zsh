# ── Zinit plugin manager + turbo tiers.
# Containment rule: every zinit-specific idiom (ices, snippets, the null-plugin
# evalcache trick) lives in this file. Other modules interact with zinit only
# through _zinit_evalcache.

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

# ── eval-cache helper: cache a tool's init output via a null plugin (refresh via sysup)
#   _zinit_evalcache <id> <generator-cmd> [wait]
_zinit_evalcache() {
  zinit ice wait"${3:-0c}" lucid id-as"$1" \
    atclone"$2 > init.zsh" atpull'%atclone' src'init.zsh' nocompile'!'
  zinit light zdharma-continuum/null
}

# ── eza styles  (set before OMZP::eza in Tier 3)
zstyle ':omz:plugins:eza' 'dirs-first'  yes
zstyle ':omz:plugins:eza' 'icons'       yes
zstyle ':omz:plugins:eza' 'git-status'  yes
zstyle ':omz:plugins:eza' 'header'      yes
zstyle ':omz:plugins:eza' 'hyperlink'   no
zstyle ':omz:plugins:eza' 'size-prefix' binary    # KiB/MiB

# ── Zinit turbo tiers  (staggered after prompt: compinit → completions → fzf-tab → suggestions → highlight)

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
