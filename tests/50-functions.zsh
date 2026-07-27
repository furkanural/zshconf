#!/usr/bin/env zsh
# Function-level tests, for functions with real logic. gbclean: against a
# fixture repo — keeps main + current + unmerged, deletes merged, -f forces.
source "${0:A:h}/lib.zsh"

fpath=("$REPO/functions" $fpath)
autoload -Uz gbclean
source "$REPO/modules/helpers.zsh"

fixture="$TWORK/gitrepo"
mkdir -p "$fixture" && cd "$fixture"
git init -q -b main
git config user.email test@test && git config user.name test
git commit --allow-empty -qm init
git branch merged-at-head                 # points at HEAD → merged
git checkout -qb unmerged-work
git commit --allow-empty -qm extra        # commit main doesn't have
git checkout -q main

gbclean >/dev/null 2>&1
branches="$(git branch --format='%(refname:short)' | sort | tr '\n' ' ')"
t_eq "merged branch deleted, main + unmerged kept" "$branches" "main unmerged-work "

git checkout -qb current-branch
gbclean >/dev/null 2>&1
t_eq "current branch survives" "$(git branch --show-current)" "current-branch"

git checkout -q main
gbclean --force >/dev/null 2>&1
t_eq "--force deletes unmerged too" "$(git branch --format='%(refname:short)' | tr '\n' ' ')" "main "

out=$(gbclean 2>&1)
t_eq "nothing to delete message" "$out" "No branches to delete."
t_done
