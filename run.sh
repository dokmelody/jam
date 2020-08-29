#!/usr/bin/env bash
set -euo pipefail

if which racket > /dev/null; then
  echo "Already installed" > /dev/null
else
  case $1 in
    --on-repl-it)
      install-pkg https://launchpad.net/~plt/+archive/ubuntu/racket/+files/racket-common_7.7+ppa1-1~bionic1_all.deb \
        https://launchpad.net/~plt/+archive/ubuntu/racket/+files/racket_7.7+ppa1-1~bionic1_amd64.deb
      ;;
    *)
      echo "racket is not installed" 1>&2
      exit 1
      ;;
  esac
fi

raco pkg install --auto || true

racket dokmelody/web-app.rkt
