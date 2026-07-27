#!/usr/bin/env zsh
# bench.zsh — self-contained startup benchmark (replaces zsh-bench, which
# deadlocks against zinit turbo mode — romkatv/zsh-bench#34 — and even on
# empty configs in headless containers — romkatv/zsh-bench#31).
#
# Two metrics, $ITERS samples each, min/median reported:
#   eager  — zsh -i -c exit: rc files sourced, turbo tiers still queued
#   full   — prompt cycles fed until turbo tiers have fired (plugins loaded)
#
# Run from anywhere; expects the config already installed (~/.zshrc stub)
# and warmed (zinit + plugins cloned — cold network clones would dominate).

emulate -L zsh
zmodload zsh/datetime || exit 1

typeset -ri ITERS=${ITERS:-10}

# time_boot <mode>: one sample, prints milliseconds (integer)
time_boot() {
  local -F start end
  start=$EPOCHREALTIME
  if [[ $1 == eager ]]; then
    zsh -i -c exit >/dev/null 2>&1
  else
    # Feed prompt cycles so zinit's turbo tiers fire, then exit.
    { for _ in {1..30}; do print 'sleep 0.1'; done; print 'exit' } | \
      zsh -i >/dev/null 2>&1
  fi
  end=$EPOCHREALTIME
  print -r -- $(( (end - start) * 1000 ))
}

# median <numbers...>
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
