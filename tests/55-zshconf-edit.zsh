#!/usr/bin/env zsh
# zshconf-edit: list, create with header, editor choice, name validation.
source "${0:A:h}/lib.zsh"

fpath=("$REPO/functions" $fpath)
autoload -Uz zshconf-edit
source "$REPO/modules/helpers.zsh"

export ZSHCONF_LOCAL="$TWORK/xdg/zsh"
mkdir -p "$ZSHCONF_LOCAL"

rec="$TWORK/editor-log"
export EDITOR="rec-editor"
rec-editor() { print -r -- "$1" >> "$rec"; }
export VISUAL=""

out=$(zshconf-edit 2>&1)
t_match "empty overlay says how to create" "$out" "*No overlay files*zshconf-edit <name>*"

zshconf-edit work
t_eq    "drop-in created"            "$(cat -- "$rec")"                    "$ZSHCONF_LOCAL/local.d/work.zsh"
t_match "drop-in has guidance header" "$(cat -- "$ZSHCONF_LOCAL/local.d/work.zsh")" "*override anything*"

: > "$rec"
zshconf-edit pre
t_eq    "pre.zsh created"            "$(cat -- "$rec")"                 "$ZSHCONF_LOCAL/pre.zsh"
t_match "pre.zsh has guidance header" "$(cat -- "$ZSHCONF_LOCAL/pre.zsh")" "*BEFORE the core*"

: > "$rec"
zshconf-edit env
t_eq    "env.zsh created"            "$(cat -- "$rec")"                 "$ZSHCONF_LOCAL/env.zsh"
t_match "env.zsh has guidance header" "$(cat -- "$ZSHCONF_LOCAL/env.zsh")" "*login shell*"

out=$(zshconf-edit 2>&1)
t_match "lists pre.zsh"      "$out" "*pre.zsh*"
t_match "lists local.d file" "$out" "*local.d/work.zsh*"

out=$(zshconf-edit ../escape 2>&1); rc=$?
t_eq    "path traversal rejected"   "$rc" "1"
t_match "traversal error explains"  "$out" "*Invalid name*"
t_eq    "no file created outside"   "$(ls "$TWORK/xdg" | grep -c escape)" "0"

out=$(zshconf-edit .hidden 2>&1); rc=$?
t_eq    "dotfile name rejected"     "$rc" "1"

unset EDITOR VISUAL
out=$(zshconf-edit more 2>&1); rc=$?
t_eq    "no editor fails"           "$rc" "1"
t_match "no editor says why"        "$out" "*No editor set*"

export VISUAL="rec-editor" EDITOR="false-editor"
false-editor() { print -r -- "WRONG" >> "$rec"; }
: > "$rec"
zshconf-edit pre
t_eq    "VISUAL preferred over EDITOR" "$(cat -- "$rec")" "$ZSHCONF_LOCAL/pre.zsh"

t_done
