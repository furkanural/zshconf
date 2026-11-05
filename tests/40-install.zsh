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

# 6. Fresh install also wires ~/.zprofile and creates env.zsh. The block
#    sources login-path.sh BEFORE env.zsh (env.zsh may call brew/mise tools).
t_eq "fresh: zprofile block"       "$(has $fake/.zprofile 'zshconf env (managed by install.sh), v2')" "1"
t_eq "fresh: zprofile sources login-path" "$(has $fake/.zprofile ". \"$REPO/login-path.sh\"")" "1"
t_eq "fresh: login-path before env.zsh"   "$(grep -n 'login-path.sh\|env.zsh' $fake/.zprofile | head -1 | grep -c login-path)" "1"
t_eq "fresh: env.zsh created"      "$([[ -f $fake/.config/zsh/env.zsh ]]; echo $(( ! $? )))" "1"
t_eq "fresh: zprofile parses as zsh" "$(zsh -n $fake/.zprofile 2>&1; echo $?)" "0"

# 7. Idempotent re-run leaves ~/.zprofile untouched
zprof_before="$(cat $fake/.zprofile)"
run_installer
t_eq "idempotent: zprofile unchanged" "$(cat $fake/.zprofile)" "$zprof_before"

# 8. Existing ~/.zprofile content is preserved; the block is appended
print -r -- 'eval "$(/opt/homebrew/bin/brew shellenv)"' >| "$fake/.zprofile"
run_installer
t_eq "append: brew line preserved" "$(has $fake/.zprofile 'brew shellenv')" "1"
t_eq "append: block appended"      "$(has $fake/.zprofile 'zshconf env (managed by install.sh), v')" "1"

# 9. A stale block is replaced in place; content around it survives. v1 is
#    the real previous shape (env.zsh only), so this doubles as the
#    v1→v2 migration test.
print -r -- 'eval "$(/opt/homebrew/bin/brew shellenv)"

# >>> # zshconf env (managed by install.sh), v1 >>>
if [[ -z ${ZSHCONF_ENV_SOURCED:-} && -r "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/env.zsh" ]]; then
  ZSHCONF_ENV_SOURCED=1
  source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/env.zsh"
fi
# <<< # zshconf env (managed by install.sh) <<<
export TAIL_KEEP=1' >| "$fake/.zprofile"
run_installer
t_eq "stale: old version gone"  "$(has $fake/.zprofile 'v1 >>>')" "0"
t_eq "stale: current version"   "$(has $fake/.zprofile 'zshconf env (managed by install.sh), v2')" "1"
t_eq "stale: login-path added"  "$(has $fake/.zprofile 'login-path.sh')" "1"
t_eq "stale: env.zsh still sourced" "$(has $fake/.zprofile 'zsh/env.zsh')" "1"
t_eq "stale: one block only"    "$(grep -c 'zshconf env (managed by install.sh), v' $fake/.zprofile | tr -d ' ')" "1"
t_eq "stale: brew line kept"    "$(has $fake/.zprofile 'brew shellenv')" "1"
t_eq "stale: tail content kept" "$(has $fake/.zprofile 'TAIL_KEEP=1')" "1"

# 10. Fresh install writes the login-bash stub to ~/.bash_profile (it was
#     created by run 1; the file is where macOS login bash looks first).
#     Like the ~/.zshrc stub: one line that sources the repo, no logic.
t_eq "bash: stub in .bash_profile"  "$(has $fake/.bash_profile 'zshconf bash-login (managed by install.sh), v3')" "1"
t_eq "bash: stub sources repo file" "$(has $fake/.bash_profile ". \"$REPO/login-path.sh\"")" "1"
t_eq "bash: stub is one line"       "$(grep -vc '^#' $fake/.bash_profile | tr -d ' ')" "1"
t_eq "bash: stub parses as bash"    "$(bash -n $fake/.bash_profile 2>&1; echo $?)" "0"
t_eq "bash: stub parses as sh"      "$(sh -n $fake/.bash_profile 2>&1; echo $?)" "0"
t_eq "bash: no .profile invented"   "$([[ -e $fake/.profile ]]; echo $?)" "1"

# 11. login-path.sh puts mise shims and Homebrew ahead of an inherited
#     path_helper-style PATH, as `bash -lc` / `zsh -lc` under /etc/profile
#     would see it — in all three shells it can be sourced from. Fake
#     brew/mise: a copy of the file with its first brew candidate repointed,
#     the way another prefix would differ; mise found via ~/.local/bin.
mkdir -p "$fake/fakebrew/bin" "$fake/.local/bin"
print -r -- '#!/bin/sh
echo "export PATH=\"'"$fake"'/fakebrew/bin:\$PATH\""' >| "$fake/fakebrew/bin/brew"
print -r -- '#!/bin/sh
echo "export PATH=\"'"$fake"'/.local/share/mise/shims:\$PATH\""' >| "$fake/.local/bin/mise"
chmod +x "$fake/fakebrew/bin/brew" "$fake/.local/bin/mise"
sed "s|/opt/homebrew/bin/brew|$fake/fakebrew/bin/brew|" "$REPO/login-path.sh" >| "$TWORK/login-path.sh"
for sh_ in "bash --noprofile --norc" "zsh -f" "sh"; do
  out="$(env -i HOME="$fake" PATH="/usr/bin:/bin" ${=sh_} -c ". '$TWORK/login-path.sh'; printf '%s' \"\$PATH\"")"
  t_match "${sh_%% *}: mise shims first"      "$out" "$fake/.local/share/mise/shims:*"
  t_match "${sh_%% *}: brew before /usr/bin"  "$out" "*$fake/fakebrew/bin:*/usr/bin*"
  t_nomatch "${sh_%% *}: no leaked temp vars" "$(env -i HOME="$fake" PATH="/usr/bin:/bin" ${=sh_} -c ". '$TWORK/login-path.sh'; set | grep -v EXECUTION_STRING")" "*_zshconf_[bm]*"
done
# Guard: sourcing twice does not prepend twice.
out="$(env -i HOME="$fake" PATH="/usr/bin:/bin" sh -c ". '$TWORK/login-path.sh'; . '$TWORK/login-path.sh'; printf '%s' \"\$PATH\"")"
t_eq "guard: shims once" "$(print -r -- "$out" | tr ':' '\n' | grep -c mise/shims)" "1"

# 12. A stub pointing at a moved repo is refreshed (same version, wrong path).
sed -i.bak "s|$REPO/login-path.sh|/old/gone/login-path.sh|g" "$fake/.bash_profile" && rm -f "$fake/.bash_profile.bak"
run_installer
t_eq "moved repo: stub repointed" "$(has $fake/.bash_profile ". \"$REPO/login-path.sh\"")" "1"
t_eq "moved repo: old path gone"  "$(has $fake/.bash_profile '/old/gone/')" "0"

# 13. Older blocks migrate to the v3 stub in place; the user's own lines
#     around them survive. v1 inlined the logic; v2 sourced bash-login.sh.
print -r -- 'export PATH=$PATH:$HOME/.maestro/bin

# >>> # zshconf bash-login (managed by install.sh), v1 >>>
for _zshconf_brew in /opt/homebrew/bin/brew; do
  if [ -x "$_zshconf_brew" ]; then eval "$("$_zshconf_brew" shellenv)"; break; fi
done
unset _zshconf_brew
# <<< # zshconf bash-login (managed by install.sh) <<<
export TAIL_KEEP=1' >| "$fake/.bash_profile"
run_installer
t_eq "v1→v3: v1 gone"           "$(has $fake/.bash_profile 'v1 >>>')" "0"
t_eq "v1→v3: inline logic gone" "$(has $fake/.bash_profile '_zshconf_brew')" "0"
t_eq "v1→v3: v3 stub present"   "$(has $fake/.bash_profile ". \"$REPO/login-path.sh\"")" "1"
t_eq "v1→v3: head line kept"    "$(has $fake/.bash_profile 'maestro/bin')" "1"
t_eq "v1→v3: tail line kept"    "$(has $fake/.bash_profile 'TAIL_KEEP=1')" "1"

print -r -- '# >>> # zshconf bash-login (managed by install.sh), v2 >>>
[ -r "'"$REPO"'/bash-login.sh" ] && . "'"$REPO"'/bash-login.sh"
# <<< # zshconf bash-login (managed by install.sh) <<<' >| "$fake/.bash_profile"
run_installer
t_eq "v2→v3: old file gone"     "$(has $fake/.bash_profile 'bash-login.sh')" "0"
t_eq "v2→v3: v3 stub present"   "$(has $fake/.bash_profile ". \"$REPO/login-path.sh\"")" "1"

# 14. An existing ~/.profile and no ~/.bash_profile: the stub goes to
#     ~/.profile (what login bash would read) instead of shadowing it.
fake2="$TWORK/home2"
mkdir -p "$fake2"
print -r -- 'export KEEP_PROFILE=1' >| "$fake2/.profile"
HOME="$fake2" XDG_CONFIG_HOME= zsh "$REPO/install.sh" >"$TWORK/install2.log" 2>&1
t_eq "profile: no .bash_profile created" "$([[ -e $fake2/.bash_profile ]]; echo $?)" "1"
t_eq "profile: stub appended"            "$(has $fake2/.profile 'zshconf bash-login (managed by install.sh), v3')" "1"
t_eq "profile: user line kept"           "$(has $fake2/.profile 'KEEP_PROFILE=1')" "1"

# 15. Both ~/.bash_profile and ~/.profile exist: bash reads only the first,
#     `sh -l` only the second — both get the stub.
fake3="$TWORK/home3"
mkdir -p "$fake3"
print -r -- 'export BP=1' >| "$fake3/.bash_profile"
print -r -- 'export PR=1' >| "$fake3/.profile"
HOME="$fake3" XDG_CONFIG_HOME= zsh "$REPO/install.sh" >"$TWORK/install3.log" 2>&1
t_eq "both: .bash_profile stubbed" "$(has $fake3/.bash_profile 'zshconf bash-login (managed by install.sh), v3')" "1"
t_eq "both: .profile stubbed"      "$(has $fake3/.profile 'zshconf bash-login (managed by install.sh), v3')" "1"
t_eq "both: user lines kept"       "$(has $fake3/.bash_profile 'BP=1')$(has $fake3/.profile 'PR=1')" "11"
t_done
