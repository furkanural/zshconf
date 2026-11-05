#!/usr/bin/env zsh
# install.sh scenarios against a sandbox HOME. The installer only touches
# $HOME and $XDG_CONFIG_HOME, so this never sees the real machine.
source "${0:A:h}/lib.zsh"

fake="$TWORK/home"
mkdir -p "$fake"
run_installer() { HOME="$fake" XDG_CONFIG_HOME= zsh "$REPO/install.sh" >"$TWORK/install.log" 2>&1 }
# Substring assertion helper — no external grep (environments that shadow
# grep with ugrep eat leading-'#' patterns as comments).
has() { local c; c="$(cat "$1")"; [[ "$c" == *"$2"* ]] && print 1 || print 0 }

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
print -r -- "# Managed by the zshconf installer — x
export ZSHCONF=\"/old/gone/path\"
[[ -r \"\$ZSHCONF/init.zsh\" ]] && source \"\$ZSHCONF/init.zsh\"" >| "$fake/.zshrc"
run_installer
t_eq "stale stub: repointed"       "$(grep -c "ZSHCONF=\"$REPO\"" $fake/.zshrc)" "1"
t_eq "stale stub: no extra backup" "$(print -rl -- $fake/.zshrc.pre-zshconf*(N) | grep -c .)" "2"

# 6. Fresh install also wires ~/.zprofile and creates env.zsh
t_eq "fresh: zprofile block"  "$(has $fake/.zprofile 'zshconf env (managed by install.sh), v')" "1"
t_eq "fresh: env.zsh created" "$([[ -f $fake/.config/zsh/env.zsh ]]; echo $(( ! $? )))" "1"

# 7. Idempotent re-run leaves ~/.zprofile untouched
zprof_before="$(cat $fake/.zprofile)"
run_installer
t_eq "idempotent: zprofile unchanged" "$(cat $fake/.zprofile)" "$zprof_before"

# 8. Existing ~/.zprofile content is preserved; the block is appended
print -r -- 'eval "$(/opt/homebrew/bin/brew shellenv)"' >| "$fake/.zprofile"
run_installer
t_eq "append: brew line preserved" "$(has $fake/.zprofile 'brew shellenv')" "1"
t_eq "append: block appended"      "$(has $fake/.zprofile 'zshconf env (managed by install.sh), v')" "1"

# 9. A stale block is replaced in place; content around it survives
print -r -- 'eval "$(/opt/homebrew/bin/brew shellenv)"

# >>> # zshconf env (managed by install.sh), v0 >>>
echo stale-body
# <<< # zshconf env (managed by install.sh) <<<
export TAIL_KEEP=1' >| "$fake/.zprofile"
run_installer
t_eq "stale: old version gone"  "$(has $fake/.zprofile 'v0 >>>')" "0"
t_eq "stale: body replaced"     "$(has $fake/.zprofile 'stale-body')" "0"
t_eq "stale: current version"   "$(has $fake/.zprofile 'zshconf env (managed by install.sh), v1')" "1"
t_eq "stale: brew line kept"    "$(has $fake/.zprofile 'brew shellenv')" "1"
t_eq "stale: tail content kept" "$(has $fake/.zprofile 'TAIL_KEEP=1')" "1"

# 10. Fresh install writes the login-bash stub to ~/.bash_profile (it was
#     created by run 1; the file is where macOS login bash looks first).
#     Like the ~/.zshrc stub: one line that sources the repo, no logic.
t_eq "bash: stub in .bash_profile"  "$(has $fake/.bash_profile 'zshconf bash-login (managed by install.sh), v2')" "1"
t_eq "bash: stub sources repo file" "$(has $fake/.bash_profile ". \"$REPO/bash-login.sh\"")" "1"
t_eq "bash: stub is one line"       "$(grep -vc '^#' $fake/.bash_profile | tr -d ' ')" "1"
t_eq "bash: stub parses as bash"    "$(bash -n $fake/.bash_profile 2>&1; echo $?)" "0"
t_eq "bash: stub parses as sh"      "$(sh -n $fake/.bash_profile 2>&1; echo $?)" "0"
t_eq "bash: repo file parses as sh" "$(sh -n $REPO/bash-login.sh 2>&1; echo $?)" "0"

# 11. bash-login.sh puts mise shims and Homebrew ahead of an inherited
#     path_helper-style PATH, as `bash -lc` under /etc/profile would see it.
#     Fake brew/mise: a copy of the file with its first brew candidate
#     repointed, the way another prefix would differ; mise found via ~/.local/bin.
mkdir -p "$fake/fakebrew/bin" "$fake/.local/bin"
print -r -- '#!/bin/sh
echo "export PATH=\"'"$fake"'/fakebrew/bin:\$PATH\""' >| "$fake/fakebrew/bin/brew"
print -r -- '#!/bin/sh
echo "export PATH=\"'"$fake"'/.local/share/mise/shims:\$PATH\""' >| "$fake/.local/bin/mise"
chmod +x "$fake/fakebrew/bin/brew" "$fake/.local/bin/mise"
sed "s|/opt/homebrew/bin/brew|$fake/fakebrew/bin/brew|" "$REPO/bash-login.sh" >| "$TWORK/bash-login.sh"
out="$(env -i HOME="$fake" PATH="/usr/bin:/bin" bash --noprofile --norc -c "source '$TWORK/bash-login.sh'; printf '%s' \"\$PATH\"")"
t_match "bash: mise shims first"      "$out" "$fake/.local/share/mise/shims:*"
t_match "bash: brew before /usr/bin"  "$out" "*$fake/fakebrew/bin:*/usr/bin*"
t_nomatch "bash: no leaked temp vars" "$(env -i HOME="$fake" PATH="/usr/bin:/bin" bash --noprofile --norc -c "source '$TWORK/bash-login.sh'; set" )" "*_zshconf_*"

# 12. A stub pointing at a moved repo is refreshed (same version, wrong path).
sed -i.bak "s|$REPO/bash-login.sh|/old/gone/bash-login.sh|g" "$fake/.bash_profile" && rm -f "$fake/.bash_profile.bak"
run_installer
t_eq "moved repo: stub repointed" "$(has $fake/.bash_profile ". \"$REPO/bash-login.sh\"")" "1"
t_eq "moved repo: old path gone"  "$(has $fake/.bash_profile '/old/gone/')" "0"

# 13. A v1 block (logic inlined, several lines) migrates to the v2 stub in
#     place; the user's own lines around it survive.
print -r -- 'export PATH=$PATH:$HOME/.maestro/bin

# >>> # zshconf bash-login (managed by install.sh), v1 >>>
for _zshconf_brew in /opt/homebrew/bin/brew; do
  if [ -x "$_zshconf_brew" ]; then eval "$("$_zshconf_brew" shellenv)"; break; fi
done
unset _zshconf_brew
# <<< # zshconf bash-login (managed by install.sh) <<<
export TAIL_KEEP=1' >| "$fake/.bash_profile"
run_installer
t_eq "v1→v2: v1 gone"          "$(has $fake/.bash_profile 'v1 >>>')" "0"
t_eq "v1→v2: inline logic gone" "$(has $fake/.bash_profile '_zshconf_brew')" "0"
t_eq "v1→v2: v2 stub present"   "$(has $fake/.bash_profile ". \"$REPO/bash-login.sh\"")" "1"
t_eq "v1→v2: head line kept"    "$(has $fake/.bash_profile 'maestro/bin')" "1"
t_eq "v1→v2: tail line kept"    "$(has $fake/.bash_profile 'TAIL_KEEP=1')" "1"

# 14. An existing ~/.profile and no ~/.bash_profile: the stub goes to
#     ~/.profile (what login bash would read) instead of shadowing it.
fake2="$TWORK/home2"
mkdir -p "$fake2"
print -r -- 'export KEEP_PROFILE=1' >| "$fake2/.profile"
HOME="$fake2" XDG_CONFIG_HOME= zsh "$REPO/install.sh" >"$TWORK/install2.log" 2>&1
t_eq "profile: no .bash_profile created" "$([[ -e $fake2/.bash_profile ]]; echo $?)" "1"
t_eq "profile: stub appended"            "$(has $fake2/.profile 'zshconf bash-login (managed by install.sh), v2')" "1"
t_eq "profile: user line kept"           "$(has $fake2/.profile 'KEEP_PROFILE=1')" "1"
t_done
