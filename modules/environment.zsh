# ── Locale: a UTF-8 default, not an override. A LANG the system or the user
# already set (macOS Language & Region, /etc/locale.conf, a de_DE login) is
# respected; only an empty/unset one gets en_US.UTF-8. A non-UTF-8 LANG
# (e.g. a bare "C" from a minimal container) is upgraded to C.UTF-8 where
# it exists, else en_US.UTF-8 — the prompt and plugins print UTF-8.
if [[ -z "${LANG:-}" ]]; then
  export LANG="en_US.UTF-8"
elif [[ "$LANG" != *[Uu][Tt][Ff]-8* && "$LANG" != *[Uu][Tt][Ff]8* ]]; then
  if [[ -d /usr/share/locale/C.UTF-8 || -d /usr/share/locale/C.utf8 || "$OSTYPE" == darwin* ]]; then
    export LANG="C.UTF-8"
  else
    export LANG="en_US.UTF-8"
  fi
fi
export LC_CTYPE="$LANG"
export TIME_STYLE="long-iso"

# ── Default programs
export EDITOR="nano"           # git commit / rebase todo
export VISUAL="zed --wait"     # mergetool / gh pr edit
export PAGER="less"

# ── Environment
export GPG_TTY=$TTY
export HOMEBREW_NO_ANALYTICS=1

# LS_COLORS feeds eza fallbacks + completion list-colors; macOS ships none.
# Consumed at startup (list-colors zstyle captures it at definition time), so
# a pre-set value — e.g. from the overlay's pre.zsh — is respected, not clobbered.
if [[ -n "$LS_COLORS" ]]; then
  :
elif (( $+commands[vivid] )); then
  export LS_COLORS="$(vivid generate ansi 2>/dev/null)"
else
  export LS_COLORS="di=1;34:ln=1;36:so=1;35:pi=1;33:ex=1;32:bd=1;33:cd=1;33:su=0;41:sg=0;46:tw=0;42:ow=0;43:mi=0;41"
fi
