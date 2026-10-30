# ── Zinit plugin manager + turbo tiers.
# Containment rule: every zinit-specific idiom (ices, snippets, the null-plugin
# evalcache trick) lives in this file. Other modules interact with zinit only
# through _zinit_evalcache.

# Bootstrap pin (TOFU): a fresh machine executes exactly this tag's code.
# We reset to the tag but stay on the default branch, so a later
# `zinit self-update` (the sanctioned update path, via sysup) still works —
# accepting drift from the pin after first install. Bump deliberately.
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

# Bound to history-substring-search via Tier 2 atload; self-deletes.
_history_substring_search_setup() {
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  # Application-mode arrows (^[OA/^[OB, what zle's terminfo reports in most
  # terminals) — otherwise the system zshrc's up-line-or-search wins there.
  [[ -n ${terminfo[kcuu1]-} ]] && bindkey "${terminfo[kcuu1]}" history-substring-search-up
  [[ -n ${terminfo[kcud1]-} ]] && bindkey "${terminfo[kcud1]}" history-substring-search-down
  bindkey '^P'   history-substring-search-up
  bindkey '^N'   history-substring-search-down

  export HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1
  export HISTORY_SUBSTRING_SEARCH_FUZZY=1

  unset -f _history_substring_search_setup
}

# ── zsh-autosuggestions settings (read at call time; overlay can override)
# MANUAL_REBIND: by default the plugin re-wraps EVERY zle widget on every
# precmd — with fast-syntax-highlighting's wrappers that is ~600 widgets,
# ~20 ms per prompt. We bind once when Tier 2 loads (fsh is loaded before it
# in the same tier, so autosuggest wraps fsh's wrappers — the order both
# plugins document), and once more after the last tier (_autosuggest_rebind)
# to pick up widgets that later tiers define (fzf's Ctrl+R/Ctrl+T, …).
typeset -g ZSH_AUTOSUGGEST_MANUAL_REBIND=1
typeset -g ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=200         # no suggestion lookups for pasted walls of text

# Bound to zsh-autosuggestions via Tier 2 atload; self-deletes.
_autosuggest_setup() {
  _zsh_autosuggest_start                 # binds widgets; with MANUAL_REBIND drops its precmd hook
  bindkey '^\' autosuggest-toggle        # Ctrl+\ — handy for screen sharing

  unset -f _autosuggest_setup
}

# Bound to the last tier's atload: one rebind so widgets created by later
# tiers (fzf-init, zoxide, OMZ plugins) are wrapped too; self-deletes.
_autosuggest_rebind() {
  (( $+functions[_zsh_autosuggest_bind_widgets] )) && _zsh_autosuggest_bind_widgets
  unset -f _autosuggest_rebind
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
# Order matters: fast-syntax-highlighting BEFORE autosuggestions, so the one
# autosuggest bind (MANUAL_REBIND, above) wraps fsh's widgets, not vice versa.
zinit wait'0b' lucid for \
  OMZL::git.zsh \
  OMZP::git \
  atload'_history_substring_search_setup' \
    zsh-users/zsh-history-substring-search \
    zdharma-continuum/fast-syntax-highlighting \
  atload"!_autosuggest_setup" \
    zsh-users/zsh-autosuggestions

# Tier 3 (1): rarely needed in first second. (git-auto-fetch removed — noisy on flaky nets.)
# Last plugin carries the final autosuggest rebind (see MANUAL_REBIND above).
zinit wait'1' lucid for \
  OMZP::docker-compose \
  OMZP::command-not-found \
  OMZP::ruby \
  OMZP::rails \
  OMZP::extract \
  atload'_autosuggest_rebind' \
    OMZP::eza
