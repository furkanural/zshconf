# ── Docker aliases + fzf pickers
if (( $+commands[docker] )); then
  alias dps='docker ps'
  alias dpsa='docker ps -a'
  alias di='docker images'
  alias dprune='docker system prune -a'           # prompt preserved (no -f)
  alias dlogs='docker logs -f'
  alias dsh='docker exec -it'

  # Tab completion: Docker Desktop / colima installs don't always ship a zsh
  # completer. Generate one into the user completions dir (on fpath, watched
  # by the compdump hygiene pass) when missing or older than the binary —
  # in the background, so it costs nothing at startup; it takes effect on
  # the next shell.
  () {
    local comp="${ZDOTDIR:-$HOME}/.zsh/completions/_docker"
    local bin="${commands[docker]:A}"
    [[ -s "$comp" && ! "$bin" -nt "$comp" ]] && return
    {
      command mkdir -p "${comp:h}"
      command docker completion zsh >| "$comp.tmp" 2>/dev/null \
        && [[ -s "$comp.tmp" ]] && command mv -f "$comp.tmp" "$comp"
      command rm -f "$comp.tmp"
    } &!
  }

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
