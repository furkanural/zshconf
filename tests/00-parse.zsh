#!/usr/bin/env zsh
# Layer 1: every file must parse (zsh -n).
source "${0:A:h}/lib.zsh"

for f in "$REPO"/init.zsh "$REPO"/modules/**/*.zsh(.) "$REPO"/functions/*(.) \
         "$REPO"/install.sh "$REPO"/tests/*.zsh(.); do
  if ! zsh -n "$f" 2>"$TWORK/parse-err"; then
    print -r -- "  FAIL: ${f#$REPO/} does not parse:"
    sed 's/^/    /' "$TWORK/parse-err"
    T_FAIL=1
  fi
done
(( T_FAIL )) || print -r -- "  ok: all files parse"
t_done
