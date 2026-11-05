#!/usr/bin/env zsh
# The env seam: ~/.config/zsh/env.zsh is visible to interactive boots (via
# init.zsh) and to login shells (via the ~/.zprofile block), and must run
# exactly once when both apply.
source "${0:A:h}/lib.zsh"

t_make_zdot "$TWORK/zdot"
xdg="$TWORK/xdg"
mkdir -p "$xdg/zsh"
printf 'export T_ENV_SEEN=1\nT_ENV_RUNS=$(( ${T_ENV_RUNS:-0} + 1 ))\n' > "$xdg/zsh/env.zsh"

# 1. Interactive (non-login) boot: init.zsh sources env.zsh
out=$(t_boot "$TWORK/zdot" "$xdg" 'print -r -- "seen=$T_ENV_SEEN runs=$T_ENV_RUNS"')
t_eq "interactive boot sees env.zsh" "$out" "seen=1 runs=1"

# 2. Login+interactive boot: the ~/.zprofile block runs it, init.zsh's
#    guard must skip it — the side-effect counter proves it ran once.
#    The fixture is the installer's current (v2) block shape.
print -r -- "# >>> zshconf env (managed by install.sh), v2 >>>
[ -r \"$REPO/login-path.sh\" ] && . \"$REPO/login-path.sh\"
if [[ -z \${ZSHCONF_ENV_SOURCED:-} && -r \"$xdg/zsh/env.zsh\" ]]; then
  ZSHCONF_ENV_SOURCED=1
  source \"$xdg/zsh/env.zsh\"
fi
# <<< zshconf env (managed by install.sh) <<<" > "$TWORK/zdot/.zprofile"

out=$(ZDOTDIR="$TWORK/zdot" XDG_CONFIG_HOME="$xdg" zsh -l -i -c 'print -r -- "seen=$T_ENV_SEEN runs=$T_ENV_RUNS"' 2>/dev/null)
t_eq "login+interactive runs env.zsh exactly once" "$out" "seen=1 runs=1"

# 3. Login, NON-interactive zsh (`zsh -lc`, how GUI apps read the env):
#    never reaches ~/.zshrc, so ~/.zprofile alone must deliver env.zsh and
#    login-path.sh. Verified by what login-path.sh exports and a clean stderr.
#    stderr merged in: any complaint would break the exact match.
out=$(ZDOTDIR="$TWORK/zdot" XDG_CONFIG_HOME="$xdg" zsh -l -c 'print -r -- "seen=$T_ENV_SEEN lp=$ZSHCONF_LOGIN_PATH_SOURCED"' 2>&1)
t_eq "zsh -lc: env.zsh + login-path.sh sourced, stderr clean" "$out" "seen=1 lp=1"
t_done
