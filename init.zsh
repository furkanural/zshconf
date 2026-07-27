# init.zsh — entry point and load manifest.
#
# Sourced from a ~/.zshrc stub:
#   export ZSHCONF="$HOME/.local/share/zsh-config"   # or wherever cloned
#   source "$ZSHCONF/init.zsh"
#
# Modules are sourced at TOP LEVEL, never inside a function: `typeset -U path`
# and friends inside modules must act on the shell's globals, not become
# function-locals.
#
# The order below is load-bearing. Every hard constraint is commented on the
# line that enforces it — if you reorder, re-read these first.

# Resolve the repo root if the stub didn't export it.
: "${ZSHCONF:=${${(%):-%N}:A:h}}"

# ── Core (lifecycle phases, strict order)
source "$ZSHCONF/modules/helpers.zsh"           # _need/_usage (call-time resolved, but defined first anyway)
source "$ZSHCONF/modules/options.zsh"           # history + setopt (incl. zshaddhistory hook)
source "$ZSHCONF/modules/path.zsh"              # path/fpath — MUST precede every $+commands guard below
source "$ZSHCONF/modules/environment.zsh"       # locale, EDITOR, LS_COLORS — vivid needs PATH; list-colors zstyle reads LS_COLORS at definition time
source "$ZSHCONF/modules/dev-tools.zsh"         # mise — before Starship so the prompt sees shimmed tools
source "$ZSHCONF/modules/prompt.zsh"            # starship — after PATH + version managers
source "$ZSHCONF/modules/completion-early.zsh"  # zsh/complist + zcompdump hygiene — MUST run before zicompinit (fires in Tier 1)
source "$ZSHCONF/modules/plugins.zsh"           # zinit bootstrap + turbo tiers; ALL zinit idioms stay in this file
source "$ZSHCONF/modules/keybindings.zsh"       # binds deferred widgets by name; safe before their plugins load
source "$ZSHCONF/modules/completion-styles.zsh" # zstyles read at completion time — after plugins, before first Tab

# ── Guarded tool integrations (each self-contained behind $+commands)
source "$ZSHCONF/modules/tools/fzf.zsh"         # uses _zinit_evalcache from plugins.zsh
source "$ZSHCONF/modules/tools/zoxide.zsh"      # uses _zinit_evalcache from plugins.zsh
source "$ZSHCONF/modules/tools/docker.zsh"
source "$ZSHCONF/modules/tools/bat.zsh"
source "$ZSHCONF/modules/tools/fd.zsh"
source "$ZSHCONF/modules/tools/ripgrep.zsh"
source "$ZSHCONF/modules/tools/heroku.zsh"      # personal-layer candidate; moves to the overlay in phase 2
source "$ZSHCONF/modules/tools/modelpreset.zsh" # personal-layer candidate; moves to the overlay in phase 2

# ── Aliases by domain
source "$ZSHCONF/modules/aliases/general.zsh"
source "$ZSHCONF/modules/aliases/homebrew.zsh"
source "$ZSHCONF/modules/aliases/system.zsh"

# ── Autoloaded user functions: one file per function in functions/
fpath=("$ZSHCONF/functions" $fpath)
() {
  local -a fns
  fns=("$ZSHCONF"/functions/*(.N:t))
  (( $#fns )) && autoload -Uz -- "${fns[@]}"
}

# ── Auto-compile (background-rebuild stale bytecode; `source` only uses a
#    .zwc that is at least as new as its source, so stale bytecode is
#    silently ignored, never wrongly used)
{
  for _zshconf_f in "$ZSHCONF"/init.zsh "$ZSHCONF"/modules/**/*.zsh(.N); do
    if [[ ! -f "$_zshconf_f.zwc" || "$_zshconf_f" -nt "$_zshconf_f.zwc" ]]; then
      zcompile "$_zshconf_f" 2>/dev/null
    fi
  done
} &!
