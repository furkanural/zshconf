#!/usr/bin/env zsh
# Every file parses; login-path.sh as POSIX sh.
source "${0:A:h}/lib.zsh"

for f in "$REPO"/init.zsh "$REPO"/modules/**/*.zsh(.) "$REPO"/functions/*(.) "$REPO"/completions/*(.N) \
         "$REPO"/install.sh "$REPO"/tests/*.zsh(.); do
  if ! zsh -n "$f" 2>"$TWORK/parse-err"; then
    print -r -- "  FAIL: ${f#$REPO/} does not parse:"
    sed 's/^/    /' "$TWORK/parse-err"
    T_FAIL=1
  fi
done
if ! sh -n "$REPO/login-path.sh" 2>"$TWORK/parse-err"; then
  print -r -- "  FAIL: login-path.sh does not parse as sh:"
  sed 's/^/    /' "$TWORK/parse-err"
  T_FAIL=1
fi
(( T_FAIL )) || print -r -- "  ok: all files parse"

# Startup files must use the /home/[l]inuxbrew glob (autofs stall otherwise).
hits=$(grep -n '/home/linuxbrew' "$REPO"/init.zsh "$REPO"/modules/**/*.zsh(.) | grep -v '^[^:]*:[0-9]*:[[:space:]]*#')
t_eq "no literal /home/linuxbrew in startup files (autofs)" "$hits" ""
t_done
