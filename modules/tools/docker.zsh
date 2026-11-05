if (( $+commands[docker] )); then
  alias dps='docker ps'
  alias dpsa='docker ps -a'
  alias di='docker images'
  alias dprune='docker system prune -a'
  alias dlogs='docker logs -f'
  alias dsh='docker exec -it'

  # Generate _docker into the user completions dir in the background when
  # missing or older than the binary, unless a packaged one is on fpath.
  # The temp file is dot-prefixed (compinit registers any _* on fpath) and
  # per-PID. A docker without `completion zsh` leaves a marker naming the
  # binary so the next shell doesn't retry until the binary changes.
  () {
    local comp="${ZDOTDIR:-$HOME}/.zsh/completions/_docker"
    local bin="${commands[docker]:A}"
    [[ -s "$comp" && ! "$bin" -nt "$comp" ]] && return
    local -a packaged=( ${^fpath:#${comp:h}}/_docker(N) )
    (( $#packaged )) && return
    local nope="${comp:h}/.${comp:t}.unsupported"
    [[ -e "$nope" && ! "$bin" -nt "$nope" && "$(<$nope)" == "$bin" ]] && return
    {
      local tmp="${comp:h}/.${comp:t}.$$"
      command mkdir -p "${comp:h}"
      if command docker completion zsh >| "$tmp" 2>/dev/null && [[ -s "$tmp" ]]; then
        command mv -f "$tmp" "$comp" && command rm -f "$nope"
      else
        print -r -- "$bin" >| "$nope"
      fi
      command rm -f "$tmp"
    } &!
  }

  # Pick containers with fzf (Tab = multi-select).
  dstop() {
    _need fzf || return
    local cids
    cids=$(docker ps --format '{{.ID}}\t{{.Names}}\t{{.Image}}' \
      | fzf --multi --header='Tab: select • Enter: stop selected' --with-nth=2,3) \
      || return 0
    [[ -n "$cids" ]] && awk '{print $1}' <<< "$cids" | xargs docker stop
  }

  drm() {
    _need fzf || return
    local cids
    cids=$(docker ps -a --format '{{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Image}}' \
      | fzf --multi --header='Tab: select • Enter: remove selected' --with-nth=2,3,4) \
      || return 0
    [[ -n "$cids" ]] && awk '{print $1}' <<< "$cids" | xargs docker rm
  }
fi
