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
  #  - The temp file is dot-prefixed and per-PID: compinit treats every
  #    `_*` file on fpath as a completer (a stray `_docker.tmp` would be
  #    registered), and shells started together must not clobber each
  #    other's half-written output.
  #  - A docker without `completion zsh` leaves a dot-prefixed marker naming
  #    the binary that failed, so we don't retry on every shell; a different
  #    or newer binary (an upgrade, a switch to Docker Desktop/colima) retries.
  #  - Skipped entirely when a packaged _docker already sits on fpath
  #    (Homebrew formula, docker-ce-cli): no point shadowing it.
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
