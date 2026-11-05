# Locale: keep a UTF-8 LANG the system set; default an empty one; upgrade a
# non-UTF-8 one (C, POSIX).
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

export EDITOR="nano"
export VISUAL="zed --wait"
export PAGER="less"

export GPG_TTY=$TTY
export HOMEBREW_NO_ANALYTICS=1

# A pre-set LS_COLORS (overlay pre.zsh) wins; completion-styles reads it at
# definition time.
if [[ -n "$LS_COLORS" ]]; then
  :
elif (( $+commands[vivid] )); then
  export LS_COLORS="$(vivid generate ansi 2>/dev/null)"
else
  export LS_COLORS="di=1;34:ln=1;36:so=1;35:pi=1;33:ex=1;32:bd=1;33:cd=1;33:su=0;41:sg=0;46:tw=0;42:ow=0;43:mi=0;41"
fi
