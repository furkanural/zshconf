#!/usr/bin/env zsh
# zshconf-edit: lists overlay files, creates drop-ins with a header, opens in
# $VISUAL/$EDITOR, rejects path-y names, honors the overlay location.
source "${0:A:h}/lib.zsh"

fpath=("$REPO/functions" $fpath)
autoload -Uz zshconf-edit
source "$REPO/modules/helpers.zsh"

export ZSHCONF_LOCAL="$TWORK/xdg/zsh"
mkdir -p "$ZSHCONF_LOCAL"

# Editor that records its argv instead of editing.
rec="$TWORK/editor-log"
export EDITOR="rec-editor"
rec-editor() { print -r -- "$1" >> "$rec"; }
export VISUAL=""

# List: empty overlay.
out=$(zshconf-edit 2>&1)
t_match "empty overlay says how to create" "$out" "*No overlay files*zshconf-edit <name>*"

# Create + edit a drop-in.
zshconf-edit work
t_eq    "drop-in created"            "$(cat -- "$rec")"                    "$ZSHCONF_LOCAL/local.d/work.zsh"
t_match "drop-in has guidance header" "$(cat -- "$ZSHCONF_LOCAL/local.d/work.zsh")" "*override anything*"

# Edit pre.zsh.
: > "$rec"
zshconf-edit pre
t_eq    "pre.zsh created"            "$(cat -- "$rec")"                 "$ZSHCONF_LOCAL/pre.zsh"
t_match "pre.zsh has guidance header" "$(cat -- "$ZSHCONF_LOCAL/pre.zsh")" "*BEFORE the core*"

# List: populated overlay shows repo-relative paths.
out=$(zshconf-edit 2>&1)
t_match "lists pre.zsh"      "$out" "*pre.zsh*"
t_match "lists local.d file" "$out" "*local.d/work.zsh*"

# Invalid names rejected, nothing created.
out=$(zshconf-edit ../escape 2>&1); rc=$?
t_eq    "path traversal rejected"   "$rc" "1"
t_match "traversal error explains"  "$out" "*Invalid name*"
t_eq    "no file created outside"   "$(ls "$TWORK/xdg" | grep -c escape)" "0"

out=$(zshconf-edit .hidden 2>&1); rc=$?
t_eq    "dotfile name rejected"     "$rc" "1"

# No editor configured.
unset EDITOR VISUAL
out=$(zshconf-edit more 2>&1); rc=$?
t_eq    "no editor fails"           "$rc" "1"
t_match "no editor says why"        "$out" "*No editor set*"

# VISUAL wins over EDITOR.
export VISUAL="rec-editor" EDITOR="false-editor"
false-editor() { print -r -- "WRONG" >> "$rec"; }
: > "$rec"
zshconf-edit pre
t_eq    "VISUAL preferred over EDITOR" "$(cat -- "$rec")" "$ZSHCONF_LOCAL/pre.zsh"

t_done
