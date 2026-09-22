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
print -r -- "# >>> zshconf env (managed by install.sh), v1 >>>
if [[ -z \${ZSHCONF_ENV_SOURCED:-} && -r \"$xdg/zsh/env.zsh\" ]]; then
  ZSHCONF_ENV_SOURCED=1
  source \"$xdg/zsh/env.zsh\"
fi
# <<< zshconf env (managed by install.sh) <<<" > "$TWORK/zdot/.zprofile"

out=$(ZDOTDIR="$TWORK/zdot" XDG_CONFIG_HOME="$xdg" zsh -l -i -c 'print -r -- "seen=$T_ENV_SEEN runs=$T_ENV_RUNS"' 2>/dev/null)
t_eq "login+interactive runs env.zsh exactly once" "$out" "seen=1 runs=1"
t_done
