# just test        — full suite (what CI runs)
# just parse       — quick syntax gate only
# just test-bare   — CI's toughest cell locally: bare Linux, no optional tools

default: test

test:
    zsh tests/run.zsh

parse:
    zsh tests/00-parse.zsh

test-bare:
    docker run --rm -v "$PWD":/repo -w /repo ubuntu:24.04 bash -c \
        "apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -qq -y zsh git curl ca-certificates >/dev/null && zsh tests/run.zsh"
