# Entry point. Sourced from the ~/.zshrc stub; modules are sourced at top
# level so typeset -U and friends act on globals. Order is load-bearing.

: "${ZSHCONF:=${${(%):-%N}:A:h}}"

ZSHCONF_LOCAL="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

# Overlay pre-hook: values the core reads during startup (e.g. LS_COLORS).
[[ -r "$ZSHCONF_LOCAL/pre.zsh" ]] && source "$ZSHCONF_LOCAL/pre.zsh"

# Env seam. Also sourced from ~/.zprofile; guard keeps it to one run.
if [[ -z ${ZSHCONF_ENV_SOURCED:-} && -r "$ZSHCONF_LOCAL/env.zsh" ]]; then
  ZSHCONF_ENV_SOURCED=1
  source "$ZSHCONF_LOCAL/env.zsh"
fi

source "$ZSHCONF/modules/helpers.zsh"
source "$ZSHCONF/modules/options.zsh"
source "$ZSHCONF/modules/path.zsh"              # before any $+commands guard
source "$ZSHCONF/modules/environment.zsh"       # LS_COLORS before completion-styles
source "$ZSHCONF/modules/dev-tools.zsh"         # mise before starship
source "$ZSHCONF/modules/prompt.zsh"
source "$ZSHCONF/modules/completion-early.zsh"  # complist + dump hygiene before zicompinit
source "$ZSHCONF/modules/plugins.zsh"           # all zinit idioms live here
source "$ZSHCONF/modules/keybindings.zsh"
source "$ZSHCONF/modules/completion-styles.zsh" # after plugins, before first Tab

source "$ZSHCONF/modules/tools/fzf.zsh"
source "$ZSHCONF/modules/tools/zoxide.zsh"
source "$ZSHCONF/modules/tools/docker.zsh"
source "$ZSHCONF/modules/tools/bat.zsh"
source "$ZSHCONF/modules/tools/fd.zsh"
source "$ZSHCONF/modules/tools/ripgrep.zsh"
source "$ZSHCONF/modules/tools/heroku.zsh"
source "$ZSHCONF/modules/tools/modelpreset.zsh"

source "$ZSHCONF/modules/aliases/general.zsh"
source "$ZSHCONF/modules/aliases/homebrew.zsh"
source "$ZSHCONF/modules/aliases/system.zsh"

# The only $OSTYPE dispatch in the project.
case "$OSTYPE" in
  darwin*) source "$ZSHCONF/modules/os/darwin.zsh" ;;
  linux*)  source "$ZSHCONF/modules/os/linux.zsh" ;;
esac

fpath=("$ZSHCONF/functions" $fpath)
() {
  local -a fns
  fns=("$ZSHCONF"/functions/*(.N:t))
  (( $#fns )) && autoload -Uz -- "${fns[@]}"
}

# Overlay drop-ins, last so they override anything above.
for _zshconf_f in "$ZSHCONF_LOCAL"/local.d/*.zsh(.N); do
  source "$_zshconf_f"
done
unset _zshconf_f

# Recompile stale bytecode in the background. source ignores a .zwc older
# than its source, so a stale one is never used.
{
  for _zshconf_f in "$ZSHCONF"/init.zsh "$ZSHCONF"/modules/**/*.zsh(.N) \
                    "${ZDOTDIR:-$HOME}"/.zcompdump(.N); do
    if [[ -s "$_zshconf_f" && ( ! -f "$_zshconf_f.zwc" || "$_zshconf_f" -nt "$_zshconf_f.zwc" ) ]]; then
      zcompile "$_zshconf_f" 2>/dev/null
    fi
  done
} &!
