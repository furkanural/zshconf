#!/usr/bin/env zsh
# install.sh scenarios against a sandbox HOME. The installer only touches
# $HOME and $XDG_CONFIG_HOME, so this never sees the real machine.
source "${0:A:h}/lib.zsh"

fake="$TWORK/home"
mkdir -p "$fake"
run_installer() { HOME="$fake" XDG_CONFIG_HOME= zsh "$REPO/install.sh" >"$TWORK/install.log" 2>&1 }

# 1. Fresh install
run_installer
t_eq "fresh: stub written"      "$(grep -c "ZSHCONF=\"$REPO\"" $fake/.zshrc)" "1"
t_eq "fresh: overlay dir made"  "$([[ -d $fake/.config/zsh/local.d ]]; echo $(( ! $? )))" "1"

# 2. Idempotent re-run
before="$(<$fake/.zshrc)"
run_installer
t_eq "idempotent: stub unchanged"  "$(<$fake/.zshrc)" "$before"
t_eq "idempotent: no backup made"  "$(print -rl -- $fake/.zshrc.pre-zshconf*(N) | grep -c .)" "0"

# 3. Existing config is backed up; its stale bytecode removed
print -r -- "# precious old config" >| "$fake/.zshrc"
touch "$fake/.zshrc.zwc"
run_installer
t_eq "backup: old config preserved" "$(<$fake/.zshrc.pre-zshconf)" "# precious old config"
t_eq "backup: stub written"         "$(grep -c 'Managed by' $fake/.zshrc)" "1"
t_eq "backup: stale zwc removed"    "$([[ -f $fake/.zshrc.zwc ]]; echo $?)" "1"

# 4. A second backup gets a timestamp instead of clobbering the first
print -r -- "# another old config" >| "$fake/.zshrc"
run_installer
t_eq "double backup: both kept" "$(print -rl -- $fake/.zshrc.pre-zshconf*(N) | grep -c .)" "2"

# 5. Our stub with a stale repo path is refreshed in place
print -r -- "# Managed by the zsh-config installer — x
export ZSHCONF=\"/old/gone/path\"
[[ -r \"\$ZSHCONF/init.zsh\" ]] && source \"\$ZSHCONF/init.zsh\"" >| "$fake/.zshrc"
run_installer
t_eq "stale stub: repointed"       "$(grep -c "ZSHCONF=\"$REPO\"" $fake/.zshrc)" "1"
t_eq "stale stub: no extra backup" "$(print -rl -- $fake/.zshrc.pre-zshconf*(N) | grep -c .)" "2"
t_done
