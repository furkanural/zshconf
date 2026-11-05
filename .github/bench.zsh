#!/usr/bin/env zsh
# Startup benchmark: eager (zsh -i -c exit) and full (prompt cycles until the
# turbo tiers fire), min/median of $ITERS. Expects an installed, warmed config.
# Replaces zsh-bench, which deadlocks against zinit turbo (romkatv/zsh-bench#34).

emulate -L zsh
zmodload zsh/datetime || exit 1

typeset -ri ITERS=${ITERS:-10}

time_boot() {
  local -F start end
  start=$EPOCHREALTIME
  if [[ $1 == eager ]]; then
    zsh -i -c exit >/dev/null 2>&1
  else
    { for _ in {1..30}; do print 'sleep 0.1'; done; print 'exit' } | \
      zsh -i >/dev/null 2>&1
  fi
  end=$EPOCHREALTIME
  print -r -- $(( (end - start) * 1000 ))
}

median() {
  local -a sorted=(${$(print -l -- "$@" | sort -n)})
  print -r -- ${sorted[$(( ($#sorted + 1) / 2 ))]}
}

local mode
local -a samples sorted
print '## Startup benchmark'
print
print '| metric | min | median |'
print '| --- | ---: | ---: |'
for mode in eager full; do
  samples=()
  for _ in {1..$ITERS}; do
    samples+=($(time_boot $mode))
  done
  sorted=(${(n)samples})
  printf '| %s boot | %.0f ms | %.0f ms |\n' "$mode" "$sorted[1]" "$(median $samples)"
done
