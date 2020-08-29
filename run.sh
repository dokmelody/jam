#!/usr/bin/env bash
set -euo pipefail

if which racket > /dev/null; then
  echo "Already installed" > /dev/null
else
  if [[ "$#" -eq 1 ]]; then
    case $1 in
      --on-repl-it)
        PKG1="racket-common_7.7+ppa1-1~bionic1_all.deb"
        PKG2="racket_7.7+ppa1-1~bionic1_amd64.deb"
        
        SITE1="https://downloads.asterisell.com"
        SITE2="https://launchpad.net/~plt/+archive/ubuntu/racket/+files"

        install-pkg $SITE1/$PKG1 || install-pkg $SITE2/$PKG1

        install-pkg $SITE1/$PKG2 || install-pkg $SITE2/$PKG2
        
        ;;
    esac
  fi
fi

OPTS=""
if [[ "$#" -eq 1 ]]; then
  case $1 in
    --on-repl-it)
    OPTS="--config /home/runner/jam/repl-it-conf --collects /home/runner/.apt/usr/share/racket/collects"
    
    ;;
  esac
fi

if which racket > /dev/null; then
  echo "Installed" > /dev/null
else
  echo "racket is not installed" 1>&2
  exit 1
fi

raco $OPTS pkg install --auto || true

racket $OPTS dokmelody/web-app.rkt
