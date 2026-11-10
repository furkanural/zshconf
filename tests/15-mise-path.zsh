#!/usr/bin/env zsh
# Zinit's prefix must not outrank mise, even after turbo tiers converge.
source "${0:A:h}/lib.zsh"

t_make_zdot "$TWORK/zdot"
mkdir -p "$TWORK/xdg/zsh" "$TWORK/bin" "$TWORK/polaris/bin" "$TWORK/polaris/sbin" "$TWORK/mise-tools"

# Keep the command guard active on bare CI; the function below supplies
# deterministic activation output without depending on a mise installation.
printf '#!/bin/sh\nexit 0\n' > "$TWORK/bin/mise"
chmod +x "$TWORK/bin/mise"
cat > "$TWORK/xdg/zsh/pre.zsh" <<EOF
path=("$TWORK/bin" \$path)
export ZPFX="$TWORK/polaris"
mise() {
  [[ "\$*" == 'activate zsh' ]] || return 1
  print -r -- '(( T_MISE_ACTIVATIONS++ ))'
  print -r -- 'path=("$TWORK/mise-tools" \$path)'
}
EOF

probe='
print -r -- "activations=$T_MISE_ACTIVATIONS"
print -r -- "mise_first=$([[ $path[1] == ${ZPFX:h}/mise-tools ]] && print 1 || print 0)"
print -r -- "polaris_bin=${path[(Ie)$ZPFX/bin]}"
print -r -- "polaris_sbin=${path[(Ie)$ZPFX/sbin]}"
'

out=$(t_boot "$TWORK/zdot" "$TWORK/xdg" "$probe")
t_eq "stderr is empty" "$(cat -- "$TWORK/stderr")" ""
t_match "mise activates once at startup" "$out" '*activations=1*'
t_match "mise precedes Zinit at startup" "$out" '*mise_first=1*'
t_match "Zinit bin remains on PATH" "$out" '*polaris_bin=<2->*'
t_match "Zinit sbin remains on PATH" "$out" '*polaris_sbin=<2->*'

out=$(t_boot_tiers "$TWORK/zdot" "$TWORK/xdg" "$probe"'
print -r -- "pending=${+functions[_autosuggest_rebind]}"
')
t_match "turbo tiers converge" "$out" '*pending=0*'
t_match "mise still activated only once after tiers" "$out" '*activations=1*'
t_match "mise still precedes Zinit after tiers" "$out" '*mise_first=1*'
t_done
