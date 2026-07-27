# ── Docker aliases + fzf pickers
if (( $+commands[docker] )); then
  alias dps='docker ps'
  alias dpsa='docker ps -a'
  alias di='docker images'
  alias dprune='docker system prune -a'           # prompt preserved (no -f)
  alias dlogs='docker logs -f'
  alias dsh='docker exec -it'

  # Pick container(s) to stop via fzf (Tab = multi-select).
  dstop() {
    _need fzf || return

    local cids
    cids=$(docker ps --format '{{.ID}}\t{{.Names}}\t{{.Image}}' \
      | fzf --multi --header='Tab: select • Enter: stop selected' --with-nth=2,3) \
      || return 0
    [[ -n "$cids" ]] && awk '{print $1}' <<< "$cids" | xargs docker stop
  }

  # Pick container(s) to remove via fzf (Tab = multi-select).
  drm() {
    _need fzf || return

    local cids
    cids=$(docker ps -a --format '{{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Image}}' \
      | fzf --multi --header='Tab: select • Enter: remove selected' --with-nth=2,3,4) \
      || return 0
    [[ -n "$cids" ]] && awk '{print $1}' <<< "$cids" | xargs docker rm
  }
fi
