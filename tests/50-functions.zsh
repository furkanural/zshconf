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

# Branches checked out in another worktree (marked '+') must be skipped —
# git would refuse anyway, but gbclean shouldn't even attempt them.
git branch wt-branch
git worktree add -q "$TWORK/wt" wt-branch
out=$(gbclean 2>&1)
t_eq      "worktree branch survives"      "$(git branch --list wt-branch --format='%(refname:short)')" "wt-branch"
t_nomatch "worktree branch not attempted" "$out" "*cannot delete*"
out=$(gbclean --force 2>&1)
t_eq      "worktree branch survives --force" "$(git branch --list wt-branch --format='%(refname:short)')" "wt-branch"
t_nomatch "not attempted under --force"      "$out" "*cannot delete*"
git worktree remove "$TWORK/wt"

git checkout -q main
gbclean --force >/dev/null 2>&1
t_eq "--force deletes unmerged too" "$(git branch --format='%(refname:short)' | tr '\n' ' ')" "main "

out=$(gbclean 2>&1)
t_eq "nothing to delete message" "$out" "No branches to delete."

# zshconf-update: refuses uncommitted edits (which --ff-only alone would let
# through when upstream doesn't touch the file), fast-forwards when clean.
autoload -Uz zshconf-update
upstream="$TWORK/upstream" clone="$TWORK/clone"
git init -q -b main "$upstream"
git -C "$upstream" config user.email test@test
git -C "$upstream" config user.name test
print a > "$upstream/a.zsh" && print b > "$upstream/b.zsh"
git -C "$upstream" add . && git -C "$upstream" commit -qm init
git clone -q "$upstream" "$clone"
print a2 > "$upstream/a.zsh" && git -C "$upstream" commit -qam "touch a only"

print local-edit >> "$clone/b.zsh"
ZSHCONF="$clone" zshconf-update >/dev/null 2>&1
t_eq "update refuses uncommitted edits" "$?" "1"
t_eq "clone not advanced when dirty" "$(cat -- "$clone/a.zsh")" "a"

git -C "$clone" checkout -q -- b.zsh
ZSHCONF="$clone" zshconf-update >/dev/null 2>&1
t_eq "update succeeds when clean" "$?" "0"
t_eq "clone fast-forwarded" "$(cat -- "$clone/a.zsh")" "a2"
t_done
