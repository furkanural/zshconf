#!/usr/bin/env zsh
# env.zsh reaches interactive and login shells, exactly once each.
source "${0:A:h}/lib.zsh"

t_make_zdot "$TWORK/zdot"
xdg="$TWORK/xdg"
mkdir -p "$xdg/zsh"
printf 'export T_ENV_SEEN=1\nT_ENV_RUNS=$(( ${T_ENV_RUNS:-0} + 1 ))\n' > "$xdg/zsh/env.zsh"

out=$(t_boot "$TWORK/zdot" "$xdg" 'print -r -- "seen=$T_ENV_SEEN runs=$T_ENV_RUNS"')
t_eq "interactive boot sees env.zsh" "$out" "seen=1 runs=1"

# Login+interactive: the ~/.zprofile block (current shape) runs it once.
print -r -- "# >>> zshconf env (managed by install.sh), v2 >>>
[ -r \"$REPO/login-path.sh\" ] && . \"$REPO/login-path.sh\"
if [[ -z \${ZSHCONF_ENV_SOURCED:-} && -r \"$xdg/zsh/env.zsh\" ]]; then
  ZSHCONF_ENV_SOURCED=1
  source \"$xdg/zsh/env.zsh\"
fi
# <<< zshconf env (managed by install.sh) <<<" > "$TWORK/zdot/.zprofile"

out=$(ZDOTDIR="$TWORK/zdot" XDG_CONFIG_HOME="$xdg" zsh -l -i -c 'print -r -- "seen=$T_ENV_SEEN runs=$T_ENV_RUNS"' 2>/dev/null)
t_eq "login+interactive runs env.zsh exactly once" "$out" "seen=1 runs=1"

# `zsh -lc` (GUI apps): ~/.zprofile alone delivers both; stderr merged in.
out=$(ZDOTDIR="$TWORK/zdot" XDG_CONFIG_HOME="$xdg" zsh -l -c 'print -r -- "seen=$T_ENV_SEEN lp=$ZSHCONF_LOGIN_PATH_SOURCED"' 2>&1)
t_eq "zsh -lc: env.zsh + login-path.sh sourced, stderr clean" "$out" "seen=1 lp=1"
t_done
