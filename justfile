default: test

install-hooks:
    ln -sf ../../hooks/pre-commit .git/hooks/pre-commit
    @echo "pre-commit hook installed"

test:
    zsh tests/run.zsh

parse:
    zsh tests/00-parse.zsh

test-bare:
    docker run --rm -v "$PWD":/repo -w /repo ubuntu:24.04 bash -c \
        "apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -qq -y zsh git curl ca-certificates >/dev/null && zsh tests/run.zsh"
