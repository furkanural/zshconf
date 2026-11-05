#!/usr/bin/env zsh
# Layer 1: every file must parse (zsh -n).
source "${0:A:h}/lib.zsh"

for f in "$REPO"/init.zsh "$REPO"/modules/**/*.zsh(.) "$REPO"/functions/*(.) "$REPO"/completions/*(.N) \
         "$REPO"/install.sh "$REPO"/tests/*.zsh(.); do
  if ! zsh -n "$f" 2>"$TWORK/parse-err"; then
    print -r -- "  FAIL: ${f#$REPO/} does not parse:"
    sed 's/^/    /' "$TWORK/parse-err"
    T_FAIL=1
  fi
done
# bash-login.sh is POSIX sh (sourced by login bash, maybe `sh -l`): check with sh.
if ! sh -n "$REPO/bash-login.sh" 2>"$TWORK/parse-err"; then
  print -r -- "  FAIL: bash-login.sh does not parse as sh:"
  sed 's/^/    /' "$TWORK/parse-err"
  T_FAIL=1
fi
(( T_FAIL )) || print -r -- "  ok: all files parse"

# A literal /home/linuxbrew lookup triggers macOS's autofs automounter
# (~50 ms per startup); the startup path must use the /home/[l]inuxbrew glob.
# bash-login.sh is exempt: POSIX sh has no (N) glob, and its linuxbrew probe
# is the last candidate, reached only when no other brew exists.
hits=$(grep -n '/home/linuxbrew' "$REPO"/init.zsh "$REPO"/modules/**/*.zsh(.) | grep -v '^[^:]*:[0-9]*:[[:space:]]*#')
t_eq "no literal /home/linuxbrew in startup files (autofs)" "$hits" ""
t_done
