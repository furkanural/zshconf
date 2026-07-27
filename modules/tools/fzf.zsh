# ── fzf
if (( $+commands[fzf] )); then
  export FZF_DEFAULT_OPTS='
    --height 40%
    --layout=reverse
    --border
    --inline-info
    --color=fg:-1,bg:-1,hl:#5fff87,fg+:#ffff87,bg+:#3a3a3a,hl+:#ffaf5f
    --color=info:#af87ff,prompt:#5fff87,pointer:#ff87d7,marker:#ff87d7,spinner:#ff87d7
    --bind ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down
  '

  # fd as source — faster, respects .gitignore.
  if (( $+commands[fd] )); then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi

  _zinit_evalcache fzf-init 'fzf --zsh'
fi
