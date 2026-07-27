#!/usr/bin/env zsh
# modelpreset management: add / list / load / edit / remove against a
# sandbox XDG_CONFIG_HOME. Interactive prompts are fed via stdin.
source "${0:A:h}/lib.zsh"

export XDG_CONFIG_HOME="$TWORK/xdg"
source "$REPO/modules/tools/modelpreset.zsh"
pfile="$XDG_CONFIG_HOME/cliproxy-presets/demo.env"

# add: creates the dir, writes only non-empty values, mode 600
modelpreset add demo >/dev/null <<'EOF'
https://proxy.example.com
tok-123
opus-x


EOF
t_eq "add: file created"     "$([[ -f $pfile ]]; echo $(( ! $? )))" "1"
t_eq "add: mode 600"         "$(ls -l $pfile | cut -c1-10)" "-rw-------"
t_eq "add: content"          "$(cat $pfile)" "export ANTHROPIC_BASE_URL='https://proxy.example.com'
export ANTHROPIC_AUTH_TOKEN='tok-123'
export ANTHROPIC_DEFAULT_OPUS_MODEL='opus-x'"

# add: refuses to overwrite
modelpreset add demo >/dev/null 2>"$TWORK/err" </dev/null
t_eq "add: refuses existing" "$?" "1"
t_match "add: suggests edit" "$(cat $TWORK/err)" "*already exists*"

# add: all-empty input creates nothing
modelpreset add empty >/dev/null 2>/dev/null <<'EOF'




EOF
t_eq "add: all-empty rejected" "$?" "1"

# list + load
t_match "list: shows preset" "$(modelpreset)" "*demo*"
out=$(modelpreset demo >/dev/null && print -r -- "$ANTHROPIC_BASE_URL/$ANTHROPIC_DEFAULT_OPUS_MODEL")
t_eq "load: exports values" "$out" "https://proxy.example.com/opus-x"

# edit: uses $EDITOR; errors on a missing preset
EDITOR="true" modelpreset edit demo
t_eq "edit: runs EDITOR"      "$?" "0"
EDITOR="true" modelpreset edit nope 2>/dev/null
t_eq "edit: missing preset errors" "$?" "1"

# remove: 'n' keeps, 'y' deletes
print n | modelpreset remove demo >/dev/null
t_eq "remove: declined keeps file" "$([[ -f $pfile ]]; echo $(( ! $? )))" "1"
print y | modelpreset remove demo >/dev/null
t_eq "remove: confirmed deletes"   "$([[ -f $pfile ]]; echo $?)" "1"
t_done
