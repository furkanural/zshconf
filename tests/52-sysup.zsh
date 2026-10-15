#!/usr/bin/env zsh
# sysup: native/topgrade backends, status propagation, and no real updates.
source "${0:A:h}/lib.zsh"

fpath=("$REPO/functions" $fpath)
autoload -Uz sysup

bin="$TWORK/bin"
log="$TWORK/calls"
mkdir -p "$bin" "$TWORK/zdot"
export SYSUP_TEST_LOG="$log"
export ZDOTDIR="$TWORK/zdot"
export ZSHCONF="$TWORK/no-remote"
mkdir -p "$ZSHCONF"
git -C "$ZSHCONF" init -q

print -r -- '#!/bin/sh
print_args() { printf "%s" "$1"; shift; for a in "$@"; do printf " %s" "$a"; done; printf "\n"; }
print_args brew "$@" >> "$SYSUP_TEST_LOG"
[ "$1 $2" = "upgrade --greedy" ] && [ -n "${SYSUP_FAIL_BREW:-}" ] && exit 7
exit 0' > "$bin/brew"
print -r -- '#!/bin/sh
printf "topgrade" >> "$SYSUP_TEST_LOG"
for a in "$@"; do printf " %s" "$a" >> "$SYSUP_TEST_LOG"; done
printf "\n" >> "$SYSUP_TEST_LOG"
exit "${SYSUP_TOPGRADE_RC:-0}"' > "$bin/topgrade"
chmod +x "$bin/brew" "$bin/topgrade"
path=("$bin" $path)
rehash

zinit() { print -r -- "zinit $*" >> "$SYSUP_TEST_LOG" }
_repair_clap_dynamic_completions() { print -r -- "repair" >> "$SYSUP_TEST_LOG" }

: > "$log"
out=$(sysup 2>&1); rc=$?
calls="$(<$log)"
t_eq      "native succeeds"              "$rc" "0"
t_match   "native updates Homebrew"      "$calls" "*brew upgrade --greedy --yes*"
t_match   "native updates Zinit"         "$calls" "*zinit update --all*"
t_nomatch "native does not use Topgrade" "$calls" "*topgrade*"
t_match   "native summary"               "$out" "*homebrew: ok*zinit: ok*"

: > "$log"
out=$(sysup --topgrade 2>&1); rc=$?
calls="$(<$log)"
t_eq      "topgrade succeeds"                "$rc" "0"
t_eq      "only plain topgrade + repair run" "$calls" "topgrade
repair"
t_match   "topgrade summary"                 "$out" "*topgrade: ok*completions: refreshed*"

: > "$log"
out=$(SYSUP_FAIL_BREW=1 sysup 2>&1); rc=$?
t_eq    "native failure returns nonzero" "$rc" "1"
t_match "native failure summarized"     "$out" "*homebrew: failed*Finished with failures*"

out=$(SYSUP_TOPGRADE_RC=9 sysup --topgrade 2>&1); rc=$?
t_eq    "topgrade failure returns nonzero" "$rc" "1"
t_match "topgrade failure summarized"     "$out" "*topgrade: failed*"

out=$(sysup --bogus 2>&1); rc=$?
t_eq    "unknown option rejected" "$rc" "2"
t_match "unknown option explained" "$out" "*unknown option: --bogus*"

SYSUP_BACKEND=topgrade
: > "$log"
out=$(sysup 2>&1); rc=$?
t_match "SYSUP_BACKEND selects Topgrade" "$(<$log)" "*topgrade*"
: > "$log"
out=$(sysup --native 2>&1); rc=$?
t_nomatch "--native overrides SYSUP_BACKEND" "$(<$log)" "*topgrade*"
unset SYSUP_BACKEND

# Minimal PATH so a real topgrade on the host is never found (or run).
rm -f "$bin/topgrade"
path=("$bin" /usr/bin /bin)
rehash
out=$(sysup --topgrade 2>&1); rc=$?
t_eq    "missing Topgrade fails"     "$rc" "1"
t_match "missing Topgrade explained" "$out" '*topgrade: failed \(not installed\)*'
t_done
